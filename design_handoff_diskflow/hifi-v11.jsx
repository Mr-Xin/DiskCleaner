/* Hi-fi v1.1 — 命令面板 · 保存搜索 · 键盘快捷键 · 自定义扫描规则 */

// ============ ⌘K 命令面板 ============

function HiFiCommandPalette() {
  const groups = [
    { label: '推荐操作', items: [
      { i: Icon.bolt,    t: '运行智能清理',       sub: '基于上次扫描结果 · 可释放 12.4 GB', k: '↵', sel: true, glow: true },
      { i: Icon.sparkle, t: '查找重复照片',       sub: '在 ~/Pictures · 上次发现 128 张',   k: '⌘D' },
    ]},
    { label: '导航 · 跳转', items: [
      { i: Icon.grid,    t: '总览',               sub: 'Dashboard',     k: '⌘1' },
      { i: Icon.disk,    t: '存储分析',           sub: 'Storage',       k: '⌘2' },
      { i: Icon.doc,     t: '大文件',             sub: 'Large Files',   k: '⌘3' },
      { i: Icon.copy,    t: '重复文件',           sub: 'Duplicates',    k: '⌘4' },
      { i: Icon.cpu,     t: '内存监控',           sub: 'Memory',        k: '⌘5' },
    ]},
    { label: '动作', items: [
      { i: Icon.refresh, t: '重新扫描整个 Mac',   sub: '约 2 分钟',                      k: '⌘R' },
      { i: Icon.archive, t: '导出本次清理报告',   sub: 'PDF · 包含释放明细',             k: '' },
      { i: Icon.settings,t: '打开设置',           sub: 'Settings',                       k: '⌘,' },
    ]},
    { label: '最近搜索', items: [
      { i: Icon.search,  t: 'size:>1GB opened:<30d',   sub: '2 天前 · 命中 8 个文件',     k: '' },
      { i: Icon.search,  t: '~/Downloads 中的 .iso',   sub: '上周 · 命中 4 个文件',       k: '' },
    ]},
  ];

  return (
    <Frame title="DiskFlow" sidebarActive="overview">
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost sm" disabled>重新扫描</button>
            <button className="df-btn primary" disabled>{Icon.sparkle}清理 12.4 GB</button>
          </>
        }
      />
      {/* 背景虚化的 Dashboard 暗示 */}
      <div className="df-main" style={{ filter: 'blur(3px) saturate(0.7)', opacity: 0.35, pointerEvents: 'none' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
          <h1 className="df-h1">早上好，Alex</h1>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: 16, flex: 1 }}>
          <div className="df-card elevated" style={{ height: 320 }}></div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            <div className="df-card glow-blue" style={{ height: 180 }}></div>
            <div className="df-card" style={{ flex: 1 }}></div>
          </div>
        </div>
      </div>

      {/* 命令面板浮层 */}
      <div className="df-modal-backdrop" style={{ alignItems: 'flex-start', paddingTop: 80 }}>
        <div style={{
          width: 620, background: 'rgba(20,24,34,0.85)',
          border: '1px solid var(--line-3)', borderRadius: 'var(--r-2xl)',
          boxShadow: '0 40px 100px rgba(0,0,0,0.7), 0 0 80px rgba(77,158,255,0.18)',
          backdropFilter: 'blur(60px) saturate(180%)',
          WebkitBackdropFilter: 'blur(60px) saturate(180%)',
          overflow: 'hidden',
          display: 'flex', flexDirection: 'column',
        }}>
          {/* 输入栏 */}
          <div style={{ padding: '18px 22px', display: 'flex', alignItems: 'center', gap: 12,
                        borderBottom: '1px solid var(--line-1)' }}>
            <span style={{ color: 'var(--blue-hi)', transform: 'scale(1.1)' }}>{Icon.search}</span>
            <div style={{ flex: 1, display: 'flex', alignItems: 'baseline', gap: 6 }}>
              <span style={{ fontSize: 19, color: 'var(--t-1)', fontWeight: 500 }}>清理</span>
              <span style={{ width: 2, height: 22, background: 'var(--blue)', display: 'inline-block', verticalAlign: 'middle',
                             animation: 'df-blink 1s infinite' }}></span>
              <span style={{ marginLeft: 'auto', fontSize: 11, color: 'var(--t-3)' }}>共 14 个结果</span>
            </div>
            <span style={{ fontSize: 10, color: 'var(--t-3)', padding: '3px 8px', background: 'var(--glass-2)',
                           border: '1px solid var(--line-1)', borderRadius: 5, fontFamily: 'var(--font-mono)' }}>ESC 关闭</span>
          </div>

          {/* 结果列表 */}
          <div style={{ maxHeight: 460, overflow: 'hidden' }}>
            {groups.map((g, gi) => (
              <div key={gi}>
                <div style={{ padding: '8px 22px 4px', fontSize: 10, fontWeight: 600,
                              textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t-4)' }}>{g.label}</div>
                {g.items.map((it, i) => (
                  <div key={i} style={{
                    padding: '10px 22px',
                    background: it.sel ? 'linear-gradient(90deg, rgba(77,158,255,0.18), rgba(77,158,255,0.06))' : 'transparent',
                    borderLeft: '3px solid ' + (it.sel ? 'var(--blue)' : 'transparent'),
                    boxShadow: it.glow ? '0 0 24px -10px rgba(77,158,255,0.4) inset' : undefined,
                    display: 'flex', alignItems: 'center', gap: 12,
                  }}>
                    <span style={{ color: it.sel ? 'var(--blue-hi)' : 'var(--t-3)' }}>{it.i}</span>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, color: 'var(--t-1)', fontWeight: it.sel ? 600 : 500 }}>{it.t}</div>
                      <div style={{ fontSize: 11, color: 'var(--t-3)', marginTop: 1 }}>{it.sub}</div>
                    </div>
                    {it.k && (
                      <span style={{ fontFamily: 'var(--font-mono)', fontSize: 10.5, padding: '2px 7px',
                                     background: it.sel ? 'rgba(77,158,255,0.25)' : 'var(--glass-2)',
                                     border: '1px solid ' + (it.sel ? 'rgba(77,158,255,0.4)' : 'var(--line-1)'),
                                     borderRadius: 5, color: it.sel ? 'var(--blue-hi)' : 'var(--t-3)' }}>{it.k}</span>
                    )}
                  </div>
                ))}
              </div>
            ))}
          </div>

          {/* 底部提示栏 */}
          <div style={{ padding: '10px 22px', borderTop: '1px solid var(--line-1)',
                        background: 'rgba(7,9,13,0.4)', display: 'flex', justifyContent: 'space-between',
                        fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--t-3)' }}>
            <span>↑↓ 导航 · Tab 进入子菜单</span>
            <span>↵ 执行 · ⌘K 关闭</span>
          </div>
        </div>
      </div>
    </Frame>
  );
}

// ============ 保存搜索（大文件页变体）============

function HiFiSavedSearches() {
  const saved = [
    { n: '本月新增大文件',     q: 'size:>500MB created:<30d',         hits: 18, color: 'var(--blue)',  active: true },
    { n: '下载里超 1GB',       q: 'in:~/Downloads size:>1GB',         hits: 8,  color: 'var(--cat-other)' },
    { n: '从未打开的视频',     q: 'type:video opened:never',          hits: 12, color: 'var(--cat-video)' },
    { n: 'Final Cut 渲染缓存', q: 'in:~/Movies/FCP type:cache',       hits: 6,  color: 'var(--cat-cache)' },
    { n: 'Xcode 旧 archives',  q: 'in:~/Library/Developer/Xcode',     hits: 14, color: 'var(--cat-apps)' },
  ];

  return (
    <Frame title="大文件 · 保存的搜索" sidebarActive="large">
      <Toolbar
        search="size:>500MB created:<30d"
        actions={
          <>
            <button className="df-btn ghost sm">{Icon.bolt}保存为…</button>
            <button className="df-btn primary">{Icon.archive}归档</button>
          </>
        }
      />
      <div className="df-main" style={{ flexDirection: 'row', padding: 0, gap: 0 }}>

        {/* 左：保存的搜索列表 */}
        <div style={{ width: 240, padding: '20px 14px', display: 'flex', flexDirection: 'column', gap: 8,
                      borderRight: '1px solid var(--line-1)', background: 'rgba(7,9,13,0.4)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingLeft: 4 }}>
            <span className="df-label">保存的搜索</span>
            <button className="df-icon-btn" style={{ width: 22, height: 22, fontSize: 14 }} title="新建搜索">+</button>
          </div>

          {saved.map((s, i) => (
            <div key={i} style={{
              padding: '10px 12px', borderRadius: 'var(--r-md)',
              background: s.active ? 'rgba(77,158,255,0.10)' : 'transparent',
              border: '1px solid ' + (s.active ? 'rgba(77,158,255,0.25)' : 'transparent'),
              display: 'flex', flexDirection: 'column', gap: 4,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ width: 8, height: 8, borderRadius: 2, background: s.color, boxShadow: `0 0 8px ${s.color}80` }}></span>
                <span style={{ flex: 1, fontSize: 12.5, fontWeight: s.active ? 600 : 500, color: s.active ? 'var(--t-1)' : 'var(--t-2)' }}>{s.n}</span>
                <span style={{ fontSize: 10, color: 'var(--t-4)' }}>{s.hits}</span>
              </div>
              <div className="df-mono" style={{ fontSize: 10, color: 'var(--t-3)', paddingLeft: 16, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{s.q}</div>
            </div>
          ))}

          <div style={{ marginTop: 8 }}>
            <div className="df-label" style={{ paddingLeft: 4 }}>最近搜索</div>
            {[
              { q: '~/Pictures duplicates' },
              { q: 'screenshots*.png' },
              { q: 'Logic Pro samples' },
            ].map((r, i) => (
              <div key={i} style={{ padding: '6px 12px', fontSize: 11.5, color: 'var(--t-3)',
                                    display: 'flex', alignItems: 'center', gap: 6 }}>
                <span style={{ opacity: 0.5 }}>{Icon.search}</span>
                <span className="df-mono" style={{ overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{r.q}</span>
              </div>
            ))}
          </div>
        </div>

        {/* 主区：当前搜索结果 */}
        <div style={{ flex: 1, padding: 22, display: 'flex', flexDirection: 'column', gap: 14, minWidth: 0 }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
              <span style={{ width: 10, height: 10, borderRadius: 3, background: 'var(--blue)', boxShadow: '0 0 10px var(--blue)' }}></span>
              <h1 className="df-h1">本月新增大文件</h1>
              <Chip>{Icon.shield}已固定</Chip>
              <span style={{ flex: 1 }}></span>
              <span className="df-label">18 项 · 38.2 GB</span>
            </div>
            <div className="df-mono" style={{ fontSize: 11, color: 'var(--t-3)' }}>
              <span style={{ color: 'var(--blue-hi)' }}>size:</span>&gt;500MB ·
              <span style={{ color: 'var(--blue-hi)' }}> created:</span>&lt;30d
            </div>
          </div>

          {/* 表格 */}
          <div className="df-card elevated" style={{ padding: 0, flex: 1, overflow: 'hidden' }}>
            <div className="df-row head" style={{ gridTemplateColumns: '32px 44px 1fr 110px 130px 100px 32px' }}>
              <span></span><span></span><span>名称 · 路径</span><span>大小</span><span>创建于</span><span>类型</span><span></span>
            </div>
            {[
              { n: 'WWDC25-recordings/',          p: '~/Movies',   s: '14.2 GB', a: '12 天前', t: 'folder', g: 'DIR', sel: true },
              { n: 'project-archive.zip',         p: '~/Documents/Backups', s: '6.8 GB',  a: '8 天前',  t: 'archive', g: 'ZIP' },
              { n: 'sample-library-update.dmg',   p: '~/Downloads', s: '4.2 GB', a: '20 天前', t: 'image', g: 'DMG', sel: true },
              { n: 'photoshoot-raws-march.zip',   p: '~/Pictures', s: '3.8 GB',  a: '14 天前', t: 'archive', g: 'ZIP' },
              { n: 'training-data.parquet',       p: '~/Code/ml',  s: '2.6 GB',  a: '5 天前',  t: 'data', g: 'PRQ' },
              { n: 'final-export.mov',            p: '~/Movies',   s: '2.4 GB',  a: '3 天前',  t: 'video', g: 'MOV' },
            ].map((r, i) => (
              <div key={i} className={'df-row ' + (r.sel ? 'selected' : '')}
                   style={{ gridTemplateColumns: '32px 44px 1fr 110px 130px 100px 32px' }}>
                <Check on={r.sel} />
                <div className={'df-glyph ' + r.t}>{r.g}</div>
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontSize: 12.5, color: 'var(--t-1)', fontWeight: 500, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.n}</div>
                  <div className="df-mono" style={{ fontSize: 10.5, color: 'var(--t-3)' }}>{r.p}</div>
                </div>
                <span className="df-mono" style={{ fontSize: 13, color: 'var(--t-1)', fontWeight: 500 }}>{r.s}</span>
                <span style={{ fontSize: 12, color: 'var(--t-3)' }}>{r.a}</span>
                <span><Chip>{r.t}</Chip></span>
                <span style={{ color: 'var(--t-3)' }}>{Icon.more}</span>
              </div>
            ))}
          </div>

          <div className="df-faction">
            <Check on />
            <span style={{ fontSize: 13, fontWeight: 500 }}>已选中 2 项</span>
            <span className="df-mono" style={{ fontSize: 18, fontWeight: 700, color: 'var(--blue-hi)' }}>· 18.4 GB</span>
            <div style={{ flex: 1 }}></div>
            <button className="df-btn ghost sm">{Icon.bell}订阅命中通知</button>
            <button className="df-btn sm">{Icon.archive}归档</button>
            <button className="df-btn danger sm">{Icon.trash}废纸篓</button>
          </div>
        </div>
      </div>
    </Frame>
  );
}

// ============ 键盘快捷键速查 ============

function HiFiShortcuts() {
  const sections = [
    { t: '导航', rows: [
      ['⌘1', '总览'],
      ['⌘2', '存储分析'],
      ['⌘3', '大文件'],
      ['⌘4', '重复文件'],
      ['⌘5', '内存监控'],
      ['⌘,', '打开设置'],
    ]},
    { t: '动作', rows: [
      ['⌘K', '打开命令面板'],
      ['⌘R', '重新扫描'],
      ['⌘F', '页内搜索'],
      ['⌘S', '保存当前搜索'],
      ['⌘B', '运行智能清理'],
      ['⌘E', '导出本次报告'],
    ]},
    { t: '选择', rows: [
      ['⌘A',          '全选'],
      ['⇧⌘A',         '取消全选'],
      ['Space',       'Quick Look 预览'],
      ['↑ ↓',         '上下移动选区'],
      ['⇧↑ / ⇧↓',     '扩展选区'],
      ['⌘点击',       '多选'],
    ]},
    { t: '清理', rows: [
      ['⌘⌫',          '移到废纸篓'],
      ['⌥⌘⌫',         '永久删除（带确认）'],
      ['⌘D',          '查找重复'],
      ['⌘L',          '在 Finder 中显示'],
      ['⌘Z',          '撤销上次清理'],
      ['?',           '显示此速查表'],
    ]},
  ];

  return (
    <Frame title="DiskFlow" sidebarActive="overview">
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost sm" disabled>重新扫描</button>
            <button className="df-btn primary" disabled>{Icon.sparkle}清理</button>
          </>
        }
      />
      <div className="df-main" style={{ filter: 'blur(3px) saturate(0.7)', opacity: 0.35, pointerEvents: 'none' }}>
        <div className="df-card" style={{ height: '100%' }}></div>
      </div>

      <div className="df-modal-backdrop">
        <div className="df-modal" style={{ width: 720, padding: 0 }}>
          <div style={{ padding: '18px 24px', borderBottom: '1px solid var(--line-1)', display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ color: 'var(--blue-hi)' }}>{Icon.bolt}</span>
            <div style={{ flex: 1 }}>
              <h2 style={{ fontSize: 16, fontWeight: 600, margin: 0 }}>键盘快捷键</h2>
              <p className="df-p" style={{ fontSize: 11.5, marginTop: 2 }}>按 <span className="df-mono">?</span> 随时唤起此速查表</p>
            </div>
            <button className="df-icon-btn">✕</button>
          </div>

          <div style={{ padding: 22, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 22 }}>
            {sections.map((s, i) => (
              <div key={i}>
                <h3 className="df-h3" style={{ marginBottom: 8, color: 'var(--blue-hi)' }}>{s.t}</h3>
                {s.rows.map((r, j) => (
                  <div key={j} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '6px 0',
                                        borderBottom: j < s.rows.length - 1 ? '1px solid var(--line-1)' : 0 }}>
                    <span className="df-mono" style={{
                      fontSize: 11.5, padding: '2px 8px', background: 'var(--glass-2)',
                      border: '1px solid var(--line-2)', borderRadius: 5,
                      color: 'var(--t-1)', minWidth: 70, textAlign: 'center', fontWeight: 600,
                    }}>{r[0]}</span>
                    <span style={{ flex: 1, fontSize: 12.5, color: 'var(--t-2)' }}>{r[1]}</span>
                  </div>
                ))}
              </div>
            ))}
          </div>

          <div style={{ padding: '12px 24px', borderTop: '1px solid var(--line-1)', display: 'flex',
                        justifyContent: 'space-between', alignItems: 'center', background: 'rgba(7,9,13,0.3)' }}>
            <span style={{ fontSize: 11, color: 'var(--t-3)' }}>在设置中可自定义部分快捷键</span>
            <button className="df-btn ghost sm">前往设置 →</button>
          </div>
        </div>
      </div>
    </Frame>
  );
}

// ============ 自定义扫描规则 ============

function HiFiScanRules() {
  return (
    <Frame title="设置 · 扫描规则" sidebarActive="settings">
      <div className="df-main" style={{ maxWidth: 820, alignSelf: 'center', width: '100%' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: 'var(--t-3)', marginBottom: 4 }}>
          <span>设置</span>
          <span>›</span>
          <span style={{ color: 'var(--t-2)' }}>扫描</span>
          <span>›</span>
          <span style={{ color: 'var(--blue-hi)' }}>自定义规则</span>
        </div>
        <h1 className="df-h1">扫描规则</h1>
        <p className="df-p" style={{ marginTop: 4 }}>定义 DiskFlow 该扫描什么、跳过什么。规则按顺序匹配，第一个命中的规则生效。</p>

        {/* 包含的根目录 */}
        <div style={{ marginTop: 8 }}>
          <h2 className="df-h2" style={{ marginBottom: 6 }}>扫描的根目录</h2>
          <div className="df-card elevated" style={{ padding: 0, overflow: 'hidden' }}>
            {[
              { p: '~/',                  s: '290 GB', en: true, primary: true },
              { p: '~/Downloads',         s: '32 GB',  en: true },
              { p: '/Applications',       s: '68 GB',  en: true },
              { p: '/Volumes/Backup-SSD', s: '740 GB', en: true, ext: true },
              { p: '/Library/Caches',     s: '12 GB',  en: false },
            ].map((r, i) => (
              <div key={i} style={{ padding: '12px 18px', borderBottom: i < 4 ? '1px solid var(--line-1)' : 0,
                                    display: 'flex', alignItems: 'center', gap: 12 }}>
                <span style={{ color: r.ext ? 'var(--purple)' : 'var(--blue-hi)' }}>{Icon.folder}</span>
                <div style={{ flex: 1 }}>
                  <div className="df-mono" style={{ fontSize: 12.5, color: 'var(--t-1)' }}>{r.p}</div>
                  <div style={{ fontSize: 11, color: 'var(--t-3)', marginTop: 2 }}>
                    {r.primary && '主目录 · '}
                    {r.ext && '外接磁盘 · '}
                    最近扫描包含 {r.s}
                  </div>
                </div>
                <div style={{
                  width: 34, height: 20, borderRadius: 10, position: 'relative',
                  background: r.en ? 'linear-gradient(180deg, var(--blue), #3a87f0)' : 'var(--glass-3)',
                  border: '1px solid ' + (r.en ? 'rgba(77,158,255,0.6)' : 'var(--line-2)'),
                  boxShadow: r.en ? '0 2px 8px rgba(77,158,255,0.4)' : 'none',
                }}>
                  <div style={{ position: 'absolute', top: 1, left: r.en ? 16 : 1, width: 16, height: 16,
                                borderRadius: 8, background: '#fff' }}></div>
                </div>
                <button className="df-icon-btn">{Icon.more}</button>
              </div>
            ))}
          </div>
          <button className="df-btn ghost sm" style={{ marginTop: 8 }}>+ 添加目录</button>
        </div>

        {/* 排除规则 */}
        <div>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 6 }}>
            <h2 className="df-h2">排除规则</h2>
            <span className="df-label">按 glob 模式 / 路径前缀 / 文件类型</span>
          </div>
          <div className="df-card elevated" style={{ padding: 0, overflow: 'hidden' }}>
            {[
              { kind: 'glob',     v: '**/node_modules/**',           reason: '前端项目依赖 · 由 npm 管理',  en: true },
              { kind: 'glob',     v: '**/.git/**',                   reason: 'Git 仓库元数据',              en: true },
              { kind: 'path',     v: '/Volumes/Time Machine',        reason: 'Time Machine 卷已单独处理',   en: true },
              { kind: 'type',     v: 'application/x-bittorrent',     reason: '种子文件',                    en: false },
              { kind: 'glob',     v: '*.psd',                        reason: '保留所有 Photoshop 文档',     en: true, user: true },
            ].map((r, i) => (
              <div key={i} style={{ padding: '12px 18px', borderBottom: i < 4 ? '1px solid var(--line-1)' : 0,
                                    display: 'flex', alignItems: 'center', gap: 12 }}>
                <span style={{ fontSize: 10, padding: '2px 7px', borderRadius: 4, fontFamily: 'var(--font-mono)',
                               background: r.kind === 'glob' ? 'rgba(77,158,255,0.15)' : r.kind === 'path' ? 'rgba(155,139,255,0.15)' : 'rgba(93,213,232,0.15)',
                               border: '1px solid ' + (r.kind === 'glob' ? 'rgba(77,158,255,0.3)' : r.kind === 'path' ? 'rgba(155,139,255,0.3)' : 'rgba(93,213,232,0.3)'),
                               color: r.kind === 'glob' ? 'var(--blue-hi)' : r.kind === 'path' ? 'var(--purple)' : 'var(--cyan)',
                               fontWeight: 600, minWidth: 48, textAlign: 'center' }}>{r.kind}</span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span className="df-mono" style={{ fontSize: 12.5, color: 'var(--t-1)' }}>{r.v}</span>
                    {r.user && <span style={{ fontSize: 9, padding: '1px 5px', borderRadius: 3,
                                                background: 'var(--glass-3)', color: 'var(--t-3)', fontWeight: 600 }}>自定义</span>}
                  </div>
                  <div style={{ fontSize: 11, color: 'var(--t-3)', marginTop: 2 }}>{r.reason}</div>
                </div>
                <div style={{
                  width: 34, height: 20, borderRadius: 10, position: 'relative',
                  background: r.en ? 'linear-gradient(180deg, var(--blue), #3a87f0)' : 'var(--glass-3)',
                  border: '1px solid ' + (r.en ? 'rgba(77,158,255,0.6)' : 'var(--line-2)'),
                }}>
                  <div style={{ position: 'absolute', top: 1, left: r.en ? 16 : 1, width: 16, height: 16,
                                borderRadius: 8, background: '#fff' }}></div>
                </div>
              </div>
            ))}
          </div>
          <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
            <button className="df-btn ghost sm">+ 添加规则</button>
            <button className="df-btn ghost sm">从 .gitignore 导入</button>
            <div style={{ flex: 1 }}></div>
            <button className="df-btn ghost sm">恢复默认</button>
          </div>
        </div>

        {/* 高级选项 */}
        <div>
          <h2 className="df-h2" style={{ marginBottom: 6 }}>高级</h2>
          <div className="df-card elevated" style={{ padding: 0, overflow: 'hidden' }}>
            {[
              { l: '深度（最大目录层级）',   v: '64' },
              { l: '并发扫描线程',           v: '8 · 自动' },
              { l: '哈希算法',               v: 'SHA-256 · pHash' },
              { l: '跳过符号链接',           v: '开' },
            ].map((r, i) => (
              <div key={i} style={{ padding: '12px 18px', borderBottom: i < 3 ? '1px solid var(--line-1)' : 0,
                                    display: 'flex', alignItems: 'center', gap: 12 }}>
                <span style={{ flex: 1, fontSize: 12.5, color: 'var(--t-1)' }}>{r.l}</span>
                <button className="df-btn ghost sm">{r.v}{Icon.chevron}</button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Frame>
  );
}

Object.assign(window, {
  HiFiCommandPalette, HiFiSavedSearches, HiFiShortcuts, HiFiScanRules,
});
