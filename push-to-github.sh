#!/bin/bash

# GitHub Actions 快速推送脚本
# 用法: ./push-to-github.sh <你的GitHub用户名>

set -e

if [ -z "$1" ]; then
    echo "错误：请提供你的GitHub用户名"
    echo "用法: $0 <你的GitHub用户名>"
    exit 1
fi

GITHUB_USER=$1
REPO_URL="https://github.com/$GITHUB_USER/rustdesk.git"

echo "========================================"
echo "GitHub Actions 快速推送脚本"
echo "========================================"
echo "GitHub 用户名: $GITHUB_USER"
echo "仓库地址: $REPO_URL"
echo "========================================"
echo

# 检查是否已初始化git
if [ ! -d ".git" ]; then
    echo "步骤 1: 初始化 Git 仓库..."
    git init
    git branch -M master
fi

# 添加远程仓库
echo "步骤 2: 添加远程仓库..."
if git remote | grep -q origin; then
    echo "远程仓库已存在，更新地址..."
    git remote set-url origin $REPO_URL
else
    echo "添加远程仓库..."
    git remote add origin $REPO_URL
fi

# 添加所有更改
echo "步骤 3: 暂存所有文件..."
git add .

# 提交更改
echo "步骤 4: 提交更改..."
COMMIT_MSG="feat: 添加自定义中继服务器配置和GitHub Actions构建工作流

- 在 libs/hbb_common/src/config.rs 中预配置服务器设置
- 添加 .github/workflows/build-android-apk.yml 构建工作流
- 用户无需在安装后手动配置中继服务器
- 支持自动构建和发布APK

服务器配置:
- 中继服务器: 8.153.105.121:21116
- 中继端口: 8.153.105.121:21117
- API服务器: http://8.153.105.121:21114
- API密钥: lr8I43Tc0Qnsa1RIyJVkVxKwll1I2xxpPOco9HWcEa4="

if git diff --cached --quiet; then
    echo "没有需要提交的更改"
else
    git commit -m "$COMMIT_MSG"
fi

# 推送到GitHub
echo "步骤 5: 推送到 GitHub..."
echo "请输入你的 GitHub 密码或访问令牌："
git push -u origin master --set-upstream

echo
echo "========================================"
echo "推送完成！"
echo "========================================"
echo
echo "下一步操作："
echo "1. 访问 https://github.com/$GITHUB_USER/rustdesk"
echo "2. 点击 'Actions' 标签"
echo "3. 选择 'Build Android APK' 工作流"
echo "4. 点击 'Run workflow' 按钮"
echo "5. 等待构建完成（通常需要 15-30 分钟）"
echo "6. 在 'Artifacts' 部分下载 APK 文件"
echo
echo "详细说明请查看 GITHUB_ACTIONS_BUILD.md 文件"
echo "========================================"
