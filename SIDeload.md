# 侧载安装指南

无需 App Store，三种方式安装 IPA 到 iPhone。

## 方式一：AltStore（推荐）

### 安装 AltStore
1. 电脑下载 [AltServer](https://altstore.io/)（Windows/Mac）
2. iPhone 安装 AltStore
3. 同一 WiFi 下自动同步

### 安装 WordMemory
1. iPhone 打开 AltStore
2. 底部 "My Apps"
3. 左上角 "+"
4. 选择 `WordMemory.ipa`
5. 等待安装完成

### 自动续签
- AltStore 每 7 天自动续签
- 保持电脑开机 + 同一 WiFi

---

## 方式二：Sideloadly（一次性）

### 安装
1. 电脑下载 [Sideloadly](https://sideloadly.io/)
2. 连接 iPhone 到电脑
3. 拖入 `WordMemory.ipa`
4. 输入 Apple ID（仅用于签名）
5. 点击 Start

### 特点
- 无需保持电脑运行
- 每 7 天需重新安装
- 免费 Apple ID 可签 3 个 App

---

## 方式三：TrollStore（永久）

### 要求
- iOS 15.0 - 17.0（部分版本）
- 需先安装 TrollStore

### 安装
1. 安装 TrollStore（需特定漏洞）
2. 分享 `WordMemory.ipa` 到 TrollStore
3. 点击 Install

### 特点
- **永久安装，无需续签**
- 系统级 App，无 7 天限制
- 需特定 iOS 版本

---

## 获取 IPA

### 方式 A：GitHub Actions 自动构建
1. Fork 本仓库
2. 进入 Actions → Build IPA
3. 点击 Run workflow
4. 下载 Artifacts 中的 IPA

### 方式 B：本地构建
```bash
cd WordMemory-iOS
./build_ipa.sh
```

### 方式 C：手动打包
```bash
# 1. 生成项目
xcodegen generate

# 2. 构建（无签名）
xcodebuild -project WordMemory.xcodeproj \
  -scheme WordMemory -configuration Release \
  -sdk iphoneos -archivePath build/WordMemory.xcarchive \
  archive CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# 3. 打包 IPA
mkdir -p build/Payload
cp -r build/WordMemory.xcarchive/Products/Applications/*.app build/Payload/
cd build && zip -r WordMemory.ipa Payload
```

---

## 常见问题

### "无法验证 App"
- 设置 → 通用 → VPN与设备管理 → 信任开发者

### "7天后无法打开"
- 使用 AltStore 自动续签
- 或重新用 Sideloadly 安装

### TrollStore 安装失败
- 检查 iOS 版本是否支持
- 确保使用 TrollStore 2.0+

---

## 推荐方案

| 场景 | 推荐方式 |
|------|----------|
| 长期稳定使用 | AltStore |
| 快速尝鲜 | Sideloadly |
| iOS 15-17 | TrollStore（永久）|
| 无电脑 | AltStore + 云电脑 |
