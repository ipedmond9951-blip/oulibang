# 🚀 自动化部署流程

## 📦 文件说明

```
.github/
├── workflows/
│   └── deploy.yml          # GitHub Actions 部署工作流
└── optimize/
    ├── optimize.sh         # 一键优化脚本（视频/图片/CSS）
    ├── package.json        # Tailwind CLI 依赖
    ├── tailwind.config.js  # Tailwind 配置（含系统字体栈）
    └── README.md           # 本文件
```

## 🔄 自动流程

每次 `git push origin main` 会触发：

```
1. GitHub 拉取最新代码
2. 安装 ffmpeg + cwebp + Tailwind CLI
3. 运行 optimize.sh：
   ├── 视频转码（移动版 + 桌面版 + poster）
   ├── 图片转 WebP
   └── 重新编译 Tailwind CSS
4. amondnet/vercel-action 部署到 Vercel
5. 输出部署摘要（GitHub Actions Summary）
```

## 🔑 必需的 GitHub Secrets

在 GitHub 仓库 **Settings → Secrets and variables → Actions** 添加：

| Secret 名 | 值 | 获取方式 |
|-----------|---|---------|
| `VERCEL_TOKEN` | Vercel API token | https://vercel.com/account/tokens |
| `VERCEL_ORG_ID` | `team_zpNihQv4m6nG8EPZqu079v8k` | Vercel 项目 Settings → General |
| `VERCEL_PROJECT_ID` | `prj_BoHXSNU3lKse8vgVu9DdzvIHErgz` | Vercel 项目 Settings → General |

## 💻 本地手动优化（不部署）

如果你想本地重新生成资源（不部署）：

```bash
cd ~/Projects/website-cloner/output/aolibang
bash .github/optimize/optimize.sh
```

跑完会得到：
- `videos/company_intro_mobile.mp4` (2.6MB)
- `videos/company_intro_desktop.mp4` (5MB)
- `videos/poster.jpg` (55KB)
- `images/*.webp` (首页关键图)
- `css/tailwind.min.css` (26KB)

## ⚠️ 注意事项

### Vercel 100 次/天限额
GitHub Actions + Vercel CLI **仍会消耗** 100 次/天限额，但有 2 个优势：
1. **构建失败不计**（Vercel 端无部署记录）
2. **构建时跑优化不消耗 Vercel 资源**（ffmpeg/cwebp 在 GitHub 跑）

### 不再需要手动跑
以后改完代码只需要：
```bash
git add . && git commit -m "..." && git push
```
GitHub Actions 自动完成优化 + 部署。

### 手动触发
如果不想等 push 自动触发，GitHub 仓库 → Actions → Deploy to Vercel → **Run workflow**。

## 🔍 调试

看部署日志：
1. GitHub 仓库 → **Actions** 标签
2. 选最近的 workflow run
3. 展开每个步骤看日志

如果失败，常见原因：
- **Secrets 没配**：会报 `Error: VERCEL_TOKEN not set`
- **Vercel 限额**：会报 `Resource is limited`
- **ffmpeg 失败**：检查 videos/company_intro.mp4 是否存在
