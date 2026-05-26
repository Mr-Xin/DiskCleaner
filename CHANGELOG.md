# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 风格，版本号采用 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [0.1.0] — 2026-05-26

第一个可运行版本：四大核心功能全部实现。

### 新增

**核心引擎（DiskCleanerCore）**

- `DiskScanner` — 递归扫描目录树，构建带尺寸的 `FileNode`；支持进度回调与取消。
- `HashService` — 基于 CryptoKit 的局部（头尾）哈希与流式完整哈希。
- `DuplicateFinder` — 三级流水线（按大小分组 → 局部哈希 → 完整哈希），含硬链接去重。
- `JunkRulesEngine` + `JunkRuleCatalog` — 10 条内置规则，覆盖用户缓存、日志、废纸篓、浏览器缓存、Xcode DerivedData、包管理器缓存、邮件下载、旧 iOS 备份、系统缓存等。
- `AppUninstaller` — 枚举 `/Applications` 与 `~/Applications`，按 bundle id（高匹配度）与应用名（低匹配度）定位残留文件。
- `LargeFileFinder` — 在已扫描树中筛出超过阈值的大文件。
- `TreemapLayout` — squarified 方块树图布局算法（纯几何，独立测试）。
- `ProtectedPaths` — 受保护路径黑名单与校验。
- `DeletionService` — 「移到废纸篓」删除服务，所有路径都先过受保护校验。
- `PermissionsChecker` — 通过探测 TCC 数据库检测完全磁盘访问。

**应用层（SwiftUI）**

- 完全磁盘访问引导页（含跳转系统设置；兼容 macOS 13 之前与之后两套面板 ID）。
- 磁盘空间可视化：树图 + 尺寸列表，支持下钻、上一级、移到废纸篓。
- 垃圾清理：分类列表、安全 / 需确认双标签、勾选合计、一键清理。
- 大文件 / 重复文件：选定文件夹分析，分段切换两类结果。
- 应用卸载：应用列表 + 残留按匹配度分组 + 卸载并清理。

**工程**

- 从 AppKit + Storyboard 模板迁移到纯 SwiftUI App 生命周期。
- 引入独立 `DiskCleanerCore` Swift Package，UI 与逻辑解耦。
- 8 项核心引擎单元测试（ByteSize、ProtectedPaths、JunkRuleCatalog、DiskScanner、HashService、DuplicateFinder、TreemapLayout、FileSystemUtilities）。
- GitHub Actions CI：在 macOS runner 上构建并测试核心包。
- 仓库基础文件：LICENSE (MIT)、README、CONTRIBUTING、.gitignore、规划文档。

### 已知限制

- 扫描使用 `FileManager`，未启用 `getattrlistbulk` 提速；扫描百万级文件树会比较慢。
- 重复文件检测目前不识别 APFS 克隆（克隆文件 inode 不同但共享物理存储，识别为重复会误导用户）。
- 完全磁盘访问检测为启发式（探测 `TCC.db`），需在更多 macOS 版本上长期验证。
- 系统级缓存（`/Library/Caches/*`）需要管理员权限，本版本不会处理。
- 尚未做代码签名、公证、打包；目前仅可在源码本地构建运行。
