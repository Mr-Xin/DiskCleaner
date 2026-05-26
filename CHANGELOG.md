# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 风格，版本号采用 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [0.10.0] — 2026-05-27 — 把剩下的 Sprint 全跑完

一晚通跑：Sprint 3-7 完整接入 DiskFlow 视觉 + v1.0 必发的两个确认弹窗 + Sprint 9 ⌘K 命令面板 + History 重设计。需要系统级权限的子功能（菜单栏 mini-app、桌面 Widget、Apple Shortcuts、iCloud 同步、定时任务唤醒）按用户要求跳过，留到打包签名一并处理。

### Sprint 3 — Storage Analyzer 重设计

`DiskMapView` 整屏按 DiskFlow §4.1 重做：

- 顶部 action 行用 `DesignButton(.default/.ghost, .small)` + `DesignChip` 替换原生 `Button` / `Label`，所有控件走 token
- 主区改为左 treemap canvas + 右 320pt 详情面板：
  - 详情面板含 **当前路径 breadcrumb**（最多展示末尾 4 段，最后一段加粗）
  - **占用分布列表**：top 6 子项 + 每项 `DesignBar(.default)` 横条（按占比），选中行蓝边 + 蓝底
  - **Insight 卡**（蓝色光晕 glass card）：根据当前目录最大子项写一句话洞察（"X 占了 Y，是当前目录的最大占用项"）
  - **Clean CTA**：选中项时变 primary「移到废纸篓 · X」按钮；未选时灰态提示
- TreemapView tile 颜色从随机 HSV 切换为 DiskFlow 7 段分类色循环；选中态加蓝色发光描边
- 选中项的右键菜单全部走 i18n key（`storage.context.*`）
- 扫描中 / 错误 / 空状态分别复用 `LoadingStateView` / `ErrorStateView` / `EmptyStateView`
- `PermissionBanner` 改为 DiskFlow 风格的 warn-tinted 玻璃条

### Sprint 4 — Large Files 独立屏

新文件 `DiskCleaner/Features/LargeFilesView.swift` —— `ContentView.detailView` 里的 `.largeFiles` 终于不再错路由到 `DuplicatesView`，现在指向真实的大文件视图：

- 顶部 action 行 + 类型筛选 chips（All / Video / Archive / Image / Audio / Folder / Other）
- 主区 = 左侧表格 + 右侧 280pt 预览面板
  - **表格 6 列**：复选框 / DesignGlyph（按扩展名分色）/ 名称+路径 / 大小 / 修改时间（`RelativeDateTimeFormatter`）/ 类型 / 更多菜单
  - **预览面板**：16:10 渐变缩略图（按类型挑 SF Symbol + 类别色渐变）+ 元信息（Size/Type/Modified）+ Reveal / Trash 双按钮
- `LargeFilesViewModel` 用 `DiskScanner` 扫树 + `LargeFileFinder` 筛 ≥ `AppSettings.largeFileThresholdMB()` 的文件
- 底部 FAB：选中数 + 总大小 + Move to Trash 按钮，>1 GB 时弹 `ConfirmDeleteSheet`
- 单击行选中 1 项，复选框多选；右上「⋯」菜单提供 Reveal / Trash 单项操作

### Sprint 5 — Duplicates 重设计

`DuplicatesView` 完整按 §4.1 重做，**剥离 large-files 路径**（已迁出到独立屏）：

- 左 260pt 分组列表：当前组左侧 3pt 蓝色边条 + 蓝底背景；每行显示文件名 + 份数 + reclaimable bytes（绿色）
- 右侧对比面板：
  - **KEEP 卡**（`DesignCard(.glowBlue)`，绿点 badge）—— 当前保留的副本
  - **VS 分隔符**
  - **DELETE 卡** 堆叠（红点 badge + danger 底色），每张支持「改保留这个」(swap keeper) / 「移到废纸篓」(单项删除)
- 底部 FAB：当前组可释放量 + 全局累计 + Skip / Apply smart pick 按钮
- ViewModel 重构：`keepers: [Int: URL]` 管理每组的 keeper 选择，`applySmartPick()` 一键把当前组的非 keeper 全部 trash 后自动跳到下一组
- 单项删除后若组剩 ≤1 项，整组自动剔除

### Sprint 6 — Memory Monitor（无须权限路径）

新文件 `MemoryView.swift`：

- `MemoryStatsModel` 以 1 Hz 节奏轮询 Mach `host_statistics64` + `sysctlbyname("vm.swapusage")`，60 秒环形缓冲
- 内存口径：In use（active + wired + compressed），Cached（inactive + purgeable），Swap（`xsw_usage.xsu_used`），CPU（`host_cpu_load_info` ticks 增量）
- 4 张统计卡，每张：value + 颜色匹配的 Swift Charts sparkline（24pt 高）+ 类别色发光圆点
- 主图：60s 双线（RAM% 蓝 + CPU% 青）+ 填充渐变 + 左侧 0/50/100 % 标签
- 进程列表占位：明确告知 per-process 数据需要 `proc_pidinfo` entitlement（README §13.04 类逻辑：先跳过）
- 同时给 Dashboard 的 memory mini 卡加一次性数据：`readMemorySampleOnce()` 用于一次性读取，避免 Dashboard 同时多开一个 polling 计时器
- `ContentView` 把 `.memory` 路由从 `ComingSoonView` 切到 `MemoryView`

### Sprint 7 — App Uninstaller 重设计

`UninstallView` 重做为 4 列 LazyVGrid：

- 每个 app card：`NSWorkspace.shared.icon(forFile:)` 渲染真实图标（圆角 22%）+ 名称 + bundleID（mono）
- 选中态：blue glow border + box-shadow + bg tint
- 选中后下方展开 detail panel：app icon + 名称 + bundle + scan chip，下面列出**按目录类型分桶的关联文件**（Caches / App Support / Preferences / Launch services / Other），每行可单独勾选
- 底部 FAB：「保留应用，仅清残留」(ghost) vs「完全卸载」(danger primary)
- 工具栏加搜索输入框（按名称 / bundle ID 实时过滤）
- 「完全卸载」按下弹 `ConfirmUninstallSheet`（详见下节）
- 新增 `AppIconView` 复用组件（图标加载失败有 fallback）

### v1.0 补完 — 删除 / 卸载确认弹窗

新文件 `DiskCleaner/Design/ConfirmationSheets.swift`：

**`ConfirmDeleteSheet`**（440pt 居中卡，DiskFlow §13.04）

- 黄色 warn 光晕图标 + 标题 + 主体（释放量 X GB 文案）
- 文件列表：最多 6 行，超出显示「还有 N 项」
- 「下次类似操作不再询问」复选 → 写入 `UserDefaults["DiskCleaner.confirmDelete.dontAsk"]`
- 双按钮：Cancel / Move to Trash（danger）
- LargeFilesView 在选中 ≥ 1 GB 且用户未勾「不再询问」时弹此 sheet

**`ConfirmUninstallSheet`**（480pt 居中卡）

- 64pt 应用图标 + 标题 + 副标题（应用名 + 关联文件总量）
- 分桶清单：Caches / App Support（高风险，黄色高亮 + risky chip）/ Preferences / Launch services / Other，每行展示文件数 + 大小
- 黄色信息条：解释 .app 可能需要管理员权限
- 「保留应用支持目录」复选 → confirm 时把 Application Support 中的项从 selection 剔除
- 双按钮：Cancel / Uninstall（danger）
- UninstallView 的「完全卸载」按钮按下时弹此 sheet

### Sprint 9 — ⌘K 命令面板

新文件 `DiskCleaner/Design/CommandPalette.swift`：

- 620pt 居中浮层，背景 55% 黑色 + ESC / 外部点击关闭
- 顶部搜索栏：sparkles 图标 + TextField + 闪烁光标（0.6 s 周期 Timer）+ 右侧 `⌘K` keycap
- 4 分组：**推荐操作 / 跳转 / 动作 / 最近**（每组前都有 uppercase tracking label）
- 高亮行：3pt 蓝色左边条 + 蓝底 + icon 变 blueHi + 行加粗
- ↑↓ 上下移动，Enter 执行，hover 自动 highlight 该行
- 12 个内置命令：Run smart cleanup / Rescan / Overview / SmartCleanup / Storage / LargeFiles / Duplicates / Apps / Memory / Settings / Open Trash / Scan history
- 通过隐藏 Button + `.keyboardShortcut("k", modifiers: .command)` 接入 ⌘K 全局快捷键（标准 SwiftUI 路径，无需 NSEvent monitor）
- ContentView 用 ZStack 把 palette 叠在 DesignFrame 之上，transition 用 0.18s opacity + scale 渐入

### Cleanup History（HistoryView）重设计

- 顶部 action 行换 `DesignButton(.ghost/.danger, .small)`，加 snapshot 数量 chip
- 趋势图卡：DesignCard(.elevated) 包裹 Swift Charts，line + point mark 用按路径分色，y/x 轴标签走 token 颜色
- 快照列表：DesignCard(.default) 容器，最多展示 50 行；每行 clock 图标 + 路径 + 时间戳 + 大小 + 项数
- 空 / 加载状态复用 `LoadingStateView` 与 `ContentUnavailableView`

### 通用改动

- 跳过的事项（与用户对齐"需要权限的任务先跳过"）：
  - 浅色主题切换（design tokens 全部基于深色定义，整体改造需要单独 Sprint）
  - 菜单栏 mini-app · 桌面 Widget（需要不同的 bundle 类型 + 签名）
  - Apple Shortcuts 集成（需要 App Intents + entitlement）
  - iCloud 偏好同步（需要 Container entitlement）
  - 定时扫描 LaunchAgent（v0.7 已有 in-app 提醒，离线唤醒留到代码签名后）
  - Memory 进程列表（需要 `proc_pidinfo` entitlement）
- `Feature.largeFiles` 路由修正：从 `DuplicatesView` 改指 `LargeFilesView`
- `Feature.memory` 路由从 `ComingSoonView` 改指 `MemoryView`

### i18n 字符串

`Localizable.xcstrings` 一次性加入 ~150 条新 key（zh-Hans + en），涵盖：

- `storage.*` —— Storage Analyzer 视图（17 条）
- `largefiles.*` —— Large Files 视图（24 条）
- `duplicates.*` —— Duplicates 视图（20 条）
- `memory.*` —— Memory Monitor（13 条）
- `uninstall.*` —— App Uninstaller 重做（15 条）
- `confirm.*` —— 两个确认 sheet（13 条）
- `palette.*` —— 命令面板（13 条）
- `history.*` —— 扫描历史卡片（8 条）
- `permission.cta.grant`、`smartcleanup.access.unknown` 等若干

### 后续

剩下的真正需要权限 / 系统集成的事项：

- 浅色主题切换（design tokens 重构）
- 菜单栏 mini-app + Widget + Apple Shortcuts + iCloud 偏好同步（README §13.07）
- LaunchAgent 后台定时扫描提醒
- Memory per-process 列表
- 应用打包 / 公证 / 代码签名（v1.0 主题）

## [0.9.2] — 2026-05-27 — Smart Cleanup 闭环 + 真实扫描数据

把 v0.9.1 留下的两个尾巴一起做完：「立即清理」按钮真正走 `DeletionService`，Dashboard 与 Smart Cleanup 用同一份 `JunkRulesEngine` 扫描结果。先点 Dashboard 看到真实可释放量 → 进 Smart Cleanup 看到真实分组 → 点「立即清理」走过渡动画 → 移到废纸篓 → Success 屏，全程跑通。

### 新增

**JunkScanStore 共享扫描服务**（`DiskCleaner/Features/JunkScanStore.swift`）

`@MainActor @Observable` 单例 store：

- `categories: [SmartCleanupCategory]` —— 扫描后由 `SmartCleanupCategory.fromJunkItems(_:)` 映射而来
- `isScanning / hasScanned / lastScanAt / lastError` 状态字段
- `totalReclaimableBytes / totalItemCount` 给 Dashboard 用的汇总
- `ensureScanned()` —— 首次进入 SmartCleanup 屏时懒触发，重入安全
- `scan()` —— 强制扫描，跑在 `Task.detached(priority: .userInitiated)` 里避免阻塞主线程（`JunkRulesEngine` 的同步 FileManager 操作不会自动让步）

ContentView 用 `@State scanStore = JunkScanStore()` 持有，Dashboard / Smart Cleanup 各拿到引用，**全 App 只扫一次**。

**SmartCleanupCategory.fromJunkItems(_:) 引擎适配器**

把 `JunkRulesEngine` 输出的 `[JunkItem]` 映射到 UI 的 6 个分类：

- `cache` ← `.userCache + .browserCache + .developerJunk + .packageManagerCache + .systemCache`
- `temp` ← `.logs + .trash`
- `downloads` ← `.mailDownloads + .largeOldDownloads`
- `large` ← `.oldDeviceBackup`
- `custom` 默认归到 `cache`
- `duplicates / leftover` 无引擎数据，保留 `samples()` 占位（等 DuplicateFinder / AppUninstaller 接入再换掉）

每条 `JunkItem` 用 `SmartCleanupItem(junkItem:)` 构造，自动：
- `url`、`bytes`、`name`、`path` 直接来自 `JunkItem`
- `lastAccessDisplay` 取 `URLResourceKey.contentAccessDate ?? .contentModificationDate`，用 `RelativeDateTimeFormatter(.short)` 格式化为「2 周前」
- `risk = item.rule.safety == .safe ? .safe : .caution`
- `reasonDisplay = item.rule.explanation`（Chinese 自带）
- `defaultSelected = item.rule.safety == .safe`

**SmartCleanupPhase 状态机**

`SmartCleanupModel.phase: SmartCleanupPhase` 三态：

- `.picking` —— 现有的选择 UI
- `.cleaning(progress: CleanupProgress)` —— 切到 `CleaningStateView`
- `.success(summary: CleanupSummary)` —— 切到 `SuccessStateView`

`runCleanup()` async：
1. 按当前展示顺序，把选中的项按 category 分组（带 `url` 的才算）
2. 为每个 category 构造一个 `CleaningTask`，初始全 `.queued`，进入 `.cleaning` 阶段
3. 顺序处理每个 category：状态从 `queued → running → done`，每个之间 `Task.sleep(350ms)` 让眼睛看清动画
4. 每批调用 `DeletionService.moveToTrash(urls, source: "smart-cleanup")`，trashed URLs 进集合，从 categories 里剔除（用户回 picking 时看到的就是清理后的状态）
5. 全部完成后切到 `.success`，breakdown 按 category 排序

**SmartCleanupView 阶段渲染**

- `body` 用 `switch model.phase` 切三种屏
- `.task` 入口：`store.ensureScanned()` + `model.applyCategories(store.categories)`
- `.onChange(of: store.lastScanAt)` 同步：用户点工具栏「重新扫描」时也能立刻刷新
- 扫描中且没有缓存数据时，picker 上叠一层 `LoadingStateView` + `MeshGradientBackground`
- 「立即清理」按钮加 `canCleanup` 守卫：必须至少有一个带真实 `url` 的项被勾选才能点
- success 屏的 breakdown 按 category 着色（`label == titleDisplay` 反查 category color）

**Dashboard 真实数据接入**

- `DashboardView` 接受 `store: JunkScanStore?` 参数
- 新增 `effectiveReclaimableBytes / effectiveQuickWinsCount / effectiveSuggestions` 派生属性：`store.hasScanned` 时用 store 数据，否则用 placeholder snapshot
- 3 张 Smart Cleanup 建议卡：扫完后取 store 中字节数最多的 3 个非空 category，每张卡的 title 用 category 内最大那一项的 name，glyph / 颜色 / summary 来自 category
- Health Score 卡和 Smart Cleanup 段的「N 项建议 · X.X GB」汇总也跟着更新
- `.task` 入口顺手 `store?.ensureScanned()` ——首次进 Dashboard 自动后台扫，扫完数字静默升级

**ContentView 工具栏「清理 X.X GB」**

- `cleanupCtaAmount` 计算属性：有真实扫描结果就显示真实可释放量，否则保留 "12.4 GB" 占位
- 「重新扫描」ghost 按钮接 `Task { await scanStore.scan() }`，真正触发扫描

### 改动

**模型字段**

- `SmartCleanupItem` 新增 `url: URL?`（占位为 `nil`）
- `SmartCleanupItem.lastAccessKey: LocalizedStringKey` → `lastAccessDisplay: String`，构造时 `NSLocalizedString` 解析；real items 用 `RelativeDateTimeFormatter` 出文案
- `SmartCleanupItem.reasonKey: LocalizedStringKey` → `reasonDisplay: String`，real items 直接拿 `rule.explanation`
- `SmartCleanupCategory` 新增 `titleDisplay: String`（在 `runCleanup` 构造 task title 时用，不走 SwiftUI 解析）
- `SmartCleanupModel` 改为 `@MainActor`，新增 `phase / lastError / applyCategories(_:) / resetToPicking() / runCleanup()`

**SwiftUI 视图**

- `SmartCleanupView.init` 现在要求传入 `store: JunkScanStore`，新增 `onDone: () -> Void` 回调（success 屏「完成」按钮按下时路由回 Dashboard）
- 旧的 `onRunCleanup: (Int64, Int) -> Void` 回调移除（清理改为内部 phase 转换）
- `DashboardView.init` 新增 `store: JunkScanStore?` 形参

**i18n 字符串**

- 新增 `smartcleanup.access.unknown`（zh-Hans「未知」/ en "unknown"）—— 当文件没有 access date / mod date 时兜底

### 后续

Sprint 3 候选（按 README §10）：

- 把工具栏「重新扫描」按钮加进度反馈（rotating chevron / progress chip）
- 把 Duplicates / Leftover 两个 category 也接到真实引擎（`DuplicateFinder` / `AppUninstaller`）
- Storage Analyzer Sunburst（可先 treemap 占位）
- Dashboard donut 的 6 段分类也切到真实数据（需要按目录大小聚合 `ScanSnapshot`，比 Junk 扫描复杂得多）

## [0.9.1] — 2026-05-26 — Smart Cleanup 中心 + Cleaning 过渡屏

把 Sprint 2 收尾收到底：实现智能清理中心（Dashboard 两个 CTA 的真正落点）+ Cleaning 过渡状态屏 + 配套的 Checkbox/Risk 两个 atom 组件。Dashboard 上的「运行智能清理」「查看全部」按钮现在能跳到 Smart Cleanup 屏；侧栏新增「智能清理」入口（带 sparkles 图标）。

### 新增

**两个新 atom 组件**

- `DesignCheckbox`（`DiskCleaner/Design/DesignCheckbox.swift`）—— 14×14 自定义复选框，3 个状态（off / on / indeterminate），on 时蓝渐变 + 阴影光晕，indeterminate 时白色横线
- `DesignRisk`（`DiskCleaner/Design/DesignRisk.swift`）—— 三档风险徽章 + `RiskLevel` 枚举（safe 绿 / normal 蓝 / caution 黄），匹配 §4.1 的 `<Risk level />`，统一 18pt 高 pill 带发光小点

**SmartCleanupView 主屏**（`DiskCleaner/Features/SmartCleanupView.swift`）

布局完整还原 `hifi-smart-cleanup.jsx`：

- 左侧 240pt 过滤侧栏：顶部「19.6 GB · 共 6 类 · 260 项」总览；6 个分类项，激活态有蓝边 + 浅蓝背景，已勾选数显示为蓝色 badge；底部「安全保障」glass 卡片说明
- 主区标题栏：sparkles 图标 + 「智能清理」+ 副标题；右侧 3 个风险筛选 chips（全部 / 仅安全 / 需复核），用 `DesignChip` 的 active 态
- 分组卡：当前展开的分组用 `DesignCard(.elevated)` 显示完整 8 列表格（32 / 80 / 32 / 1fr / 110 / 110 / 70 / 24）+ 头部带分类色顶部渐变叠加；其他分组用 `DesignCard(.default)` 折叠显示一行（复选框 + 色块 + 标题/副标题 + 大小 + chevron）
- 项目行：组合 `DesignCheckbox` + `DesignRisk` + `DesignGlyph`（缩写自名字前两位）+ 名称/路径 + 说明 + 最近访问 + 大小 + ellipsis；选中行整体淡蓝背景
- 底部浮动操作栏（FAB）：`DesignCheckbox`（已选中全清开关）+ 「已选中 N 项」+ 18pt 渐变大数字「· X.X GB」+ 风险分布（只显示非零，颜色编码）+「仅勾选安全项」ghost 按钮 +「立即清理 X.X GB」primary 按钮带 sparkles 图标

**SmartCleanupModel**（`DiskCleaner/Features/SmartCleanupModel.swift`）

`@Observable` final class 把所有渲染状态收拢：

- `categories: [SmartCleanupCategory]`（6 个内置，每个含 `items: [SmartCleanupItem]` 数组）
- `selectedItemIDs: Set<UUID>` —— 跨分组选中集合
- `expandedCategoryID: String?` —— 当前展开分组（互斥）
- `activeCategoryID: String?` —— 左侧 focus
- `filter: SmartCleanupRiskFilter` —— 全部 / 仅安全 / 需复核
- `toggle / toggleAll / selectOnlySafeItems / focusCategory / expand` 等 mutators
- `groupCheckboxState(_:)` 三态算法：全选 → .on，部分 → .indeterminate，未选 → .off
- `SmartCleanupCategory.samples()` 提供占位数据，所有可见文案走 i18n key —— 接真实引擎时把这个 factory 换掉即可

**CleaningStateView**（追加到 `DiskCleaner/Design/StateViews.swift`）

§4.3 ✨ 的清理过渡屏，先实现成可独立预览的组件：

- 320pt 呼吸光晕背景（3s 周期 `easeInOut.repeatForever`）
- 三层同心轨道（外 110pt 蓝 / 中 85pt 紫反向 / 内 60pt 青），每层各挂一个发光小球，速度 18s / 13s / 8s，相位错开 0° / 120° / 240°
- 中央 48pt 渐变大数字 `已释放 X.X GB / 共 Y.Y GB`（白→blueHi→cyan）
- 任务列表 3 种状态：
  - done —— 绿色对勾圆 + 100% 进度条 + 绿色数值
  - running —— 蓝色旋转圆环图标 + 流动光斑进度条 + 卡片蓝色光晕
  - queued —— 虚线序号圆 + 0% 进度条 + 卡片整体 `opacity: 0.55`
- 用 `@State pulse / orbit` 驱动呼吸 + 公转动画，符合 README §4.3 实现要点

**Feature 路由**

- `Feature` 枚举新增 `.smartCleanup` case（紧跟 `.overview` 之后）；i18n key `feature.smart_cleanup`，图标 `sparkles`
- ContentView `detailView` 路由 `.smartCleanup` → `SmartCleanupView`
- DashboardView 新增 `onRunSmartCleanup` / `onViewAllSuggestions` 两个回调，被 Health Score CTA、Smart Cleanup 段落「查看全部 →」、suggestion 卡的「查看」三处触发
- ContentView 把这两个回调都接到 `selection = .smartCleanup`
- Toolbar `toolbar.action.cleanup` 按钮（Dashboard 屏右上）也改为跳到 `.smartCleanup`

### 改动

**i18n 字符串**

- `Localizable.xcstrings` 新增 54 条 key（zh-Hans + en），覆盖 `risk.*` / `smartcleanup.*` / `feature.smart_cleanup` / `state.cleaning.*`，总条目 278 → 332
- 含 6 个分类的 title + summary、9 条样本 cache item 的 reason、6 个相对时间标签（today / yesterday / 2/3/4/8 hours/days/weeks/months ago）、FAB 中 4 个数量统计、`smartcleanup.col.*` 5 个表头

### 后续

Sprint 3 候选（按 README §10）：

- Storage Analyzer Sunburst（可先 treemap 占位）
- 把 Dashboard / SmartCleanup 的 placeholder 数据切到 `DiskCleanerCore` 的真实扫描结果（需新做类别分组器）
- 把「立即清理 X.X GB」从 stub 接到 `DeletionService` + 路由到 `CleaningStateView`（已就绪）+ 自动跳转到 `SuccessStateView`

## [0.9.0] — 2026-05-26 — DiskFlow Sprint 2: Dashboard

完整实现 DiskFlow §4.1 的 Overview / Dashboard 屏，覆盖 1.5fr/1fr 主网格 + Donut chart + Health Score + Memory mini + 3 张 Smart Cleanup 建议卡。同时把 5 个常用 atom 抽成独立组件供后续 Sprint 复用。

### 新增

**5 个可复用设计组件**（`DiskCleaner/Design/`）

- `DesignChip.swift` —— pill 状态徽章，5 个变体（default / active / good / warn / danger）+ 可选 dot 指示器；匹配 `df-chip` 的玻璃背景与边框
- `DesignDonut.swift` —— SwiftUI 实现的多段圆环图，每段 `Circle().trim().stroke()` + 微小段间隙；中央可显示渐变大标签 + 副标签
- `DesignBar.swift` —— 渐变进度条 + 软光晕，4 个变体（default 蓝→青 / good / warn / danger）；用 `animation(.easeOut(0.2))` 平滑过渡
- `DesignCard.swift` —— 统一卡片背景容器，3 个变体（default / elevated 加阴影 / glowBlue 蓝光晕，用于 Health Score 卡）；统一 `r-xl` 18pt 圆角 + line1 边框
- `DesignGlyph.swift` —— 36×36 渐变方块带白色 2–3 字缩写文字；按 `DesignGlyphKind`（apps / docs / video / photo / system / cache / folder / archive / other）拾取颜色

**DashboardView**（`DiskCleaner/Features/DashboardView.swift`）

- 问候栏：根据当前时段切换「早上好/下午好/晚上好」+ 用户长名 `NSFullUserName()`；右侧卷标 chip + 健康分 chip（带 dot + good/warn/danger 状态色）
- 主网格：1.5fr 存储分布卡（含 220pt Donut + 6 段分类色 + 软蓝光晕背景 + 分类图例 6 行）/ 1fr 右列（Health Score `glowBlue` 卡 + Memory mini `default` 卡）
- Health Score：64pt `linear-gradient(白→blueHi→cyan)` 大数字 + 「/ 100」+ 本周变化指示 + DesignBar(good) + 摘要文字 + primary CTA「运行智能清理」
- Memory mini：未启用时显示「暂未启用」chip + 灰色占位；启用后切实际数值 + 颜色状态条
- 智能清理段：标题（sparkles 图标 + `dashboard.smart.title` + `· N 项建议 · X.X GB`）+ 「查看全部 →」ghost 按钮；下方 3 列建议卡（每张 DesignGlyph + 标签 + 标题 + 大额数字 + 描述 + 查看/跳过按钮）
- `DashboardSnapshot` 值类型：把所有渲染所需字段抽成数据快照，后续 Sprint 直接换上真实引擎数据即可，View 不需要再动

**Toolbar trailing actions**

- `ContentView.toolbarTrailingActions`：仅在 Overview 屏显示「重新扫描」ghost 按钮 + 「清理 12.4 GB」primary 按钮（含 sparkles 图标）；其他屏 EmptyView
- `DiskCleanerApp.selection` 默认值从 `.storage` 改为 `.overview`，第一次打开直接落到 Dashboard

### 改动

**i18n 字符串**

- `Localizable.xcstrings` 新增 36 条 Dashboard 命名空间 key（`dashboard.greeting.*` / `dashboard.chip.*` / `dashboard.storage.*` / `dashboard.category.*` / `dashboard.donut.*` / `dashboard.health.*` / `dashboard.memory.*` / `dashboard.smart.*` / `toolbar.action.*`），每条都给 zh-Hans + en
- 总字符串条目从 242 增至 278
- 带 `%@` / `%lld` 占位符的参数化文案统一用 `String(format: NSLocalizedString(...), args)` + `Text(verbatim:)`，避免 SwiftUI `Text("key \(arg)")` 把 key 变成 `key %lld` 造成查找失败

**Feature 路由**

- `ContentView.detailView` 把 `.overview` 从 `ComingSoonView(plannedSprint: "Sprint 2")` 切到真正的 `DashboardView()`
- ContentView 的 `?? .storage` 默认 fallback 也改为 `?? .overview`，与 App 默认值保持一致

### 后续

Sprint 2.5 / Sprint 3 候选：

- 智能清理中心 Smart Cleanup 屏（README §4.1 ✨，是 Dashboard CTA 与「查看全部」按钮的跳转目标，含风险评级 + 多选 + 浮动操作栏）
- Storage Analyzer Sunburst（README Sprint 3）
- Dashboard 的数据从 placeholder 切到 `ScanSnapshot`（需先做类别分组器）

## [0.8.2] — 2026-05-26 — DiskFlow Sprint 1 收尾

补齐 Sprint 1 剩下的部分（Settings + 4 个 States）+ 接入 i18n 字符串系统，所有新文案改用语义 key。

### 新增

**4 个状态屏视图组件**（`DiskCleaner/Design/StateViews.swift`）

- `EmptyStateView` — 120pt 虚线圆 + 蓝色磁盘图标 + 「选择文件夹…」/「扫描整个 Mac」双 CTA + 安全提示
- `LoadingStateView` — 3 层同心圆（外蓝主进度 / 中青 / 内紫）+ 中央百分比 + 渐变进度条 + 3 个统计卡（已索引 / 重复组 / 可回收）
- `SuccessStateView` — 96pt 绿勾圆 + 56pt 「已释放」渐变数字 + 释放项列表（每行 ✓+名称+大小）+ 健康分变化卡（82 → 94, +12）
- `ErrorStateView` — 88pt 橙盾圆角矩形 + 文案 + 「打开系统设置」+ 已连接驱动器列表（其中 Backup-SSD 标红）

**DesignButton + DesignToggle**

- `DesignButton`（default / primary / ghost / danger × standard / small）：primary 带蓝色光晕，匹配 §6 token
- `DesignToggle`：34×20 蓝色渐变激活态，匹配设计稿的 `HiFiSettings.Toggle`

**SettingsScreen 重设计**（替代旧 5-tab `SettingsView`）

- 单页 ScrollView，最大宽 760pt 居中
- 4 段卡片：扫描 / 清理 / 通知 / 高级
- 控件类型：DesignToggle（reminder）/ Menu 风格 value cell（默认扫描位置 / 频率 / 阈值 / 语言）/ 状态徽章（FDA "已授权"）/ ghost button + chevron（管理）
- 底部 footer：版本/系统/架构 + 「检查更新」+「关于」按钮
- 排除路径与自定义规则的 CRUD 走 sheet（保留原 CRUD 逻辑），不再占满整页
- 旧 `SettingsView.swift` 已删除

**Settings 改为 Feature 项**

- `Feature` 枚举新增 `.settings`，归在侧栏 SYSTEM 段
- `DesignSidebar` 把原来 hardcode 的 `settingsRow` 改回普通 nav row（systemItems 参数回归）
- `DiskCleanerApp` 移除独立的 `Settings { SettingsView() }` Scene；`Cmd+,` 现在设 `selection = .settings`，inline 切到 SettingsScreen

### 改动

**i18n 字符串系统**

- `Localizable.xcstrings` 新增 87 条语义 key（`sidebar.*` / `toolbar.*` / `feature.*` / `state.*` / `settings.*` / `frequency.*` / `scan_root.*` / `language.*` 等），每条都同时给 zh-Hans 和 en 翻译
- 总字符串条目从 138 增至 242
- 所有新 chrome 文件改用 `Text(LocalizedStringKey(keyString))` 解析，不再硬编码英文/中文
- `Feature.title` → `Feature.titleKey`（返回 i18n key 字符串）
- `DesignNavItem.label` → `DesignNavItem.labelKey`
- `DesignToolbar.placeholder` → `placeholderKey`
- `ComingSoonView.title` → `titleKey: LocalizedStringKey`
- `CommandMenu` 全部菜单项走 i18n
- 中文系统下看到的全部是中文（之前是英文 hardcode）

### 不在本次范围

- 把已有 detail views（DiskMapView / DuplicatesView / 等）的字符串也迁到 i18n key —— 等各视图按 DiskFlow 设计重做时一并处理
- Cleaning 过渡屏（README §4.3 新增的那个）—— 留到 Sprint 2 与 Smart Cleanup 一起做
- 字体栈不需要改动：SwiftUI `Font.system()` 在 macOS 上对 CJK 自动选 PingFang SC、对拉丁选 SF Pro，开箱即用

## [0.8.0] — 2026-05-26 — DiskFlow Redesign · Sprint 1

接入 `design_handoff_diskflow` 的新视觉系统。Sprint 1 目标：Frame + Sidebar + Toolbar 三个全局组件 + 设计令牌系统。

### 新增

**设计令牌系统（`DiskCleaner/Design/`）**

- `Tokens.swift` —— 全套颜色（bg / glass / line / text / 5 个 neon accents / 7 个 category colors / 3 个 semantic）、字体阶梯、圆角、间距、阴影；含 `Color(hex:)` 初始化扩展。
- `DarkGlass` ViewModifier —— 用 SwiftUI `.regularMaterial` + 黑色 tint 还原 `rgba(11,14,20,α)` 的深色玻璃质感。
- `MeshGradientBackground` —— 三个 `RadialGradient`（蓝 / 紫 / 青）叠加在深色 linear gradient 之上，对应 §6 的环境光斑。

**全局 chrome 组件**

- `DesignFrame` —— 整体 shell，承载 sidebar + 主区，背景挂 MeshGradient；macOS 窗口本身的标题栏 + traffic lights 由系统提供。
- `DesignSidebar` —— 224pt 宽：品牌区（渐变方块 + 文字）→ `WORKSPACE` 段（导航条目，含 SF Symbol 图标和可选 badge）→ `SYSTEM` 段（Settings 入口）→ 底部存储状态卡（卷名 + Healthy 徽章 + stacked bar + Used / Free）。
- `DesignToolbar` —— 52pt 高：搜索框（含 ⌘K 键徽章）+ Refresh / Bell 图标按钮 + 可扩展尾部 actions。

**功能侧栏扩展**

- `Feature` 枚举重写，对齐 DiskFlow 设计的 7 个 workspace items（Overview / Storage / Large Files / Duplicates / Applications / Memory / External）+ DiskCleaner 原有 3 项（Junk / History / Activity）。
- 新增 `ComingSoonView`（带 SF Symbol 大图 + 标题 + 计划 Sprint）用作 Overview / Memory / External 的占位。
- `DiskCleanerApp` 的 `CommandMenu` 重命名为 "Features"，`Cmd+1..7` 对应设计的 7 个主要项，DiskCleaner 原有 3 项保留为无快捷键的菜单项。

### 改动

- `ContentView` 不再用 `NavigationSplitView`，改用 `DesignFrame { sidebar } main: { Toolbar + detail }` 的组合。
- 现有功能页（DiskMapView / DuplicatesView / UninstallView / JunkCleaningView / HistoryView / AuditLogView）原样挂在新 chrome 下，视觉重做留到对应 sprint。
- App 窗口 minWidth 由 760 调到 980（要容纳 sidebar 224pt + 主区合理宽度）；用 `.windowStyle(.titleBar)` + `.windowToolbarStyle(.unified)` 让 OS 标题栏与新 Toolbar 衔接更自然。
- 默认进入页改为 `.storage`（即原来的「磁盘空间可视化」），等 Sprint 2 做完 Overview 后改回 `.overview`。

### 不在 Sprint 1 范围

- Dashboard / Overview 实际内容（Sprint 2）
- 各功能页详情视图按设计重做（Sprint 3-7）
- Memory monitor 实时图表（Sprint 6）
- External drives 支持（更后期）
- ⌘K 命令面板（v1.x）

## [0.7.0] — 2026-05-26

实用功能扩展：用户终于能控制扫描什么、看到时间维度的变化、自定义清理规则、被提醒重新扫描。

### 新增

**排除路径**

- 设置 ▸ 扫描 tab 新增排除目录列表，用 NSOpenPanel 添加。
- DiskMapView 子项右键菜单加「加入排除列表」一键添加。
- `DiskScanner.scan(...)` 增加 `excludedPaths` 参数；扫描时直接跳过匹配的子项，子目录也不进入。
- DiskMap 与重复文件页都接入此设置。

**自定义清理规则**

- 设置 ▸ 规则 tab 提供 CRUD：增 / 改（含 sheet 编辑器）/ 删；含「浏览…」按钮选路径。
- `CustomJunkRule` 模型 + `CustomRulesStore` actor，JSON 存到 `~/Library/Application Support/DiskCleaner/custom-rules.json`。
- `JunkCategory` 新增 `.custom` 分类；垃圾清理结果里和内置规则混合显示。

**扫描历史**

- 新功能页「扫描历史」（侧边栏第 5 项，`Cmd+5`）：
  - Swift Charts 趋势线（按根路径分组）
  - 快照列表：时间 / 根路径 / 大小 / 项数
  - 刷新与清空
- `ScanSnapshot` + `ScanHistoryStore`，JSONL 存到 `scan-history.jsonl`。
- 磁盘可视化扫描完成后自动记录快照。

**定时扫描提醒**

- 设置 ▸ 提醒 tab：开关 + 频率（每天 / 每周 / 每月）。
- `ScanReminder` 使用 `NSBackgroundActivityScheduler` 周期检查，超阈值通过 `UNUserNotificationCenter` 发系统通知。
- App 启动时自动注册当前设置。

**其他**

- `Feature` 新增 `.history` 项；侧边栏现在有 6 个功能页，主菜单「功能」加上 `Cmd+5`（历史）/ `Cmd+6`（最近操作）。
- `FileNode` 新增 `totalItemCount` 计算属性。
- `Localizable.xcstrings` 加约 30 条新条目（138 总）。

### 测试

- 新增 `CustomRulesStoreTests`（4 项）：保存 / 加载 / upsert / 删除 / asJunkRule 映射。
- 新增 `ScanHistoryStoreTests`（3 项）：记录与读取 / 时序排列 / 清空。

### 已知限制

- 定时扫描提醒需要 app 处于运行状态（哪怕在后台）。完全退出后不会触发——这一限制要靠 LaunchAgent 解决，留到 v1.0 与代码签名一并处理。
- 自定义规则当前只支持单条 path；要支持多 path / 通配符增强留待后续。
- 扫描历史的 chart 在数据点很多时性能未优化（Swift Charts 默认行为应该足够）。

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
