# DiskCleaner

一款面向 macOS 的磁盘管理与清理工具：看清磁盘空间被什么占用、安全地回收无用空间、干净地卸载应用。

> **项目状态：v0.1 — 四大功能均已实现，可本地编译运行。** 路线后续会推进性能优化、签名公证与正式发布，更新见 [`CHANGELOG.md`](CHANGELOG.md)。

## 功能

| 功能 | 说明 | 状态 |
|---|---|---|
| 磁盘空间可视化 | 扫描磁盘，以矩形树图展示空间占用并逐层下钻 | ✓ v0.1 |
| 大文件 / 重复文件查找 | 找出超大文件与内容重复的文件 | ✓ v0.1 |
| 垃圾清理 | 按类别识别并清理缓存、日志、临时文件等 | ✓ v0.1 |
| 应用卸载 | 卸载应用并清除其散落在系统各处的残留文件 | ✓ v0.1 |

完整路线图见 [`规划文档.md`](规划文档.md)。

## 项目结构

```
DiskCleaner/
├── DiskCleaner/            # App 层（SwiftUI）
│   ├── DiskCleanerApp.swift
│   └── ContentView.swift
├── DiskCleanerCore/        # 核心逻辑 Swift Package（无 UI，可独立测试）
│   ├── Package.swift
│   ├── Sources/DiskCleanerCore/
│   │   ├── Model/          # FileNode、ByteSize
│   │   ├── Scanner/        # DiskScanner
│   │   ├── Hashing/        # HashService
│   │   ├── Duplicates/     # DuplicateFinder
│   │   ├── Junk/           # JunkRule、JunkRuleCatalog、JunkRulesEngine
│   │   ├── Uninstall/      # AppUninstaller
│   │   ├── Deletion/       # ProtectedPaths、DeletionService
│   │   └── Permissions/    # PermissionsChecker
│   └── Tests/
├── DiskCleanerTests/       # App 层测试
├── DiskCleanerUITests/
└── .github/workflows/      # CI
```

核心逻辑全部放在独立的 `DiskCleanerCore` 包里，与 UI 解耦，便于单元测试与复用。

## 开发与构建

需要 Xcode 与 macOS。

### 核心逻辑包（可独立开发，无需 Xcode）

```bash
cd DiskCleanerCore
swift build
swift test
```

### 完整应用

1. 用 Xcode 打开 `DiskCleaner.xcodeproj`。
2. 选择 `DiskCleaner` scheme，`Cmd+B` 构建或 `Cmd+R` 运行。
3. 首次运行会显示完全磁盘访问引导页——按提示在系统设置中授予权限，回到 app 点「重新检查」即可使用全部功能。

## 权限与分发

磁盘清理工具需要读取系统各处的文件，这受 macOS 的 **完全磁盘访问（Full Disk Access）** 保护：

- 应用以 **非沙盒** 方式构建，运行时引导用户在「系统设置 ▸ 隐私与安全性 ▸ 完全磁盘访问」中授权。
- 因此本应用 **不会上架 Mac App Store**（App Store 要求开启沙盒），而通过 GitHub Releases 的 `.dmg` 或 Homebrew Cask 分发。

## 测试

`DiskCleanerCore` 使用 [Swift Testing](https://developer.apple.com/documentation/testing)。CI 会在每次 push / PR 时于 macOS 上构建并测试该包。

## 安全设计

DiskCleaner 会删除用户文件，安全性是第一原则：

- 默认 **移到废纸篓**（可恢复），而非永久删除。
- 所有删除操作都先经过 `ProtectedPaths` 受保护路径校验。
- 拿不准的清理项默认不勾选，需用户显式选择。

## 许可证

[MIT](LICENSE)

## 免责声明

本软件按「现状」提供，会对文件系统执行删除操作。请自行承担使用风险，重要数据请提前备份。作者不对任何数据丢失负责。
