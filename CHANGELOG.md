# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 风格，版本号采用 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [0.2.0] — 2026-05-26

让现有功能更扎实——扫描看得见、可取消，APFS 克隆不再误判，删了什么都查得到。

### 改进

**性能**

- `DiskScanner` 改为并行扫描：根目录的顶层子树用 `TaskGroup` 并发遍历，多核机器上明显更快。

**进度与取消**

- 引擎进度按 ~10Hz 节流回调，UI 显示已扫描项数、累计字节与当前路径。
- 磁盘可视化、垃圾清理、大文件 / 重复文件三个扫描界面都加了「取消」按钮（Esc 同样可取消）。
- `JunkRulesEngine.scan` 新增 `onProgress` 回调。

**正确性**

- 新增 `DiskCleanerCoreBridge` C 桥，封装 `getattrlist` 取 APFS clone identifier。
- `DuplicateFinder` 用 clone id 排除 APFS 克隆——同源克隆不再被误报为可清理的重复。

**审计与可追溯**

- 新增 `AuditLog` actor，每次"移到废纸篓"以 JSONL 追加到 `~/Library/Application Support/DiskCleaner/audit.log`。
- 新增「最近操作」侧边栏页：浏览历史、在访达中显示日志文件、一键清空。
- `DeletionService` 增加 `source` 参数，记录是哪个功能触发的删除（`disk-map` / `junk-clean` / `duplicates` / `uninstall`）。

**权限体验**

- `ScanResult` 新增 `blockedDirectoryCount`，扫描时统计因权限读取失败的目录数。
- 扫描结束若 FDA 未授予且受阻目录 > 0，磁盘可视化与重复文件界面顶部出现橙色横幅，附带「去授权」一键跳转。

### 测试

- 新增：`AuditLogTests`、`CloneIDTests`。
- 更新：`DiskScannerTests` 适配新的 `ScanResult` API 并加了进度回调断言。

### 已知限制

- `getattrlistbulk` 的全面迁移（更深层的扫描提速）留待 v0.3。
- 应用卸载暂不自动 `launchctl unload` LaunchAgent / Daemon（留待 v0.3）。
- 系统级缓存清理（`/Library/Caches/*`）仍需要管理员权限，本版本不会处理。
- 代码签名 / 公证 / 打包尚未做，目前仅源码本地构建运行。

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
