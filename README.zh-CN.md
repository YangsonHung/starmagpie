<p align="center">
  <img src="docs/assets/app-icon.png" width="128" alt="StarMagpie app icon">
</p>

<h1 align="center">StarMagpie</h1>

<p align="center">
  一个原生 macOS 应用，用来把 GitHub Stars 整理成可搜索、可分类、可维护的个人仓库库。
</p>

<p align="center">
  <a href="README.md">English</a>
  ·
  <a href="README.zh-CN.md"><strong>中文</strong></a>
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: GPL v3" src="https://img.shields.io/badge/License-GPLv3-blue.svg"></a>
  <a href="https://github.com/yangsonhung/starmagpie/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/yangsonhung/starmagpie/actions/workflows/ci.yml/badge.svg"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS-lightgrey.svg">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-14%2B-black.svg">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5-orange.svg">
  <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-blue.svg">
  <img alt="SwiftData" src="https://img.shields.io/badge/storage-SwiftData-purple.svg">
  <img alt="XcodeGen" src="https://img.shields.io/badge/project-XcodeGen-147EFB.svg">
</p>

## 概览

StarMagpie 会把你的 GitHub starred repositories 同步到本机，并让 Star 之后的整理过程更有效。它会在本地保存仓库元数据，支持按名称、描述、语言、Topics 和备注搜索，并为仓库提供分类能力，方便你之后重新找到和使用这些项目。

这个应用刻意保持轻量和原生。它使用 SwiftUI、SwiftData、URLSession 和 macOS Keychain，不接入后端服务，不提供账号同步服务器，也不会把 Token 存到 Keychain 之外。

## 功能亮点

- 使用 SwiftUI 构建的原生 macOS 体验。
- 使用 GitHub Personal Access Token 登录，并安全保存到 macOS Keychain。
- 使用 `application/vnd.github.star+json` 响应格式分页同步 GitHub Stars，并保留 `starred_at`。
- 使用 SwiftData 进行本地持久化。
- 支持按仓库名、完整名称、描述、Topics、语言和备注搜索。
- 内置关键词分类，并支持手动分类覆盖。
- 支持仓库备注、复制链接、打开 GitHub 和取消 Star。
- 支持 JSON 导入导出，保留本地仓库数据、分类、备注和最后查看时间。
- 支持英文和简体中文本地化，并提供 App 内语言切换。

## 目录

- [环境要求](#环境要求)
- [安装](#安装)
- [使用](#使用)
- [GitHub Token 权限](#github-token-权限)
- [隐私](#隐私)
- [开发](#开发)
- [发布构建](#发布构建)
- [项目结构](#项目结构)
- [仓库 Topics](#仓库-topics)
- [贡献](#贡献)
- [许可证](#许可证)

## 环境要求

- macOS 14.0 或更高版本
- Xcode 26 或更高版本
- XcodeGen

使用 Homebrew 安装 XcodeGen：

```bash
brew install xcodegen
```

## 安装

### 下载发布包

发布后可在 GitHub Releases 页面下载 `StarMagpie-unsigned.zip`。

项目当前没有 Apple Developer 证书，因此发布包默认不使用 Developer ID 签名，也不做 Apple 公证。macOS Gatekeeper 会提示应用来自未识别开发者。

### 从源码构建

```bash
git clone https://github.com/yangsonhung/starmagpie.git
cd starmagpie
xcodegen generate
open StarMagpie.xcodeproj
```

在 Xcode 中选择 `StarMagpie` scheme 后运行。

## 使用

1. 创建一个可以访问 starred repositories 的 GitHub Personal Access Token。
2. 启动 StarMagpie，并使用 Token 登录。
3. 点击 Sync 同步你的 GitHub Stars。
4. 使用搜索、语言筛选、排序、分类和备注整理仓库。
5. 使用 Data 菜单导入或导出 StarMagpie JSON 归档。

导入采用合并策略：GitHub repo `id` 相同的仓库会被更新，归档中没有出现的本地仓库会保留。

## GitHub Token 权限

StarMagpie 只把 Token 存入 macOS Keychain，不会写入 SwiftData、日志或项目文件。

最低权限建议：

- 读取 Stars：允许读取当前用户的 starred repositories。
- 取消 Star：需要对 starred repositories 的写入权限。

Fine-grained token 使用时，请只授予当前账户需要的最小权限。

## 隐私

StarMagpie 是本地优先的应用：

- 没有后端服务。
- 没有远程分析。
- 没有跨设备同步。
- GitHub Token 只保存在 macOS Keychain。
- 仓库数据、备注、分类和导入导出归档都由你自己控制。

## 开发

生成 Xcode 工程：

```bash
xcodegen generate
```

运行测试：

```bash
xcodebuild test -scheme StarMagpie -destination 'platform=macOS'
```

构建 App：

```bash
xcodebuild build -scheme StarMagpie -destination 'platform=macOS'
```

重新生成 App 图标：

```bash
./scripts/generate-app-icon.swift
```

构建未签名发布包：

```bash
./scripts/package-unsigned.sh
```

## 发布构建

本地未签名发布包会输出到：

- `dist/StarMagpie-unsigned.zip`
- `dist/StarMagpie-unsigned.zip.sha256`

创建 `v*` 标签并推送到 GitHub 后，`Release Unsigned Build` 工作流会自动构建未签名包并附加到 GitHub Release。

构建产物没有 Apple TeamIdentifier。Xcode 仍可能为可执行文件写入 ad-hoc/linker 签名，这不等同于 Developer ID 签名。

## 多语言

源码以英文文案作为基准语言。用户可见文案通过以下文件本地化：

- `StarMagpie/en.lproj/Localizable.strings`
- `StarMagpie/zh-Hans.lproj/Localizable.strings`
- `StarMagpie/en.lproj/InfoPlist.strings`
- `StarMagpie/zh-Hans.lproj/InfoPlist.strings`

新增 UI 文案时，需要在同一次变更中同步更新英文和简体中文本地化文件。

## 项目结构

```text
StarMagpie/
├── StarMagpie/                 # App 源码
│   ├── App/                    # App 入口与根视图
│   ├── Models/                 # SwiftData 模型和筛选逻辑
│   ├── Services/               # GitHub API、Keychain、归档和同步服务
│   ├── Utilities/              # 本地化、文档和全局设置工具
│   ├── Views/                  # SwiftUI 视图
│   ├── Assets.xcassets/        # App 图标和资源
│   ├── en.lproj/               # 英文本地化
│   └── zh-Hans.lproj/          # 简体中文本地化
├── StarMagpieTests/            # 单元测试
├── .github/                    # Issue 模板、PR 模板、CI 和发布工作流
├── docs/                       # 文档素材
├── scripts/                    # 本地维护脚本
├── AGENTS.md                   # Agent 开发约定
├── CLAUDE.md -> AGENTS.md      # Claude 兼容软链接
├── CONTRIBUTING.md             # 贡献指南
├── CODE_OF_CONDUCT.md          # 行为准则
├── SECURITY.md                 # 安全政策
├── SUPPORT.md                  # 支持说明
├── LICENSE                     # GNU GPL v3
├── README.md                   # 英文 README
└── project.yml                 # XcodeGen 配置
```

## 仓库 Topics

建议在 GitHub 仓库中设置这些 topics：

```text
macos
swift
swiftui
swiftdata
github
github-stars
github-api
keychain
xcodegen
productivity
open-source
```

## 贡献

欢迎提交 Issue 和 Pull Request。开始前请阅读：

- [贡献指南](CONTRIBUTING.md)
- [行为准则](CODE_OF_CONDUCT.md)
- [安全政策](SECURITY.md)

提交 Bug、问题或功能建议时，请使用 GitHub Issue 模板。适用时请提供 macOS 版本、Xcode 版本、复现步骤和相关日志。

## 许可证

StarMagpie 使用 [GNU General Public License v3.0](LICENSE) 授权。
