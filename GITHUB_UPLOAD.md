# GitHub 上传 指南

## 方式一：网页上传（最简单）

### 1. 创建仓库
- 打开 https://github.com/new
- Repository name: `WordMemory-iOS`
- 选择 **Public**（GitHub Actions 免费）
- **不要**勾选任何初始化选项
- 点击 **Create repository**

### 2. 上传文件
- 在新仓库页面点击 "uploading an existing file"
- 将 `WordMemory-iOS` 文件夹内容拖入
- 注意：词库文件较大（53MB），可能需要分批上传
  - 先上传除 JSON 词库外的所有文件
  - 再单独上传两个词库文件

### 3. 启用 GitHub Actions
- 进入仓库 Settings → Actions → General
- 选择 "Allow all actions and reusable workflows"
- 保存

### 4. 触发构建
- 进入 Actions 页面
- 选择 "Build IPA"
- 点击 "Run workflow"
- 等待构建完成（约 10-15 分钟）
- 下载 Artifacts 中的 IPA

---

## 方式二：Git 命令行（需安装 Git）

### 1. 初始化 Git 仓库
```bash
cd C:\Users\TheSky\Desktop\Code\WordMemory-iOS
git init
git add .
git commit -m "Initial commit: WordMemory iOS app with SM2 + AI"
```

### 2. 关联远程仓库
```bash
git remote add origin https://github.com/你的用户名/WordMemory-iOS.git
git branch -M main
git push -u origin main
```

### 3. 等待自动构建
- GitHub Actions 会自动触发
- 进入 Actions 页面查看进度

---

## 注意事项

### 词库文件大小
- `wordbook_full.json`: 15.3 MB
- `wordbook_full_from_e2c.json`: 38.54 MB
- **总计**: 53.84 MB

GitHub 单文件限制 100MB，所以可以正常上传。

### 如果上传失败
1. 使用 Git LFS 处理大文件：
```bash
git lfs install
git lfs track "*.json"
git add .gitattributes
git add .
git commit -m "Add wordbooks with LFS"
```

2. 或者将词库放到 GitHub Release：
   - 先上传代码（不含词库）
   - 创建 Release
   - 上传词库作为 Release Assets

---

## GitHub Actions 构建说明

项目已配置 `.github/workflows/build.yml`：
- 自动触发：push 到 main 分支
- 手动触发：Actions → Build IPA → Run workflow
- 输出：未签名的 IPA 文件
- 用途：通过 AltStore/Sideloadly/TrollStore 安装

---

## 快速开始

1. 在 GitHub 创建仓库 `WordMemory-iOS`
2. 上传项目文件
3. 进入 Actions → Build IPA → Run workflow
4. 等待构建完成，下载 IPA
5. 使用侧载工具安装到 iPhone
