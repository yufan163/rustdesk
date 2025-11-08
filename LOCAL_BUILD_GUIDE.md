# RustDesk Android APK 本地构建指南

## 概述

本指南说明如何在本地环境中完整构建预配置了自定义服务器的 RustDesk Android APK。

## 前置要求

### 系统依赖
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y \
  build-essential cmake ninja-build pkg-config \
  git curl wget unzip \
  openjdk-17-jdk \
  android-tools-adb android-tools-fastboot

# 安装 Android SDK 和 NDK
# 下载并安装 Android Studio 或独立 SDK
export ANDROID_SDK_ROOT=$HOME/android-sdk
export ANDROID_NDK_HOME=$ANDROID_SDK_ROOT/ndk/27.0.12077973
```

### Flutter
```bash
# 安装 Flutter 3.24.5
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# 验证安装
flutter doctor
```

### Rust
```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# 安装 Flutter Rust Bridge Codegen
cargo install flutter_rust_bridge_codegen
```

## 构建步骤

### 1. 克隆仓库
```bash
git clone https://github.com/yufan163/rustdesk.git
cd rustdesk
```

### 2. 安装子模块
```bash
git submodule update --init --depth 1
```

### 3. 设置环境变量
```bash
export ANDROID_SDK_ROOT=$HOME/android-sdk
export ANDROID_NDK_HOME=$ANDROID_SDK_ROOT/ndk/27.0.12077973
export VCPKG_ROOT=$HOME/vcpkg
```

### 4. 初始化 vcpkg（可选）
```bash
# 如果需要构建原生库
git clone https://github.com/microsoft/vcpkg.git $VCPKG_ROOT
cd $VCPKG_ROOT
./bootstrap-vcpkg.sh
cd -
```

### 5. 生成 Flutter Rust Bridge
```bash
cd flutter
flutter_rust_bridge_codegen \
  --rust-input ../src/flutter_ffi.rs \
  --dart-output lib/generated_bridge.dart \
  --dart-decl-output lib/bridge_definitions.dart \
  --c-output ios/Runner/bridge_generated.h \
  --rust-crate-dir ../ \
  --rust-output ../src/bridge_generated/ \
  --class-name RustdeskImpl
cd -
```

### 6. 构建 Android APK
```bash
cd flutter

# 构建特定架构
flutter build apk --release --target-platform android-arm64

# 或构建所有架构（推荐）
flutter build apk --release --split-per-abi

# 构建 AAB（用于发布）
flutter build appbundle --release
```

APK 文件将生成在：`flutter/build/app/outputs/flutter-apk/app-release.apk`

## 自定义服务器配置

当前的配置在 `src/common.rs:1754-1758`：

```rust
pub fn load_custom_client() {
    // 预配置默认中继服务器设置
    let mut hard_settings = config::HARD_SETTINGS.write().unwrap();
    hard_settings.insert("custom-rendezvous-server".into(), "8.153.105.121:21116".into());
    hard_settings.insert("relay-server".into(), "8.153.105.121:21117".into());
    hard_settings.insert("api-server".into(), "http://8.153.105.121:21114".into());
    hard_settings.insert("key".into(), "lr8I43Tc0Qnsa1RIyJVkVxKwll1I2xxpPOco9HWcEa4=".into());
    drop(hard_settings);
    // ...
}
```

**修改服务器配置**：
编辑 `src/common.rs` 文件，替换上述 IP 地址和密钥。

## 故障排除

### 错误：flutter_rust_bridge_codegen 编译失败
```bash
# 尝试安装特定版本
cargo install flutter_rust_bridge_codegen --version 2.0.0

# 或使用最新版本
cargo install --git https://github.com/flutter-rust/flutter_rust_bridge codegen
```

### 错误：NDK 未找到
```bash
# 检查 NDK 安装
ls $ANDROID_NDK_HOME

# 如果没有，使用 sdkmanager 安装
$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager "ndk;27.0.12077973"
```

### 错误：依赖下载超时
```bash
# 使用国内镜像
git config --global url."https://ghproxy.com/https://github.com/".insteadOf "https://github.com/"
export CARGO_REGISTRY_DEFAULT=https://mirrors.ustc.edu.cn/crates.io-index
```

## 使用自动化脚本

项目中提供了几个脚本：

```bash
# 构建 Android APK（快速）
./build.sh --flutter

# 构建 Android（完整）
cd flutter && ./build_android.sh

# 构建所有平台
python3 build.py --flutter --release
```

## 签名 APK（可选）

### 生成签名密钥
```bash
keytool -genkey -v -keystore ~/rustdesk.keystore -alias rustdesk -keyalg RSA -keysize 2048 -validity 10000
```

### 签名 APK
```bash
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore ~/rustdesk.keystore app-release.apk rustdesk
```

### 对齐 APK
```bash
zipalign -v 4 app-release.apk rustdesk-aligned.apk
```

## 验证安装

```bash
# 安装到设备
adb install rustdesk-aligned.apk

# 验证配置
adb logcat | grep RustDesk
```

## 性能优化

### 启用混淆
```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

### 启用硬件编解码
```bash
flutter build apk --release --target-platform android-arm64,android-arm --enable-software-rendering=false
```

## 常见问题

### Q: Bridge 代码生成失败？
A: 确保安装了正确版本的 `flutter_rust_bridge_codegen`，并检查 Rust 输入文件路径。

### Q: 构建过程中内存不足？
A: 增加系统内存或使用 `--release` 模式（已默认启用）。

### Q: 无法连接到服务器？
A: 检查防火墙设置，确保 21116、21117、21114 端口开放。

## 完整构建示例

```bash
#!/bin/bash
set -e

echo "=== 安装依赖 ==="
sudo apt update
sudo apt install -y build-essential cmake ninja-build openjdk-17-jdk

echo "=== 设置环境变量 ==="
export ANDROID_SDK_ROOT=$HOME/android-sdk
export ANDROID_NDK_HOME=$ANDROID_SDK_ROOT/ndk/27.0.12077973
export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"

echo "=== 克隆仓库 ==="
git clone https://github.com/yufan163/rustdesk.git
cd rustdesk
git submodule update --init --depth 1

echo "=== 安装 Flutter ==="
wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

echo "=== 安装 Rust ==="
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

echo "=== 安装 Flutter Rust Bridge ==="
cargo install flutter_rust_bridge_codegen

echo "=== 生成 Bridge 代码 ==="
cd flutter
flutter_rust_bridge_codegen \
  --rust-input ../src/flutter_ffi.rs \
  --dart-output lib/generated_bridge.dart \
  --dart-decl-output lib/bridge_definitions.dart \
  --rust-crate-dir ../ \
  --rust-output ../src/bridge_generated/ \
  --class-name RustdeskImpl
cd -

echo "=== 构建 APK ==="
cd flutter
flutter build apk --release --split-per-abi

echo "=== 完成 ==="
echo "APK 文件位置: $(pwd)/build/app/outputs/flutter-apk/"
```

## 支持

如果遇到问题，请：
1. 查看 [Flutter 文档](https://docs.flutter.dev)
2. 查看 [RustDesk 文档](https://rustdesk.com/docs)
3. 在 GitHub 提交 Issue

## 许可证

本项目基于 AGPLv3 许可证。详见 LICENSE 文件。
