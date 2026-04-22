#!/bin/bash
# build_ipa.sh - 构建 IPA 文件用于侧载安装

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
SCHEME="WordMemory"
EXPORT_OPTIONS="$PROJECT_DIR/exportOptions.plist"

echo "🚀 开始构建 WordMemory IPA..."

# 1. 生成 Xcode 项目
echo "📦 生成 Xcode 项目..."
cd "$PROJECT_DIR"
xcodegen generate

# 2. 清理旧构建
echo "🧹 清理旧构建..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 3. 归档
echo "📋 归档..."
xcodebuild \
    -project "$PROJECT_DIR/WordMemory.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -sdk iphoneos \
    -archivePath "$BUILD_DIR/WordMemory.xcarchive" \
    archive \
    CODE_SIGN_IDENTITY="iPhone Developer" \
    DEVELOPMENT_TEAM="YOUR_TEAM_ID"

# 4. 导出 IPA
echo "📱 导出 IPA..."

# 创建 export options plist
cat > "$EXPORT_OPTIONS" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

xcodebuild \
    -exportArchive \
    -archivePath "$BUILD_DIR/WordMemory.xcarchive" \
    -exportPath "$BUILD_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS"

echo "✅ IPA 构建完成！"
echo "📁 输出路径: $BUILD_DIR/WordMemory.ipa"

# 5. 显示文件信息
if [ -f "$BUILD_DIR/WordMemory.ipa" ]; then
    ls -lh "$BUILD_DIR/WordMemory.ipa"
    echo ""
    echo "🎯 安装方法:"
    echo "   1. AltStore: 连接手机 → My Apps → + → 选择 IPA"
    echo "   2. Sideloadly: 连接手机 → 拖入 IPA → 输入 Apple ID"
    echo "   3. TrollStore: 安装 TrollStore → 打开 IPA → Install"
fi
