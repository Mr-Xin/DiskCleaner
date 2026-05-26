/* Hi-fi v1.3 — 菜单栏小应用 · 桌面 Widget · Shortcuts 集成 · iCloud 同步 */

// ============ 菜单栏 Mini App ============

function HiFiMenubar() {
  return (
    <div style={{
      width: '100%', height: '100%',
      background: 'linear-gradient(180deg, #1a3a5f 0%, #2d5a8f 40%, #4a78b8 100%)',
      position: 'relative', overflow: 'hidden',
    }}>
      {/* 仿 macOS 桌面壁纸效果 */}
      <div style={{ position: 'absolute', inset: 0,
                    background: 'radial-gradient(circle at 30% 30%, rgba(255,200,100,0.3), transparent 50%), radial-gradient(circle at 70% 70%, rgba(120,80,200,0.4), transparent 50%)' }}></div>

      {/* macOS 顶部菜单栏 */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 28,
        background: 'rgba(0,0,0,0.35)',
        backdropFilter: 'blur(20px) saturate(180%)',
        display: 'flex', alignItems: 'center', padding: '0 16px',
        fontSize: 13, color: '#fff', fontWeight: 500,
        gap: 18,
      }}>
        <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><path d="M17.5 12.5c-.5-1.5 0-3 1-3.5-1-1.5-2.5-2-4-2-1.5 0-2 .5-3 .5-1 0-1.5-.5-3-.5C6 7 4.5 8.5 4.5 11c0 4 3 8 5 8 .5 0 1.5-.5 2.5-.5s2 .5 2.5.5c1 0 2-1 3-2.5-2-1-2-3.5-.5-4z"/></svg>
        <span style={{ fontWeight: 700 }}>访达</span>
        <span style={{ fontWeight: 400 }}>文件</span>
        <span style={{ fontWeight: 400 }}>编辑</span>
        <div style={{ flex: 1 }}></div>
        {/* 菜单栏图标区 */}
        <span style={{ opacity: 0.9, fontSize: 12 }}>⚡ 89%</span>
        <span style={{ opacity: 0.9, fontSize: 12 }}>📶</span>
        <span style={{ opacity: 0.9, fontSize: 12 }}>🔍</span>
        {/* DiskFlow 菜单栏图标 - 高亮态 */}
        <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 4,
                      padding: '2px 8px', borderRadius: 4, background: 'rgba(255,255,255,0.18)' }}>
          <div style={{ width: 12, height: 12, borderRadius: 3,
                        background: 'linear-gradient(135deg, var(--blue), var(--purple), var(--cyan))',
                        display: 'grid', placeItems: 'center', fontSize: 7, fontWeight: 700, color: '#fff' }}>D</div>
          <span style={{ fontSize: 11.5, fontFamily: 'var(--font-mono)', fontWeight: 600 }}>61%</span>
        </div>
        <span style={{ opacity: 0.9, fontSize: 11 }}>周六 14:32</span>
      </div>

      {/* 菜单栏弹出小窗 */}
      <div style={{
        position: 'absolute', top: 34, right: 84, width: 340,
        background: 'rgba(20,24,34,0.88)',
        backdropFilter: 'blur(60px) saturate(180%)',
        border: '1px solid var(--line-3)',
        borderRadius: 14,
        boxShadow: '0 24px 60px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.04)',
        overflow: 'hidden',
        color: 'var(--t-1)',
      }}>
        {/* 头部 */}
        <div style={{ padding: '14px 16px', borderBottom: '1px solid var(--line-1)',
                      display: 'flex', alignItems: 'center', gap: 10 }}>
          <div className="df-brand-mark" style={{ width: 26, height: 26, fontSize: 13 }}>D</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 600 }}>DiskFlow</div>
            <div style={{ fontSize: 10.5, color: 'var(--t-3)' }}>实时 · 6 月 28 日 14:32</div>
          </div>
          <span className="df-chip good" style={{ height: 20 }}><span className="dot"></span>健康 82</span>
        </div>

        {/* 存储概览 */}
        <div style={{ padding: '14px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          {/* 磁盘条 */}
          <div>
            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 4 }}>
              <span style={{ fontSize: 11, color: 'var(--t-3)', fontWeight: 500 }}>Macintosh HD</span>
              <span className="df-mono" style={{ fontSize: 11, color: 'var(--t-2)' }}>312 / 512 GB</span>
            </div>
            <div className="df-stacked-bar" style={{ height: 8 }}>
              <span style={{ width: '22%', background: 'var(--cat-apps)' }}></span>
              <span style={{ width: '14%', background: 'var(--cat-docs)' }}></span>
              <span style={{ width: '10%', background: 'var(--cat-video)' }}></span>
              <span style={{ width: '8%', background: 'var(--cat-photo)' }}></span>
              <span style={{ width: '7%', background: 'var(--cat-system)' }}></span>
              <span style={{ width: '4%', background: 'var(--cat-cache)' }}></span>
            </div>
          </div>

          {/* 内存条 */}
          <div>
            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 4 }}>
              <span style={{ fontSize: 11, color: 'var(--t-3)', fontWeight: 500 }}>内存</span>
              <span className="df-mono" style={{ fontSize: 11, color: 'var(--warn)' }}>12.4 / 16 GB</span>
            </div>
            <Bar fill={78} variant="warn" />
          </div>
        </div>

        <div className="df-divider"></div>

        {/* 智能清理提示 */}
        <div style={{ padding: '12px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ color: 'var(--blue-hi)' }}>{Icon.sparkle}</span>
            <span style={{ fontSize: 12.5, fontWeight: 600 }}>可释放 12.4 GB</span>
          </div>
          <button className="df-btn primary sm" style={{ width: '100%', justifyContent: 'center', height: 30 }}>
            一键智能清理
          </button>
        </div>

        <div className="df-divider"></div>

        {/* 快捷操作列表 */}
        <div style={{ padding: '6px 0' }}>
          {[
            { i: Icon.bolt,    t: '释放内存',           k: '⌥⌘M' },
            { i: Icon.copy,    t: '查找重复文件',       k: '⌘D' },
            { i: Icon.disk,    t: '打开存储分析',       k: '⌘2' },
            { i: Icon.refresh, t: '立即重新扫描',       k: '⌘R' },
          ].map((r, i) => (
            <div key={i} style={{ padding: '7px 16px', display: 'flex', alignItems: 'center', gap: 10,
                                  fontSize: 12, color: 'var(--t-1)', cursor: 'default' }}>
              <span style={{ color: 'var(--t-3)' }}>{r.i}</span>
              <span style={{ flex: 1 }}>{r.t}</span>
              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--t-3)' }}>{r.k}</span>
            </div>
          ))}
        </div>

        <div className="df-divider"></div>

        {/* 底部 */}
        <div style={{ padding: '10px 16px', display: 'flex', alignItems: 'center',
                      background: 'rgba(7,9,13,0.4)' }}>
          <button className="df-btn ghost sm" style={{ flex: 1, justifyContent: 'flex-start', padding: '0 8px' }}>
            {Icon.grid}打开 DiskFlow ⌘O
          </button>
          <button className="df-icon-btn" style={{ width: 26, height: 26 }}>{Icon.settings}</button>
        </div>
      </div>

      {/* 桌面提示 */}
      <div style={{ position: 'absolute', bottom: 24, left: 24, right: 24,
                    padding: '12px 16px', borderRadius: 10,
                    background: 'rgba(0,0,0,0.4)', backdropFilter: 'blur(20px)',
                    border: '1px solid rgba(255,255,255,0.15)',
                    color: '#fff', fontSize: 11.5, display: 'flex', alignItems: 'center', gap: 10 }}>
        <span style={{ color: '#5dd5e8' }}>{Icon.sparkle}</span>
        <span>菜单栏小应用 · 不必打开主窗口也能查看 + 一键清理</span>
        <span style={{ marginLeft: 'auto', opacity: 0.6 }}>340 × 自适应</span>
      </div>
    </div>
  );
}

// ============ 桌面 Widget ============

function HiFiWidget() {
  return (
    <div style={{
      width: '100%', height: '100%',
      background: 'linear-gradient(135deg, #2a1a4a 0%, #4a2a6a 40%, #6a3a8a 100%)',
      position: 'relative', overflow: 'hidden',
    }}>
      {/* 桌面壁纸效果 */}
      <div style={{ position: 'absolute', inset: 0,
                    background: 'radial-gradient(circle at 70% 30%, rgba(255,180,100,0.25), transparent 50%), radial-gradient(circle at 20% 80%, rgba(100,200,255,0.2), transparent 50%)' }}></div>

      {/* macOS 顶部菜单栏（简化）*/}
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 28,
                    background: 'rgba(0,0,0,0.3)', backdropFilter: 'blur(20px)',
                    display: 'flex', alignItems: 'center', padding: '0 16px', gap: 16,
                    fontSize: 12, color: '#fff' }}>
        <span style={{ fontWeight: 700 }}> 桌面</span>
        <div style={{ flex: 1 }}></div>
        <span style={{ opacity: 0.7 }}>14:32 · 周六</span>
      </div>

      {/* 桌面文件假装存在 */}
      <div style={{ position: 'absolute', top: 60, left: 30, display: 'flex', flexDirection: 'column', gap: 28, opacity: 0.6 }}>
        {['Documents', 'Projects', 'Inbox'].map((n, i) => (
          <div key={i} style={{ width: 64, textAlign: 'center', color: '#fff' }}>
            <div style={{ width: 48, height: 40, borderRadius: 6, background: 'rgba(110,200,255,0.7)',
                          margin: '0 auto', boxShadow: '0 4px 12px rgba(0,0,0,0.3)' }}></div>
            <div style={{ fontSize: 10, marginTop: 4, textShadow: '0 1px 2px rgba(0,0,0,0.5)' }}>{n}</div>
          </div>
        ))}
      </div>

      {/* 中号 widget */}
      <div style={{
        position: 'absolute', top: 60, right: 50, width: 280,
        background: 'rgba(20,24,34,0.78)',
        backdropFilter: 'blur(40px) saturate(180%)',
        borderRadius: 22,
        border: '1px solid rgba(255,255,255,0.12)',
        boxShadow: '0 20px 50px rgba(0,0,0,0.4)',
        padding: 18,
        display: 'flex', flexDirection: 'column', gap: 14,
        color: 'var(--t-1)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div className="df-brand-mark" style={{ width: 22, height: 22, fontSize: 11, borderRadius: 6 }}>D</div>
          <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--t-1)' }}>DiskFlow</span>
          <span style={{ flex: 1 }}></span>
          <span style={{ fontSize: 10, color: 'var(--t-3)' }}>14:32</span>
        </div>

        {/* 大数字 + 进度 */}
        <div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
            <span style={{ fontSize: 36, fontWeight: 700, letterSpacing: '-0.03em',
                           background: 'linear-gradient(180deg, #fff, var(--blue-hi))',
                           WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text' }}>312</span>
            <span style={{ fontSize: 14, color: 'var(--t-3)' }}>/ 512 GB</span>
            <span style={{ marginLeft: 'auto', fontSize: 10, color: 'var(--good)', fontWeight: 500 }}>● 健康 82</span>
          </div>
          <div className="df-stacked-bar" style={{ height: 6, marginTop: 8 }}>
            <span style={{ width: '22%', background: 'var(--cat-apps)' }}></span>
            <span style={{ width: '14%', background: 'var(--cat-docs)' }}></span>
            <span style={{ width: '10%', background: 'var(--cat-video)' }}></span>
            <span style={{ width: '8%', background: 'var(--cat-photo)' }}></span>
            <span style={{ width: '7%', background: 'var(--cat-system)' }}></span>
            <span style={{ width: '4%', background: 'var(--cat-cache)' }}></span>
          </div>
        </div>

        <div style={{ height: 1, background: 'var(--line-1)' }}></div>

        {/* 智能清理建议 */}
        <div>
          <div style={{ fontSize: 10, color: 'var(--t-3)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>可释放</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4 }}>
            <span style={{ color: 'var(--blue-hi)' }}>{Icon.sparkle}</span>
            <span style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.02em', color: 'var(--blue-hi)' }}>12.4 GB</span>
            <span style={{ fontSize: 11, color: 'var(--t-3)', marginLeft: 4 }}>3 项建议</span>
          </div>
        </div>

        <button className="df-btn primary sm" style={{ width: '100%', justifyContent: 'center', height: 30 }}>
          一键清理
        </button>
      </div>

      {/* 小号 widget */}
      <div style={{
        position: 'absolute', bottom: 80, right: 50, width: 160, height: 160,
        background: 'rgba(20,24,34,0.78)',
        backdropFilter: 'blur(40px)',
        borderRadius: 22,
        border: '1px solid rgba(255,255,255,0.12)',
        boxShadow: '0 20px 50px rgba(0,0,0,0.4)',
        padding: 14,
        display: 'flex', flexDirection: 'column',
        color: 'var(--t-1)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ color: 'var(--warn)' }}>{Icon.cpu}</span>
          <span style={{ fontSize: 11, color: 'var(--t-3)', fontWeight: 600 }}>内存</span>
        </div>
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ position: 'relative', width: 100, height: 100 }}>
            <svg width="100" height="100" viewBox="0 0 100 100">
              <circle cx="50" cy="50" r="40" fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="8"/>
              <circle cx="50" cy="50" r="40" fill="none" stroke="var(--warn)" strokeWidth="8"
                      strokeDasharray="196 251" strokeLinecap="round" transform="rotate(-90 50 50)"
                      style={{ filter: 'drop-shadow(0 0 6px rgba(255,180,92,0.6))' }}/>
            </svg>
            <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', textAlign: 'center' }}>
              <div>
                <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.02em', color: 'var(--warn)' }}>78%</div>
                <div style={{ fontSize: 9, color: 'var(--t-3)', marginTop: -2, fontFamily: 'var(--font-mono)' }}>12.4 / 16 GB</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* dock 模拟 */}
      <div style={{ position: 'absolute', bottom: 12, left: '50%', transform: 'translateX(-50%)',
                    background: 'rgba(255,255,255,0.18)', backdropFilter: 'blur(30px)',
                    border: '1px solid rgba(255,255,255,0.25)',
                    borderRadius: 18, padding: 6, display: 'flex', gap: 6 }}>
        {['#4d9eff', '#5fd49a', '#ffb45c', '#d287ff', '#5dd5e8'].map((c, i) => (
          <div key={i} style={{ width: 36, height: 36, borderRadius: 8,
                                  background: `linear-gradient(135deg, ${c}, ${c}80)`,
                                  boxShadow: '0 2px 6px rgba(0,0,0,0.4)' }}></div>
        ))}
        <div style={{ width: 1, background: 'rgba(255,255,255,0.2)', margin: '0 4px' }}></div>
        <div style={{ width: 36, height: 36, borderRadius: 8,
                        background: 'linear-gradient(135deg, var(--blue), var(--purple) 70%, var(--cyan))',
                        boxShadow: '0 4px 14px rgba(77,158,255,0.5)',
                        display: 'grid', placeItems: 'center', color: '#fff', fontWeight: 700, fontSize: 16 }}>D</div>
      </div>

      {/* 桌面提示 */}
      <div style={{ position: 'absolute', bottom: 70, left: 24,
                    padding: '10px 14px', borderRadius: 10,
                    background: 'rgba(0,0,0,0.4)', backdropFilter: 'blur(20px)',
                    border: '1px solid rgba(255,255,255,0.15)',
                    color: '#fff', fontSize: 11, display: 'flex', alignItems: 'center', gap: 8, maxWidth: 320 }}>
        <span style={{ color: '#5dd5e8' }}>{Icon.sparkle}</span>
        <span>桌面 Widget · 中号 280×320 · 小号 160×160</span>
      </div>
    </div>
  );
}

// ============ Apple Shortcuts 集成 ============

function HiFiShortcutsIntegration() {
  const actions = [
    { i: Icon.disk,    t: '扫描指定文件夹',     d: '输入：路径列表 · 输出：扫描结果 JSON',         tag: '查询' },
    { i: Icon.copy,    t: '查找重复文件',       d: '输入：文件夹路径 · 输出：重复组数 / 可释放',  tag: '查询' },
    { i: Icon.bolt,    t: '运行智能清理',       d: '可设置：仅清理"安全"项 / 跳过 > X GB',        tag: '动作' },
    { i: Icon.trash,   t: '清理指定缓存',       d: '输入：bundle ID · 输出：释放字节数',           tag: '动作' },
    { i: Icon.archive, t: '归档到外部',         d: '输入：文件 + 目标盘 · 输出：归档成功 / 失败',  tag: '动作' },
    { i: Icon.bell,    t: '获取磁盘状态',       d: '输出：剩余空间、健康分、内存压力等级',         tag: '查询' },
  ];

  const samples = [
    { i: '🌙', t: '夜间自动清理', d: '每天凌晨 1 点 · 仅清理"安全"项 · 释放后通知',     when: '每天 01:00' },
    { i: '📸', t: '导入照片前预备', d: '收到 iPhone 连接事件 → 检查可用空间 → 不足则清理', when: '事件触发' },
    { i: '🎬', t: 'Final Cut 工作流', d: '打开 FCP → 关闭其他大占用应用 → 释放内存',   when: '应用触发' },
  ];

  return (
    <Frame title="设置 · Apple Shortcuts" sidebarActive="settings">
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost sm">查看文档</button>
            <button className="df-btn">打开 Shortcuts.app →</button>
          </>
        }
      />
      <div className="df-main">
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: 'var(--t-3)', marginBottom: 4 }}>
          <span>设置</span><span>›</span><span>集成</span><span>›</span><span style={{ color: 'var(--blue-hi)' }}>Apple Shortcuts</span>
        </div>

        {/* 头部说明 */}
        <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start' }}>
          <div style={{ width: 56, height: 56, borderRadius: 13, flexShrink: 0,
                        background: 'linear-gradient(135deg, #ff7a78, #ff5a7e, #b948c0)',
                        display: 'grid', placeItems: 'center', color: '#fff',
                        boxShadow: '0 8px 24px rgba(255,90,126,0.35)' }}>
            <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor"><path d="M14 6a4 4 0 1 0-4 4 4 4 0 0 0 4-4zm6 12a4 4 0 1 0-4 4 4 4 0 0 0 4-4zM8 18a4 4 0 1 0-4 4 4 4 0 0 0 4-4z" /></svg>
          </div>
          <div style={{ flex: 1 }}>
            <h1 className="df-h1">Apple Shortcuts</h1>
            <p className="df-p" style={{ marginTop: 4, fontSize: 13, maxWidth: 600 }}>
              把 DiskFlow 接到你自动化流程里 · 也可以在 Spotlight 输入 <span className="df-mono" style={{ background: 'var(--glass-2)', padding: '1px 6px', borderRadius: 4 }}>"释放 RAM"</span> 直接触发。
            </p>
          </div>
          <span className="df-chip good"><span className="dot"></span>已启用</span>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 16, flex: 1, minHeight: 0 }}>
          {/* 可用动作 */}
          <div className="df-card elevated" style={{ padding: 0, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
            <div style={{ padding: '14px 18px', borderBottom: '1px solid var(--line-1)',
                          display: 'flex', alignItems: 'center', gap: 8 }}>
              <h2 className="df-h2">可用动作</h2>
              <span className="df-label">{actions.length} 个</span>
            </div>
            <div style={{ flex: 1, overflow: 'hidden' }}>
              {actions.map((a, i) => (
                <div key={i} style={{ padding: '12px 18px', borderBottom: i < actions.length - 1 ? '1px solid var(--line-1)' : 0,
                                      display: 'flex', alignItems: 'center', gap: 12 }}>
                  <div style={{ width: 30, height: 30, borderRadius: 8, flexShrink: 0,
                                background: a.tag === '动作' ? 'rgba(95,212,154,0.15)' : 'rgba(77,158,255,0.15)',
                                border: '1px solid ' + (a.tag === '动作' ? 'rgba(95,212,154,0.4)' : 'rgba(77,158,255,0.4)'),
                                display: 'grid', placeItems: 'center',
                                color: a.tag === '动作' ? 'var(--good)' : 'var(--blue-hi)' }}>{a.i}</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--t-1)' }}>{a.t}</div>
                    <div style={{ fontSize: 11, color: 'var(--t-3)', marginTop: 2 }}>{a.d}</div>
                  </div>
                  <Chip variant={a.tag === '动作' ? 'good' : ''}>{a.tag}</Chip>
                </div>
              ))}
            </div>
          </div>

          {/* 示例脚本 */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            <div className="df-label" style={{ paddingLeft: 4 }}>示例自动化</div>
            {samples.map((s, i) => (
              <div key={i} className="df-card" style={{ padding: 14, display: 'flex', gap: 12 }}>
                <div style={{ width: 36, height: 36, borderRadius: 8, flexShrink: 0,
                              background: 'var(--glass-2)', display: 'grid', placeItems: 'center', fontSize: 20 }}>{s.i}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2 }}>
                    <span style={{ fontSize: 12.5, fontWeight: 600 }}>{s.t}</span>
                    <span style={{ fontSize: 9, padding: '1px 6px', borderRadius: 3, background: 'var(--glass-3)', color: 'var(--t-3)' }}>{s.when}</span>
                  </div>
                  <div style={{ fontSize: 11, color: 'var(--t-3)', lineHeight: 1.5 }}>{s.d}</div>
                  <button className="df-btn ghost sm" style={{ marginTop: 6 }}>{Icon.archive}导入到 Shortcuts</button>
                </div>
              </div>
            ))}

            <div className="df-card" style={{ padding: 14, marginTop: 'auto', background: 'rgba(77,158,255,0.06)',
                                                borderColor: 'rgba(77,158,255,0.25)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                <span style={{ color: 'var(--blue-hi)' }}>{Icon.bolt}</span>
                <span style={{ fontSize: 12, fontWeight: 600 }}>AppleScript / 终端命令</span>
              </div>
              <p style={{ margin: 0, fontSize: 11, color: 'var(--t-3)', lineHeight: 1.5 }}>
                高级用户可通过 <span className="df-mono">diskflow</span> CLI 调用所有动作。
              </p>
              <div className="df-mono" style={{ marginTop: 8, padding: 8, background: 'rgba(0,0,0,0.3)',
                                                  borderRadius: 5, fontSize: 10.5, color: 'var(--cyan)' }}>
                $ diskflow clean --safe-only --max=10GB
              </div>
            </div>
          </div>
        </div>
      </div>
    </Frame>
  );
}

// ============ iCloud 偏好同步 ============

function HiFiICloudSync() {
  return (
    <Frame title="设置 · iCloud 同步" sidebarActive="settings">
      <div className="df-main" style={{ maxWidth: 820, alignSelf: 'center', width: '100%' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: 'var(--t-3)', marginBottom: 4 }}>
          <span>设置</span><span>›</span><span>集成</span><span>›</span><span style={{ color: 'var(--blue-hi)' }}>iCloud 同步</span>
        </div>

        {/* 账户头部 */}
        <div className="df-card elevated" style={{ padding: 22, display: 'flex', alignItems: 'center', gap: 16 }}>
          <div style={{ width: 64, height: 64, borderRadius: 18,
                        background: 'linear-gradient(135deg, #4d9eff, #5dd5e8 70%, #b3d9ff)',
                        display: 'grid', placeItems: 'center', color: '#fff', flexShrink: 0,
                        boxShadow: '0 8px 24px rgba(77,158,255,0.35)' }}>
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
              <path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z" />
            </svg>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
              <h1 className="df-h1" style={{ fontSize: 20 }}>iCloud 同步</h1>
              <Chip variant="good"><span className="dot"></span>已连接</Chip>
            </div>
            <p className="df-p" style={{ fontSize: 12.5 }}>
              alex@icloud.com · 在你所有装有 DiskFlow 的 Mac 之间同步偏好与设置
            </p>
          </div>
          <button className="df-btn ghost">注销</button>
        </div>

        {/* 同步项目 */}
        <div>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 6 }}>
            <h2 className="df-h2">同步的项目</h2>
            <span className="df-label">最后同步 · 2 分钟前</span>
          </div>
          <div className="df-card elevated" style={{ padding: 0, overflow: 'hidden' }}>
            {[
              { l: '应用偏好',                sub: '主题、字号、布局选项',             en: true, count: '23 项',  size: '< 1 KB' },
              { l: '扫描规则',                sub: '自定义包含目录与排除规则',         en: true, count: '12 项',  size: '4 KB' },
              { l: '保存的搜索',              sub: 'Large Files 中的查询',             en: true, count: '5 项',   size: '< 1 KB' },
              { l: '调度计划',                sub: '自动扫描时间表',                   en: true, count: '8 任务', size: '2 KB' },
              { l: '键盘快捷键',              sub: '自定义快捷键覆盖',                 en: false, count: '0 项',  size: '—' },
              { l: '通知偏好',                sub: '哪些事件触发通知',                 en: true, count: '12 项',  size: '< 1 KB' },
            ].map((r, i, arr) => (
              <div key={i} style={{ padding: '14px 18px', borderBottom: i < arr.length - 1 ? '1px solid var(--line-1)' : 0,
                                    display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, color: 'var(--t-1)', fontWeight: 500 }}>{r.l}</div>
                  <div style={{ fontSize: 11, color: 'var(--t-3)', marginTop: 2 }}>{r.sub}</div>
                </div>
                <span className="df-mono" style={{ fontSize: 11, color: 'var(--t-3)', minWidth: 60, textAlign: 'right' }}>{r.count}</span>
                <span className="df-mono" style={{ fontSize: 11, color: 'var(--t-3)', minWidth: 50, textAlign: 'right' }}>{r.size}</span>
                <div style={{
                  width: 34, height: 20, borderRadius: 10, position: 'relative',
                  background: r.en ? 'linear-gradient(180deg, var(--blue), #3a87f0)' : 'var(--glass-3)',
                  border: '1px solid ' + (r.en ? 'rgba(77,158,255,0.6)' : 'var(--line-2)'),
                  boxShadow: r.en ? '0 2px 8px rgba(77,158,255,0.4)' : 'none',
                  flexShrink: 0,
                }}>
                  <div style={{ position: 'absolute', top: 1, left: r.en ? 16 : 1, width: 16, height: 16,
                                borderRadius: 8, background: '#fff' }}></div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* 已链接设备 */}
        <div>
          <h2 className="df-h2" style={{ marginBottom: 6 }}>已链接设备</h2>
          <div className="df-card elevated" style={{ padding: 0, overflow: 'hidden' }}>
            {[
              { n: '这台 Mac', sub: 'MacBook Pro 14" · macOS 15.4 · v1.3.0', this: true, last: '现在' },
              { n: 'Mac mini · 工作室', sub: 'Mac mini M2 · macOS 15.4 · v1.3.0', last: '2 分钟前' },
              { n: 'MacBook Air · 备用', sub: 'MacBook Air M1 · macOS 14.6 · v1.2.4', last: '昨天', warn: true },
            ].map((d, i, arr) => (
              <div key={i} style={{ padding: '14px 18px', borderBottom: i < arr.length - 1 ? '1px solid var(--line-1)' : 0,
                                    display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ width: 32, height: 32, borderRadius: 8, background: 'var(--glass-2)',
                              border: '1px solid var(--line-2)', display: 'grid', placeItems: 'center', color: 'var(--blue-hi)' }}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
                    <rect x="2" y="4" width="20" height="14" rx="2"/><path d="M8 22h8M12 18v4"/>
                  </svg>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span style={{ fontSize: 13, fontWeight: 500 }}>{d.n}</span>
                    {d.this && <Chip variant="good"><span className="dot"></span>当前设备</Chip>}
                    {d.warn && <Chip variant="warn">需更新到 v1.3</Chip>}
                  </div>
                  <div style={{ fontSize: 11, color: 'var(--t-3)', marginTop: 2 }}>{d.sub}</div>
                </div>
                <span style={{ fontSize: 11, color: 'var(--t-3)' }}>{d.last}</span>
                {!d.this && <button className="df-btn ghost sm">取消链接</button>}
              </div>
            ))}
          </div>
        </div>

        {/* 隐私说明 */}
        <div style={{ padding: 14, background: 'rgba(95,212,154,0.06)', border: '1px solid rgba(95,212,154,0.2)',
                      borderRadius: 'var(--r-lg)', display: 'flex', gap: 12, alignItems: 'flex-start', marginBottom: 30 }}>
          <span style={{ color: 'var(--good)', marginTop: 2 }}>{Icon.shield}</span>
          <div>
            <div style={{ fontSize: 12.5, fontWeight: 600, marginBottom: 4 }}>端到端加密</div>
            <p style={{ margin: 0, fontSize: 11.5, color: 'var(--t-2)', lineHeight: 1.5 }}>
              所有同步数据使用你的 iCloud 钥匙串加密 · DiskFlow 服务器看不到你的扫描结果与文件清单 · 总共占用 iCloud 不到 1 MB。
            </p>
          </div>
        </div>
      </div>
    </Frame>
  );
}

Object.assign(window, {
  HiFiMenubar, HiFiWidget, HiFiShortcutsIntegration, HiFiICloudSync,
});
