# Handoff: DiskFlow — macOS Storage Management App

> **目标读者：使用 Claude Code 或其他 AI/人类开发者，在真实代码库中实现该设计的工程师。**

## 1. 概览 Overview

DiskFlow 是一款 macOS 桌面应用，帮助用户：可视化磁盘占用 · 找出大文件 · 清理重复文件 · 卸载应用残留 · 监控内存压力。

**目标用户：** 高级用户、开发者、创作者、对存储敏感的 Mac 用户。

**当前界面语言：简体中文（zh-CN）**，后续会扩展英文。设计文件中所有用户可见文案都已使用中文；字体栈以 `PingFang SC` 为首选，西文回落到 `SF Pro Display / Text`。

### i18n 实施建议

UI 文案应抽离为字符串表（i18n keys），不要硬编码在视图层。推荐结构：

```
locales/
├── zh-CN.json        ← 当前设计的所有文案
└── en.json           ← 之后加英文版本，键名与 zh-CN 一一对应
```

英文版本切换时只需改字体栈优先级（把 `SF Pro Display` 放到最前），无需改其他视觉规则。组件库（SwiftUI / React）按平台标准做 i18n 接入即可（SwiftUI：`String(localized:)` + `.strings` 文件；React：`react-i18next` 或 `@lingui/react`）。

**设计语言：** 深色优先 · 毛玻璃 · 柔和霓虹蓝/青/紫渐变 · 遵循 Apple Human Interface Guidelines · 像 macOS 原生应用一样自然。

---

## 2. ⚠️ 关于设计文件 About the Design Files

本交付包含的 HTML 文件是 **设计参考稿（design references）**，由 React + 内联 JSX 构建，**不是用于直接打包发布的生产代码**。

开发任务：**在目标技术栈中重新实现这些设计的视觉与交互**。

### 推荐技术栈选择

| 场景 | 推荐方案 | 理由 |
|---|---|---|
| 仅 macOS · 追求原生体验 | **SwiftUI + AppKit**（首选） | 毛玻璃效果（`.regularMaterial`）原生支持，文件系统 API 完整，Apple Silicon 优化 |
| 跨平台或团队已熟悉 web 栈 | **Tauri 2.0 + React + TypeScript** | Rust 后端处理文件扫描快，前端可较好还原玻璃质感 |
| 临时方案 / Web 演示 | **Electron + React** | 不推荐，资源消耗大且玻璃效果较差 |

**不要把 HTML 直接 wrap 成 WebView 发布**——会失去原生体验。

---

## 3. 保真度 Fidelity

本交付为 **高保真（Hi-fi）设计稿**：
- ✅ 颜色、字号、间距、圆角、阴影都是最终值，请精确还原
- ✅ 所有图标已确定（Lucide 风格 monoline，1.8 stroke）
- ✅ 渐变、玻璃模糊、霓虹高光、SF Pro Display 字体都已确定

请按设计令牌（见 §6）实现，不要重新发明配色。

---

## 4. 屏幕清单 Screens

文件 `DiskFlow Design.html` 中按章节组织：

### 4.1 Primary（主要屏幕，5 张）

#### Dashboard · Overview （`dashboard`）
- **目的**：用户开 App 第一眼看到的总览页
- **布局**（1280 × 800）：
  - 侧边栏（224px 宽，左对齐）
  - 顶部工具栏（52px 高）
  - 主区：问候 + 两列网格（左侧 1.5fr 环形图卡 + 分类图例 / 右侧 1fr 健康分卡 + 内存迷你卡）+ 底部 3 列智能建议卡
- **关键元素**：
  - **Donut chart**：220px，6 段分类色，中央显示 `312 GB / of 512 GB used`
  - **Health Score 卡**：64px 大数字，从白色渐变到 cyan，蓝色光晕（`box-shadow: 0 0 60px -10px rgba(77,158,255,0.25)`）
  - **CTA 按钮**："Run smart cleanup" 用 primary 蓝色渐变 + 蓝色光晕
  - **Smart Cleanup 卡片**：分类色彩编码的渐变方块图标 + 标题 + 大额释放空间 + Review/Skip 按钮
- **"查看全部"按钮** 跳转到 `smart-cleanup` 屏（见下）。

#### 智能清理中心 · Smart Cleanup（`smart-cleanup`）✨

- **目的**：Dashboard 上 Smart Cleanup 卡片右侧"查看全部 →"按钮的跳转目标。承载**所有** 8–12 项清理建议（不只首页那 3 项），支持分组浏览 + 细粒度多选 + 风险评级。
- **路由**：`/smart-cleanup`，侧边栏新增独立入口（位于 Overview 之后，徽章显示总可释放量 `12.4 GB`）。
- **布局**（1280 × 800）：
  - 全局侧边栏 224px
  - 左侧二级筛选栏 240px：顶部汇总（"19.6 GB · 共 6 类 · 260 项"）+ 分类列表（每类显示已选数 + 总数 + 大小）+ 底部安全保障说明卡
  - 主区：标题 + 风险筛选 chips（全部 / 仅安全 / 需复核）+ 分组列表 + 底部浮动操作栏
- **关键元素**：
  - **风险徽章**（`<Risk level />`）三档：
    - `safe` 绿色 · "安全" — 应用临时数据，可放心删除
    - `normal` 蓝色 · "一般" — 一般情况安全，重新同步会重建
    - `caution` 黄色 · "需复核" — 索引/项目数据，删除会影响下次使用速度
  - **分组卡**：展开态显示表头（风险 · 项目 · 说明 · 最近访问 · 大小）+ 多行；折叠态只显示一行（图标+标题+一句话+大小+`›`）
  - **项目行列结构**（grid-template-columns）：`32px 80px 32px 1fr 110px 110px 70px 24px` 对应 复选框 / 风险 / 图标 / 项目+路径 / 说明 / 最近访问 / 大小 / ⋯
  - **底部浮动操作栏**：「已选中 N 项 · X.X GB」+ 颜色编码的风险统计「● 7 项安全 · ● 1 项一般」+「仅勾选安全项」快捷键 +「立即清理 X.X GB」CTA
  - 点击「立即清理」→ 跳转 `cleaning` 过渡屏 → `success`

#### Storage Analyzer · Sunburst （`analyzer`）
- **目的**：层级化展示存储分布，支持钻取
- **布局**：1.4fr 旭日图 + 1fr 详情面板
- **关键元素**：
  - **Sunburst**：两环，外环显示子分类（Xcode/Logic 等），点击切片高亮 + 钻取
  - **详情面板**：面包屑路径（Apps › Xcode）+ Breakdown 列表（DerivedData / iOS Simulator / Archives / Binary / Other）+ "Clean 6.2 GB" CTA
  - **Insight 小卡**：底部 `✨ Insight: Xcode caches grew by 6.2 GB this month.`

#### Large Files · Table + Preview （`large-files`）
- **目的**：找出并处理大文件
- **布局**：左主区（表格）+ 右侧 280px 预览面板
- **关键元素**：
  - **类型筛选 chips**：All / Video / Archive / Image / Folder / Other（顶右）
  - **表格列**：复选框 · 类型图标（32×32 渐变方块带扩展名缩写）· 名称+路径（mono） · 大小 · 最后打开 · 类型 · ⋯
  - **批量操作浮动栏**：选中 3 文件 · 19.4 GB · Reveal / Archive / Trash 按钮
  - **预览面板**：视频缩略图（16:10）+ 文件元信息（Size/Type/Resolution/Duration/Created）+ Open/Archive/Trash 按钮

#### Duplicate Cleaner · Side-by-side （`duplicates`）
- **目的**：清理重复文件
- **布局**：左侧 260px 分组列表 + 右侧对比面板
- **关键元素**：
  - **分组列表**：选中项左侧蓝边 + 蓝色背景高亮
  - **对比卡片**：1 个 KEEP 卡（绿色光晕边框 + "Keep" 徽章）+ 3 个 DELETE 卡（红色色调 + "Delete" 徽章）
  - **VS 分隔符**：垂直居中文字
  - **底部浮动栏**：本组清理摘要 + Skip / Customize / Apply smart pick

### 4.2 Secondary（次要屏幕，3 张）

#### Memory Monitor （`memory`）
- 4 个统计卡（In use / Cached / Swap / CPU），每卡含 sparkline
- 完整 60s 实时图（RAM 蓝 + CPU 青，带渐变填充与发光描边）
- 进程表（Process 名 · Memory + sparkline · CPU · Energy）

#### App Uninstaller （`apps`）
- 4 列应用卡网格
- 选中卡：蓝色光晕环 + 展开显示残留数据明细（Caches/App Support/Preferences）
- 底部浮动栏：「Keep apps, clean leftovers」 vs 「Uninstall completely」

#### Settings （`settings`）
- 居中 760px 最大宽度
- 分组：Scanning / Cleanup / Notifications / Advanced
- 控件：自定义 toggle（蓝色渐变激活态）/ 下拉 / 状态徽章
- 底部版本号 + Check for updates

### 4.3 States（状态屏，5 张 · 含清理过渡动画）

| ID | 用途 | 关键视觉 |
|---|---|---|
| `empty`    | 首次启动 / 未扫描 | 120px 虚线圆 + 蓝色磁盘图标 + "Pick folders" / "Scan entire Mac" CTA |
| `loading`  | 扫描中 | 三层同心圆动画（外圈蓝渐变 68%，内圈青 + 紫片段）+ 进度条 + 实时计数器 |
| `cleaning` ✨ | **点击「运行智能清理」后到「清理完成」之间的过渡动画屏** | 中央 48px 渐变文字 "已释放 8.4 GB / 共 12.4 GB" + 三层旋转粒子轨道 + 任务列表（已完成 / 进行中 / 排队中三种状态） |
| `success`  | 清理完成 | 96px 绿色对勾圆 + 大号 "12.4 GB" 渐变文字 + 释放项列表 + 健康分变化（82 → 94） |
| `error`    | 权限不足 | 88px 橙色盾牌图标 + 解释文案 + "Open System Settings" CTA + 已连接驱动列表 |

#### Cleaning 过渡屏实现要点

**这一屏的关键是让用户感受到"事情正在发生"，避免从 Dashboard 点 CTA → 突然弹出 Success 的生硬感。**

视觉构成：
1. **背景渐变光晕**（呼吸动画，3s 周期）：`radial-gradient(circle, rgba(77,158,255,0.28), transparent 70%)` + `animation: pulse 3s ease-in-out infinite`
2. **三层同心轨道环**：圆形 1px border-radius:50% 边框，每层以不同方向 + 时长旋转（外圈 18s / 中圈 13s 反向 / 内圈 8s）。每个环上挂一个发光小球。
3. **5 个漂浮粒子**：用 `transform: rotate() translateX(var(--orbit-r)) rotate()` 实现 CSS-only 公转，半径 70–110px，色彩交替（blue / cyan / purple）
4. **中央数字**：使用与 Dashboard 健康分相同的 `linear-gradient(180deg, #fff, var(--blue-hi), var(--cyan))` + `background-clip: text`，配 tabular-nums 数字
5. **任务列表**三态：
   - **done** ✓：绿色对勾圆 + 100% 进度条 + 绿色数值 + 文字 "✓ 完成"
   - **running**：蓝色旋转圆环图标 + 流动光斑进度条（`@keyframes shimmer`）+ 卡片蓝色光晕 `box-shadow`
   - **queued**：虚线序号圆 + 0% 进度条 + 卡片整体 opacity:0.55

转场建议（开发实现）：
- 从 Dashboard 点击「运行智能清理」按钮 → 当前页面 `opacity` 渐隐 200ms → 路由切换 → Cleaning 屏从 `scale(0.96)` 渐入 300ms
- Cleaning → Success 转场：当所有任务 done 后，中央"已释放 X GB"的数字继续展示，同时圆环动画停止 + 颜色从蓝色渐变到绿色（800ms），再切换到 Success 页
- macOS 平台用 `withAnimation(.easeOut(duration: 0.3))` 或 `matchedGeometryEffect`

---

## 5. 交互行为 Interactions

### 全局
- `⌘K` 唤起命令面板（v1.0 后可加）
- `⌘R` 触发 Rescan
- `⌘,` 打开 Settings
- 拖拽文件/文件夹到主窗口 → 单点扫描

### 选择与多选
- 单击行/卡选中
- `⌘+点击` 多选 / `Shift+点击` 范围选
- 选中后自动浮出底部 action bar（带 backdrop-blur）

### 删除流程
- 默认走 Trash（"Safe-delete" 默认开）
- 删除 >1 GB 弹原生 alert 二次确认
- 成功后跳转 Success state

### 状态变迁
- `idle → scanning → done`（scanning 时显示 loading state，done 后跳回原页面）
- `error` 永远可重试

### 动画
- 卡片 hover：`background 120ms`
- 按钮 hover：`background 120ms`，`active`: `translateY(0.5px) 80ms`
- 进度条：实际进度变化用 `transition: width 200ms ease-out`
- Loading 同心圆：每环以不同速度旋转（外圈 2s · 中圈 3s · 内圈 4s），CSS 关键帧

---

## 6. 设计令牌 Design Tokens

完整定义见 `hifi.css` 顶部 `:root`。简表如下：

### 颜色 Colors

```
/* Backgrounds */
--bg-0: #07090d   /* deepest underlay */
--bg-1: #0d1117   /* app body */
--bg-2: #11161f   /* sidebar */
--bg-3: #161c27   /* cards */

/* Glass surfaces (rgba on dark) */
--glass-1: rgba(255,255,255,0.03)
--glass-2: rgba(255,255,255,0.05)
--glass-3: rgba(255,255,255,0.08)
--glass-hi: rgba(255,255,255,0.12)

/* Borders */
--line-1: rgba(255,255,255,0.06)
--line-2: rgba(255,255,255,0.10)
--line-3: rgba(255,255,255,0.16)

/* Text */
--t-1: #f0f3f8  /* primary */
--t-2: #b6bfcf  /* secondary */
--t-3: #7a8497  /* tertiary */
--t-4: #4d566a  /* faint / labels */

/* Accents */
--blue:    #4d9eff
--blue-hi: #6fb3ff
--cyan:    #5dd5e8
--purple:  #9b8bff
--pink:    #d287ff

/* Category colors */
--cat-apps:   #4d9eff
--cat-docs:   #9b8bff
--cat-video:  #d287ff
--cat-photo:  #ff8eb1
--cat-system: #5dd5e8
--cat-cache:  #ffb55c
--cat-other:  #6e7991

/* Semantic */
--good:   #5fd49a
--warn:   #ffb45c
--danger: #ff6b7d
```

### 字体 Typography

```
/* 中文优先（当前主语言），英文回落到 SF Pro */
font-family: -apple-system, "SF Pro Display", "SF Pro Text", BlinkMacSystemFont,
             "PingFang SC", "Helvetica Neue", "Microsoft YaHei", system-ui, sans-serif;
font-mono:   "SF Mono", ui-monospace, "JetBrains Mono", Menlo, "PingFang SC", monospace;

/* Scale */
h1: 24px / 700 / -0.02em
h2: 15px / 600 / -0.01em
h3: 13px / 600
body: 12.5–13px / 400–500
label (uppercase): 10.5px / 600 / 0.08em letter-spacing
mono: tabular-nums

/* Hero numbers (e.g. health score) */
display: 56–64px / 700 / -0.04em
gradient text: linear-gradient(180deg, #fff, var(--blue-hi) 60%, var(--cyan))
```

> ⚠️ 中文不需要 `letter-spacing`（容易显得松散）。设计中只在英文/数字/大字号场景使用负字距。
> 当切到英文界面时，把 `SF Pro Display` 提到字体栈最前即可。

### 间距 Spacing（8pt 网格）

```
内边距 cards: 16–22px
gap (grids): 12–16px
toolbar 高度: 52px
titlebar 高度: 38px
sidebar 宽度: 224px
preview pane 宽度: 280px
floating action bar 高度: ~56px
```

### 圆角 Radii

```
--r-xs: 4px        小标签
--r-sm: 6px        小按钮
--r-md: 10px       常规按钮 / search box
--r-lg: 14px       小卡片
--r-xl: 18px       常规卡片
--r-2xl: 22px      command palette
--r-pill: 999px    chips
```

### 阴影 Shadows

```
--shadow-sm: 0 1px 2px rgba(0,0,0,0.4)
--shadow-md: 0 4px 16px rgba(0,0,0,0.32), 0 1px 2px rgba(0,0,0,0.4)
--shadow-lg: 0 12px 40px rgba(0,0,0,0.5), 0 2px 6px rgba(0,0,0,0.3)
--shadow-glow-blue: 0 0 24px rgba(77,158,255,0.35)
--shadow-glow-cyan: 0 0 24px rgba(93,213,232,0.30)

/* Primary button glow */
box-shadow: 0 4px 14px rgba(77,158,255,0.35), inset 0 1px 0 rgba(255,255,255,0.2)
```

### 毛玻璃 Glass

```
backdrop-filter: blur(20px) saturate(160%);
background: rgba(11,14,20,0.4);   /* toolbar */
background: rgba(11,14,20,0.6);   /* sidebar */
background: rgba(22,28,39,0.85);  /* floating action bar */
```

**SwiftUI 等价：** 用 `.background(.regularMaterial)` 或 `.background(.ultraThinMaterial)`。

### 环境光斑（Mesh gradient）

应用主背景使用多层 radial gradient 营造氛围光：
```
background-image:
  radial-gradient(900px 600px at 12% -10%, rgba(77,158,255,0.16), transparent 60%),
  radial-gradient(700px 500px at 110% 10%, rgba(155,139,255,0.14), transparent 55%),
  radial-gradient(800px 600px at 50% 120%, rgba(93,213,232,0.08), transparent 60%),
  linear-gradient(180deg, #0e131c 0%, #0a0d14 100%);
```

---

## 7. 组件清单 Components

实现时请抽出以下可复用组件：

| 组件 | 说明 | 已出现于 |
|---|---|---|
| `Frame` | mac 窗口外壳（含 traffic lights + title） | 所有页面 |
| `Sidebar` | 左导航 + 底部存储状态卡 | 所有主页面 |
| `Toolbar` | 顶部搜索 + 操作按钮 | 所有主页面 |
| `Button` | 含 4 变体: default / primary / ghost / danger，2 尺寸 | 所有页面 |
| `IconButton` | 32×32 方形 | Toolbar |
| `Chip` | 含 4 变体: default / active / good / warn / danger | 所有页面 |
| `Checkbox` | 自定义渐变激活态 | Tables |
| `Toggle` | 蓝色渐变 + 阴影 | Settings |
| `Donut` | SVG 圆环图，支持多段 | Dashboard |
| `Sunburst` | 多层环形钻取图 | Analyzer |
| `Bar` | 渐变进度条带光晕 | 多处 |
| `Sparkline` | 24px 高小折线 | Memory |
| `Card` | 含 `elevated` / `glow-blue` 变体 | 所有页面 |
| `FloatingActionBar` | 底部贴底毛玻璃栏 | Tables / Apps |
| `Glyph` | 32×32 渐变方块带扩展名缩写 | Large Files |

### 图标库 Icons

使用 [Lucide Icons](https://lucide.dev/)，stroke-width 1.8，size 18px。设计稿中用到：
`grid · disk · doc · copy · apps · cpu · drive · settings · search · zap (bolt) · sparkles · arrow-right · check · trash · archive · folder-open · refresh-cw · more-horizontal · bell · chevron-right · folder · play · pause · alert-triangle · shield · filter`

---

## 8. 数据来源 Data Sources（macOS 实现）

| 需求 | API |
|---|---|
| 磁盘容量 | `URLResourceKey.volumeAvailableCapacityKey` |
| 文件枚举 | `FileManager.enumerator(at:)` + `URLResourceKey.fileSizeKey` |
| 重复检测 | 图像：感知哈希（pHash / dHash）；文件：流式 SHA-256 + 大小预过滤 |
| 内存/CPU | `host_statistics64` + `proc_listpids` + `proc_pidinfo` |
| 应用列表 | 扫描 `/Applications` 与 `~/Applications` |
| 残留数据 | 扫描 `~/Library/Caches/<bundle>`, `~/Library/Application Support/<bundle>`, `~/Library/Preferences/<bundle>.plist` |
| 安全删除 | `NSWorkspace.recycle(_:completionHandler:)` |
| 权限 | Full Disk Access（用户在 System Settings 中手动授权） |

---

## 9. 状态管理 State Management

核心状态（无论用 Redux/Zustand/SwiftUI `@Observable`，结构类似）：

```ts
interface AppState {
  scan: {
    status: 'idle' | 'scanning' | 'done' | 'error';
    progress: { filesIndexed: number; currentPath: string; pct: number };
    lastScanAt: Date | null;
  };
  storage: {
    totalBytes: number;
    usedBytes: number;
    categories: Record<Category, { bytes: number; subItems: FolderEntry[] }>;
    healthScore: number; // 0–100
  };
  largeFiles: FileEntry[];
  duplicateGroups: DuplicateGroup[];
  apps: AppEntry[];
  memory: { ramUsed; ramCached; swap; cpu; processes: ProcessEntry[] };
  drives: DriveEntry[];
  selection: Set<string>;  // 跨视图持久化的选中集合
  settings: SettingsValues;
}
```

---

## 10. 实现顺序建议

| Sprint | 目标 |
|---|---|
| 1 | Frame + Sidebar + Toolbar + Settings + Empty/Loading/Success/Error states |
| 2 | Dashboard 完整布局（含 Donut chart 与 Health Score） |
| 3 | Storage Analyzer（Sunburst 较复杂，可先用 treemap 替代再迭代） |
| 4 | Large Files 表格 + 预览面板 + 批量删除流 |
| 5 | Duplicates（含 pHash 实现） |
| 6 | Memory monitor 实时图表 |
| 7 | App Uninstaller（含残留数据探测） |
| 8 | Menu bar widget（v1.1） |
| 9 | 动画细节 + ⌘K 命令面板（v1.2） |

---

## 11. 文件清单 Files

| 文件 | 用途 |
|---|---|
| `DiskFlow Design.html` | 主入口 —— 用 design canvas 把 11 张稿铺开 |
| `hifi.css` | 完整设计令牌 + 组件 CSS（可作 reference） |
| `hifi-shared.jsx` | `Frame` / `Sidebar` / `Toolbar` / `Donut` / `Bar` / `Chip` / `Check` / `Sparkline` + 所有图标 |
| `hifi-dashboard.jsx` | Dashboard 屏 |
| `hifi-screens-1.jsx` | Analyzer / Large Files / Duplicates |
| `hifi-screens-2.jsx` | Memory / Apps / Settings / 4 个 States |
| `design-canvas.jsx` | 设计稿画布壳，**仅用于展示**，开发时无需移植 |

---

## 12. 给 Claude Code 的建议提示词

在你的代码库根目录运行 Claude Code，输入：

```
请阅读 design_handoff_diskflow/README.md，理解 DiskFlow 这款 macOS 存储管理应用的整体设计。

我们使用 [SwiftUI / Tauri+React / 你的实际栈] 实现。

请先从 Sprint 1 开始，搭建 Frame + Sidebar + Toolbar 这三个全局组件，
精确还原 §6 设计令牌中的颜色、字体、间距、玻璃材质效果。

完成后我们再实现 Dashboard 屏。
```

完成第一阶段后，继续：

```
请基于已建好的全局组件，实现 Dashboard 屏 (§4.1)。注意：
- Donut chart 用 SVG 实现，6 段分类色 + 中央数字
- Health Score 用大号渐变文字（详见 §6 Typography）
- Smart Cleanup 卡片用 Lucide 图标 + 分类渐变方块
```

---

**完整设计稿请打开 `DiskFlow Design.html` 查看。点击任一线框右上的展开图标可全屏聚焦。**
