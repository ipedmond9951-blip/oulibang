#!/usr/bin/env bash
# ============================================================================
# oulibang.com 资源优化脚本
# 用途：每次部署前自动跑（GitHub Actions / 本地手动均可）
# 功能：
#   1. 视频转码（移动版 640x360/500kbps + 桌面版 1280x720/1000kbps + poster）
#   2. 图片转 WebP（首页关键图）
#   3. Tailwind CSS 重新编译（含系统字体栈）
#
# 跑法：bash .github/optimize/optimize.sh
# ============================================================================
set -e

# 切到项目根目录
cd "$(dirname "$0")/../.."
ROOT=$(pwd)
echo "📁 项目根目录: $ROOT"

# ----------------------------------------------------------------------------
# 1. 视频转码
# ----------------------------------------------------------------------------
echo ""
echo "🎬 步骤 1/3: 视频转码"
mkdir -p videos
if [ -f "videos/company_intro.mp4" ]; then
  # 移动版（640x360, 500kbps → 约 2.2MB）
  if [ ! -f "videos/company_intro_mobile.mp4" ] || [ "videos/company_intro.mp4" -nt "videos/company_intro_mobile.mp4" ]; then
    echo "  ↳ 生成移动版视频..."
    ffmpeg -y -i videos/company_intro.mp4 -vf "scale=640:360" \
      -c:v libx264 -b:v 500k -c:a aac -b:a 96k \
      -movflags +faststart videos/company_intro_mobile.mp4 2>/dev/null
  else
    echo "  ↳ 移动版视频已最新，跳过"
  fi

  # 桌面版（1280x720, 1000kbps）
  if [ ! -f "videos/company_intro_desktop.mp4" ] || [ "videos/company_intro.mp4" -nt "videos/company_intro_desktop.mp4" ]; then
    echo "  ↳ 生成桌面版视频..."
    ffmpeg -y -i videos/company_intro.mp4 -vf "scale=1280:720" \
      -c:v libx264 -b:v 1000k -c:a aac -b:a 128k \
      -movflags +faststart videos/company_intro_desktop.mp4 2>/dev/null
  else
    echo "  ↳ 桌面版视频已最新，跳过"
  fi

  # Poster（首帧 JPG, 55KB）
  if [ ! -f "videos/poster.jpg" ] || [ "videos/company_intro.mp4" -nt "videos/poster.jpg" ]; then
    echo "  ↳ 生成视频首帧 poster..."
    ffmpeg -y -i videos/company_intro.mp4 -ss 00:00:01 -vframes 1 \
      -vf "scale=640:360" -q:v 3 videos/poster.jpg 2>/dev/null
  else
    echo "  ↳ poster 已最新，跳过"
  fi
  echo "  ✅ 视频处理完成"
else
  echo "  ⚠️  未找到 videos/company_intro.mp4，跳过视频处理"
fi

# ----------------------------------------------------------------------------
# 2. 图片转 WebP
# ----------------------------------------------------------------------------
echo ""
echo "🖼️  步骤 2/3: 图片转 WebP"
mkdir -p images
count=0
for src in \
  "images/new_factory.jpg" \
  "images/news-factory-production.jpg" \
  "images/news-lab-research.jpg" \
  "images/news-exhibition.jpg" \
  "images/logo.png"
do
  if [ -f "$src" ]; then
    base="${src%.*}"
    dst="${base}.webp"
    if [ ! -f "$dst" ] || [ "$src" -nt "$dst" ]; then
      echo "  ↳ $src → $dst"
      if [[ "$src" == *.png ]]; then
        cwebp -q 90 "$src" -o "$dst" 2>/dev/null
      else
        cwebp -q 85 "$src" -o "$dst" 2>/dev/null
      fi
      count=$((count + 1))
    fi
  fi
done
echo "  ✅ WebP 转换完成（$count 张）"

# ----------------------------------------------------------------------------
# 3. Tailwind CSS 编译
# ----------------------------------------------------------------------------
echo ""
echo "🎨 步骤 3/3: 编译 Tailwind CSS"
mkdir -p css
if command -v npx &> /dev/null; then
  cd .github/optimize
  npx tailwindcss@3.4.1 -c tailwind.config.js -o ../../css/tailwind.min.css --minify 2>/dev/null
  cd ../..
  echo "  ✅ Tailwind CSS 编译完成（css/tailwind.min.css）"
else
  echo "  ⚠️  未找到 npx，跳过 Tailwind 编译"
fi

# ----------------------------------------------------------------------------
# 完成
# ----------------------------------------------------------------------------
echo ""
echo "🎉 优化完成！"
echo ""
echo "📊 视频文件："
ls -lh videos/*.mp4 videos/*.jpg 2>/dev/null | awk '{print "  - " $NF ": " $5}'
echo ""
echo "🖼️  WebP 图片："
ls -lh images/*.webp 2>/dev/null | awk '{print "  - " $NF ": " $5}'
echo ""
echo "🎨 CSS 文件："
ls -lh css/*.css 2>/dev/null | awk '{print "  - " $NF ": " $5}'
