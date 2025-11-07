# 使用 GitHub Actions 构建 Android APK

## 前提条件
- GitHub 账户
- 已 Fork 的 RustDesk 项目

## 构建步骤

### 1. 添加 GitHub Actions 工作流文件

工作流文件已创建在：`.github/workflows/build-android-apk.yml`

### 2. 推送更改到您的 Fork

```bash
# 初始化仓库（如果还未初始化）
git init
git remote add origin https://github.com/你的用户名/rustdesk.git

# 添加所有文件
git add .
git commit -m "feat: 添加自定义中继服务器配置和GitHub Actions构建工作流"

# 推送到GitHub
git branch -M master
git push -u origin master
```

### 3. 在 GitHub 上触发构建

1. **访问您的 Fork**：
   ```
   https://github.com/你的用户名/rustdesk
   ```

2. **进入 Actions 页面**：
   - 点击 "Actions" 标签
   - 您会看到 "Build Android APK" 工作流

3. **手动触发构建**：
   - 点击 "Build Android APK" 工作流
   - 点击 "Run workflow" 按钮
   - 选择分支（master）并点击绿色的 "Run workflow" 按钮

4. **等待构建完成**：
   - 构建通常需要 15-30 分钟
   - 您可以在 Actions 页面查看实时进度

### 4. 下载构建产物

构建完成后：

1. **下载 APK**：
   - 在 Actions 页面点击成功的构建
   - 滚动到 "Artifacts" 部分
   - 点击 "rustdesk-android-apk" 下载

2. **APK 文件说明**：
   - `app-arm64-v8a-release.apk` - 64位 ARM（大多数现代设备）
   - `app-armeabi-v7a-release.apk` - 32位 ARM（旧设备）
   - `app-x86_64-release.apk` - x64 模拟器

3. **下载 AAB（可选）**：
   - AAB 文件用于 Google Play Store 发布
   - 点击 "rustdesk-android-aab" 下载

## 验证服务器配置

构建的 APK 已经预配置了您的服务器地址：
- 中继服务器：`8.153.105.121:21116`
- 中继端口：`8.153.105.121:21117`
- API服务器：`http://8.153.105.121:21114`
- API密钥：`lr8I43Tc0Qnsa1RIyJVkVxKwll1I2xxpPOco9HWcEa4=`

安装 APK 后，您无需再次配置这些服务器地址。

## 故障排除

### 构建失败怎么办？

1. **检查 Actions 日志**：
   - 点击失败的构建
   - 查看具体的错误信息

2. **常见错误**：
   - 依赖下载超时：通常会自动重试
   - 内存不足：GitHub Actions 有时会出现，可以重新运行

3. **重新运行**：
   - 在 Actions 页面点击 "Re-run jobs"

### 需要更改服务器配置？

编辑 `libs/hbb_common/src/config.rs` 文件中的第65-73行：
```rust
m.insert("custom-rendezvous-server".into(), "你的新服务器地址:端口".into());
m.insert("relay-server".into(), "你的新服务器地址:端口".into());
m.insert("api-server".into(), "https://你的新服务器地址".into());
m.insert("key".into(), "你的新API密钥".into());
```

然后重新提交和推送。

## 自动化构建

每次推送到 master 分支时，GitHub Actions 会自动构建 APK。

## 注意事项

- 每次构建大约消耗 40-50 GitHub Actions 分钟
- 构建产物保留 30 天
- 可以免费使用公开仓库的 GitHub Actions
- 私有仓库每月有 2000 分钟的免费额度
