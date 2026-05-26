# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 风格，版本号采用 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [0.6.1] — 2026-05-26

### 改进

- 侧边栏底部菜单按钮加高，视觉更舒展：
  - 左侧 app 图标改为 32×32 的圆形高亮（带浅色 tint 底色）
  - 主标题「DiskCleaner」+ 副标题「v0.x.y」（自动从 Bundle 读取 `CFBundleShortVersionString`）
  - 内外 padding 都微增，整体高度从 ~32pt 提到 ~54pt

## [0.6.0] — 2026-05-26

侧边栏左下角加 Claude 风格的快捷菜单。

### 新增

- **侧边栏底部固定一个按钮**，点击弹出菜单：
  - **设置**（`Cmd+,`，通过 SwiftUI 原生 `SettingsLink` 打开 Settings 场景）
  - **语言 ▸** 二级菜单：跟随系统 / 简体中文 / English（当前选中带 ✓）
  - **关于 DiskCleaner**（macOS 标准 About 面板，显示版本与版权）
- 侧边栏里切换语言后，弹出与 Settings 里一致的「语言已更改」对话框，可立即重启或稍后。

### 改进

- 切换语言不再需要打开 Settings——侧边栏两步搞定。
- `Localizable.xcstrings` 补「设置」「关于 DiskCleaner」的英文翻译。

### 实现要点

- SwiftUI `Menu` + 嵌套 `Menu` 实现一二级菜单。
- 用 `SettingsLink`（macOS 14+ 原生 API）作为打开 Settings 的入口，免去手写 `@Environment(\.openSettings)` 调用。
- `.menuIndicator(.hidden)` 隐藏 Menu 自带的小箭头，因为按钮 label 自己带了上下箭头图标。
- About 面板用 `NSApplication.orderFrontStandardAboutPanel(nil)`，自动读取 Bundle 的版本与版权（v0.3 设的 `NSHumanReadableCopyright` 终于派上用场）。

## [0.5.0] — 2026-05-26

App 内语言切换：不用改系统语言，直接在设置里选。

### 新增

- **App 内语言选择器**：设置 ▸ 常规 ▸ 语言。可选「跟随系统」「简体中文」「English」。
- 切换后通过覆写 `UserDefaults` 的 `AppleLanguages` 键生效，弹出「语言已更改」对话框，可选立即重启或稍后。
- 「立即重启」会用 `open -n` 启动应用新实例并退出当前实例，新语言下次启动即生效。

### 改进

- `Localizable.xcstrings` 新增 6 条与语言选择器相关的字符串（"语言"、"跟随系统"、"语言已更改"、"立即重启"、"稍后"、重启提示文案）。总条目从 80 增至 86。
- 语言名称（"简体中文"、"English"）使用 `Text(verbatim:)` 显式跳过本地化——每种语言始终以自己的名字显示。

### 实现细节

- macOS 标准做法：app 设置 `AppleLanguages` 数组 → 下次启动时 `CFBundle` 与 `CFLocale` 自动使用该语言。无需自定义 bundle 查找逻辑。
- 选「跟随系统」时清空 `AppleLanguages`，让 macOS 回到系统语言。

## [0.4.0] — 2026-05-26

性能与国际化收尾：扫描底层换 `getattrlistbulk`，重复文件并行哈希，应用卸载顺手卸 LaunchAgent，关键字符串中英双语。

### 性能

- **`getattrlistbulk` 全面接入** — C 桥新增 `dc_bulk_open` / `dc_bulk_next` / `dc_bulk_close`，单次系统调用拿到目录里所有子项的名字、对象类型、逻辑大小、分配大小、APFS clone id。`DiskScanner` 默认走 bulk 快路径，遇到错误自动回退 `FileManager`。大目录扫描显著提速。
- **`DuplicateFinder` 哈希并行化** — `bucketed(_:using:)` 改用 `TaskGroup`，同尺寸文件桶里的局部 / 完整哈希现在并发跑（Swift 协作线程池自然限流到 CPU 核心数）。

### 改进

- **应用卸载顺带 `launchctl unload`** — `AppUninstaller` 新增 `unloadLaunchServices(among:)`：识别残留里 `~/Library/LaunchAgents/*.plist` 与 `/Library/LaunchDaemons/*.plist`，删 plist 前先调 `launchctl unload`，避免卸完应用还有僵尸服务在跑。`UninstallViewModel.uninstall()` 自动调用。
- **关键字符串中英双语** — 新增 `Localizable.xcstrings`，覆盖五个功能名 / 高频按钮 / 段落标题 / 设置项 / 垃圾分类 / 空状态 / FDA 引导（约 80 条）。`developmentRegion` 改成 `zh-Hans`，中文系统继续用中文，英文系统切到英文翻译。详细的状态文案 / 错误细节 / 规则描述本轮未翻，留后续补全。

### 测试

- 新增 `BulkEnumerationTests`：跑 `dc_bulk_open` + `dc_bulk_next` 解析已知目录，验证 C 缓冲区布局解析正确（这是 v0.4 最容易翻车的地方，单测专门覆盖）。
- 新增 `AppUninstallerTests`：验证 LaunchAgent / Daemon plist 的路径判别。
- 既有 `DiskScannerTests` 现在隐式覆盖 bulk 路径（temp 目录在 APFS 卷上时会走 bulk）。

### 已知限制 / 待办

- 详细文案与规则说明的本地化（v0.5）。
- `DuplicateFinder` 并行哈希没有上限——对极大同尺寸桶可能过度并发，留 v0.5 加 maxConcurrent 控制。
- 代码签名 / 公证 / 打包（v1.0）。

## [0.3.0] — 2026-05-26

UI/UX 打磨：应用图标、设置面板、键盘快捷键、更友好的错误提示。

### 新增

**应用层**

- 应用图标（placeholder）：渐变背景 + 饼图剪影，Python 生成的全套 macOS 尺寸（16/32/64/128/256/512/1024，含 @2x）。
- **设置面板**（`Cmd+,`），两个 tab：
  - **常规**：默认扫描位置（主目录 / 上次使用的位置 / 每次询问）。
  - **检测**：大文件阈值（10–2048 MB）、审计日志保留上限（50–5000 条）。
- **主菜单「功能」+ 键盘快捷键** `Cmd+1..5` 切换五个功能页（磁盘可视化、垃圾清理、大文件/重复文件、应用卸载、最近操作）。
- **`ErrorView` 共享错误组件**：自动从 `LocalizedError` 取出 errorDescription + recoverySuggestion，可选「重试」「打开系统设置」动作按钮。

**引擎**

- `DeletionError` 实现 `LocalizedError`：受保护路径的删除拒绝会显示明确说明与建议。

**About**

- 版本号提升至 `0.3.0`（`MARKETING_VERSION`）。
- 加入 `INFOPLIST_KEY_NSHumanReadableCopyright`：系统自带「关于 DiskCleaner」对话框会显示版本与版权 / 许可证信息。

### 改进

- 各视图模型从 `errorMessage: String?` 升级为 `lastError: (any Error)?`；UI 通过 `ErrorView` 同时展示标题与建议动作。
- 磁盘可视化页：「扫描主目录」按钮改为「扫描默认位置」，遵循设置项行为；记录最近扫描位置以支持 lastUsed 选项。
- 大文件查找使用设置项中的阈值（替代硬编码的 100MB）。
- 审计日志读取使用设置项中的上限（替代硬编码的 500）。

### 待办 / 已知限制

- 中英文本地化（String Catalog）—— 留到 v0.4。
- `getattrlistbulk` 全面迁移 —— 留到 v0.4。
- 应用图标是 placeholder，欢迎替换为正式设计稿。
- 代码签名 / 公证 / 打包 —— v1.0 主题。

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
