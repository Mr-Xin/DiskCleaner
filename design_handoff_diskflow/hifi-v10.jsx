/* Hi-fi v1.0 补完屏 — External Drives 主页 · Onboarding · 两个确认弹窗 */

// ============ 外接磁盘主页 ============

function HiFiExternalDrives() {
  const drives = [
    {
      id: 'm-hd', n: 'Macintosh HD', sub: 'APFS · 内置 SSD',
      used: 312, total: 512, pct: 61, c: 'var(--blue)', state: 'connected', primary: true,
    },
    {
      id: 'bk', n: 'Backup-SSD', sub: 'APFS · USB-C · 1 TB Samsung T7',
      used: 740, total: 1024, pct: 72, c: 'var(--purple)', state: 'connected',
    },
    {
      id: 'tm', n: 'Time Machine', sub: 'APFS · 雷雳 · 4 TB',
      used: 1800, total: 4096, pct: 44, c: 'var(--cyan)', state: 'connected', tag: 'Time Machine',
    },
    {
      id: 'sd', n: 'SD CARD (32GB)', sub: 'ExFAT · 内置读卡器',
      used: 28, total: 32, pct: 87, c: 'var(--warn)', state: 'connected', warn: true,
    },
    {
      id: 'old', n: 'WD-Passport', sub: 'HFS+ · 上次连接 3 天前',
      used: 850, total: 2048, pct: 41, c: 'var(--t-4)', state: 'offline',
    },
  ];

  const fmt = (gb) => gb >= 1024 ? (gb / 1024).toFixed(1) + ' TB' : gb + ' GB';

  return (
    <Frame title="外接磁盘" sidebarActive="drives">
      <Toolbar
        search="按名称、类型筛选驱动器…"
        actions={
          <>
            <button className="df-btn ghost sm">{Icon.refresh}刷新</button>
            <button className="df-btn">{Icon.shield}权限设置</button>
          </>
        }
      />
      <div className="df-main">
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div>
            <h1 className="df-h1">外接磁盘</h1>
            <p className="df-p" style={{ marginTop: 4 }}>
              4 个已连接 · 1 个最近离线 · 总容量 <b style={{ color: 'var(--t-1)' }}>7.6 TB</b> · 已用 <b style={{ color: 'var(--blue-hi)' }}>3.8 TB</b>
            </p>
          </div>
          <Chip variant="good"><span className="dot"></span>完全磁盘访问权限已授权</Chip>
        </div>

        {/* 已连接的磁盘网格 */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 14 }}>
          {drives.filter(d => d.state === 'connected').map((d, i) => (
            <div key={d.id} className="df-card elevated" style={{ padding: 18, display: 'flex', flexDirection: 'column', gap: 12,
                                                                    position: 'relative', overflow: 'hidden' }}>
              {d.primary && (
                <div style={{ position: 'absolute', top: -40, right: -40, width: 160, height: 160, borderRadius: '50%',
                              background: `radial-gradient(circle, ${d.c}33, transparent 70%)`, filter: 'blur(20px)', pointerEvents: 'none' }}></div>
              )}
              {/* 头部 */}
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14, position: 'relative' }}>
                <div style={{ width: 48, height: 48, borderRadius: 12, flexShrink: 0,
                              background: `linear-gradient(135deg, ${d.c}, ${d.c}80)`,
                              display: 'grid', placeItems: 'center', color: '#fff',
                              boxShadow: `0 4px 14px ${d.c}40, inset 0 1px 0 rgba(255,255,255,0.2)` }}>
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect x="2" y="14" width="20" height="6" rx="2"/><rect x="2" y="4" width="20" height="6" rx="2"/>
                    <path d="M6 7h.01M6 17h.01"/>
                  </svg>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ fontSize: 15, fontWeight: 600, color: 'var(--t-1)' }}>{d.n}</span>
                    {d.primary && <Chip>启动盘</Chip>}
                    {d.tag && <Chip variant="good">{d.tag}</Chip>}
                    {d.warn && <Chip variant="warn"><span className="dot"></span>剩余不足</Chip>}
                  </div>
                  <div style={{ fontSize: 11.5, color: 'var(--t-3)', marginTop: 2 }}>{d.sub}</div>
                </div>
                <button className="df-icon-btn" title="弹出">{Icon.more}</button>
              </div>

              {/* 用量 */}
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
                <span style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.02em', color: 'var(--t-1)' }}>{fmt(d.used)}</span>
                <span style={{ fontSize: 12, color: 'var(--t-3)' }}>共 {fmt(d.total)}</span>
                <span style={{ marginLeft: 'auto', fontSize: 12, color: d.warn ? 'var(--warn)' : 'var(--t-3)', fontWeight: d.warn ? 600 : 400 }}>已用 {d.pct}%</span>
              </div>
              <Bar fill={d.pct} variant={d.warn ? 'warn' : ''} />

              {/* 操作按钮 */}
              <div style={{ display: 'flex', gap: 6, marginTop: 4 }}>
                <button className="df-btn sm" style={{ flex: 1, justifyContent: 'center' }}>{Icon.disk}扫描此盘</button>
                <button className="df-btn ghost sm" style={{ flex: 1, justifyContent: 'center' }}>{Icon.reveal}打开</button>
                {!d.primary && <button className="df-btn ghost sm">弹出</button>}
              </div>
            </div>
          ))}
        </div>

        {/* 离线/最近连接的磁盘 */}
        <div>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 8 }}>
            <h2 className="df-h2">最近离线</h2>
            <span className="df-label">1 个</span>
          </div>
          {drives.filter(d => d.state === 'offline').map(d => (
            <div key={d.id} className="df-card" style={{ padding: '14px 18px', display: 'flex', alignItems: 'center', gap: 14, opacity: 0.7 }}>
              <div style={{ width: 36, height: 36, borderRadius: 10, background: 'var(--glass-2)', border: '1px dashed var(--line-2)',
                            display: 'grid', placeItems: 'center', color: 'var(--t-3)' }}>{Icon.drive}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: 500 }}>{d.n}</div>
                <div style={{ fontSize: 11, color: 'var(--t-3)' }}>{d.sub} · 上次扫描快照仍可查看</div>
              </div>
              <span className="df-mono" style={{ fontSize: 12, color: 'var(--t-3)' }}>{fmt(d.used)} / {fmt(d.total)}</span>
              <button className="df-btn ghost sm">查看上次结果</button>
              <button className="df-btn ghost sm">移除</button>
            </div>
          ))}
        </div>
      </div>
    </Frame>
  );
}

// ============ 首启引导 Onboarding ============

function HiFiOnboarding() {
  return (
    <Frame title="DiskFlow · 欢迎" sidebarActive="overview">
      {/* 隐藏侧边栏需要重新写一个简化版 frame，这里复用并在 main 上做全屏覆盖 */}
      <div className="df-main" style={{ padding: 0, gap: 0, position: 'absolute', inset: '38px 0 0 0', background: 'var(--bg-1)' }}>
        <div style={{
          flex: 1, padding: 48, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 60, alignItems: 'center',
          position: 'relative', overflow: 'hidden',
        }}>
          {/* 背景光斑 */}
          <div style={{ position: 'absolute', top: -100, left: -100, width: 500, height: 500, borderRadius: '50%',
                        background: 'radial-gradient(circle, rgba(77,158,255,0.25), transparent 70%)', filter: 'blur(40px)' }}></div>
          <div style={{ position: 'absolute', bottom: -150, right: -100, width: 500, height: 500, borderRadius: '50%',
                        background: 'radial-gradient(circle, rgba(155,139,255,0.18), transparent 70%)', filter: 'blur(40px)' }}></div>

          {/* 左：欢迎文案 */}
          <div style={{ position: 'relative', zIndex: 2, display: 'flex', flexDirection: 'column', gap: 18 }}>
            <div className="df-brand-mark" style={{ width: 60, height: 60, borderRadius: 16, fontSize: 28 }}>D</div>
            <div>
              <div className="df-label" style={{ color: 'var(--blue-hi)' }}>欢迎使用 DiskFlow · v1.0</div>
              <h1 style={{ fontSize: 40, fontWeight: 700, letterSpacing: '-0.02em', margin: '8px 0 0', lineHeight: 1.15 }}>
                让你的 Mac<br/>
                <span style={{ background: 'linear-gradient(180deg, var(--blue-hi), var(--cyan))',
                               WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text' }}>
                  重新有了呼吸感
                </span>
              </h1>
            </div>
            <p style={{ fontSize: 14, color: 'var(--t-2)', lineHeight: 1.6, maxWidth: 360, margin: 0 }}>
              DiskFlow 帮你看清磁盘里到底装了什么，安全释放空间，让 Mac 长期保持顺滑。
            </p>

            {/* 三个特性 */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 14, marginTop: 8 }}>
              {[
                { icn: Icon.disk,    t: '可视化整盘占用',  d: '环形图 / 树状图 / 旭日图三种视角' },
                { icn: Icon.copy,    t: '智能找重复 / 大文件', d: '感知哈希 + 推荐保留项' },
                { icn: Icon.shield,  t: '默认安全删除',     d: '统一进废纸篓，30 天内可恢复' },
              ].map((f, i) => (
                <div key={i} style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
                  <div style={{ width: 32, height: 32, borderRadius: 8, background: 'var(--glass-2)',
                                border: '1px solid var(--line-2)', display: 'grid', placeItems: 'center',
                                color: 'var(--blue-hi)', flexShrink: 0 }}>{f.icn}</div>
                  <div>
                    <div style={{ fontSize: 13, fontWeight: 600 }}>{f.t}</div>
                    <div style={{ fontSize: 12, color: 'var(--t-3)', marginTop: 2 }}>{f.d}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* 右：步骤进度 + CTA */}
          <div style={{ position: 'relative', zIndex: 2, display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div className="df-card elevated" style={{ padding: 24, display: 'flex', flexDirection: 'column', gap: 18,
                                                        background: 'var(--glass-3)', borderColor: 'var(--line-3)' }}>
              {/* 步骤指示 */}
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
                {[
                  { i: 1, t: '欢迎',    state: 'done'    },
                  { i: 2, t: '授权',    state: 'current' },
                  { i: 3, t: '首次扫描', state: 'next'    },
                ].map((s, i, arr) => (
                  <React.Fragment key={i}>
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                      <div style={{
                        width: 28, height: 28, borderRadius: 14,
                        background: s.state === 'done'    ? 'var(--good)' :
                                    s.state === 'current' ? 'linear-gradient(180deg, var(--blue), #3a87f0)' :
                                                            'var(--glass-2)',
                        border: '1px solid ' + (s.state === 'next' ? 'var(--line-2)' : 'transparent'),
                        boxShadow: s.state === 'current' ? '0 0 0 4px rgba(77,158,255,0.2)' : 'none',
                        display: 'grid', placeItems: 'center',
                        color: s.state === 'next' ? 'var(--t-3)' : '#fff',
                        fontSize: 12, fontWeight: 700,
                      }}>
                        {s.state === 'done' ? '✓' : s.i}
                      </div>
                      <span style={{ fontSize: 11, color: s.state === 'next' ? 'var(--t-3)' : 'var(--t-1)', fontWeight: 500 }}>{s.t}</span>
                    </div>
                    {i < arr.length - 1 && (
                      <div style={{ flex: 1, height: 1.5, background: s.state === 'done' ? 'var(--good)' : 'var(--line-1)', marginBottom: 18 }}></div>
                    )}
                  </React.Fragment>
                ))}
              </div>

              <div className="df-divider"></div>

              {/* 当前步骤内容 */}
              <div>
                <h2 className="df-h2" style={{ fontSize: 17 }}>授予完全磁盘访问权限</h2>
                <p className="df-p" style={{ fontSize: 12.5, marginTop: 6, lineHeight: 1.6 }}>
                  为了准确扫描你的所有磁盘（包括外接盘、Time Machine），DiskFlow 需要 macOS 的「完全磁盘访问」权限。
                  我们<b style={{ color: 'var(--t-1)' }}>默认只读</b>，永远不会自动删除任何文件。
                </p>
              </div>

              <div style={{ background: 'var(--glass-1)', border: '1px solid var(--line-1)', borderRadius: 10, padding: 14,
                            display: 'flex', alignItems: 'center', gap: 12 }}>
                <span style={{ color: 'var(--blue-hi)' }}>{Icon.shield}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12.5, fontWeight: 500 }}>授予后会跳转到系统设置</div>
                  <div style={{ fontSize: 11, color: 'var(--t-3)', marginTop: 2 }}>勾选 DiskFlow.app 然后回到这里 · 可随时撤销</div>
                </div>
              </div>

              <div style={{ display: 'flex', gap: 10, marginTop: 4 }}>
                <button className="df-btn ghost" style={{ flex: 1, justifyContent: 'center' }}>稍后设置</button>
                <button className="df-btn primary" style={{ flex: 2, justifyContent: 'center', height: 38 }}>
                  {Icon.shield}打开系统设置授权 →
                </button>
              </div>
            </div>

            <p style={{ fontSize: 11, color: 'var(--t-3)', textAlign: 'center', margin: 0 }}>
              已经熟悉 DiskFlow？<a href="#" style={{ color: 'var(--blue-hi)' }}>跳过引导，直接进入主界面</a>
            </p>
          </div>
        </div>
      </div>
    </Frame>
  );
}

// ============ 确认弹窗：删除 >1GB ============

function HiFiConfirmDelete() {
  return (
    <Frame title="大文件" sidebarActive="large">
      {/* 后景：表格的虚化版本 */}
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost sm" disabled>{Icon.filter}筛选</button>
            <button className="df-btn primary" disabled>{Icon.trash}移到废纸篓</button>
          </>
        }
      />
      <div className="df-main" style={{ filter: 'blur(2px) saturate(0.7)', opacity: 0.4, pointerEvents: 'none' }}>
        <h1 className="df-h1">大文件</h1>
        <div className="df-card elevated" style={{ flex: 1, padding: 16 }}>
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} style={{ padding: 12, borderBottom: '1px solid var(--line-1)', display: 'flex', gap: 12 }}>
              <div style={{ width: 30, height: 30, borderRadius: 8, background: 'var(--glass-3)' }}></div>
              <div style={{ flex: 1 }}>
                <div style={{ height: 11, background: 'var(--glass-3)', borderRadius: 3, marginBottom: 6, width: '60%' }}></div>
                <div style={{ height: 9, background: 'var(--glass-2)', borderRadius: 3, width: '40%' }}></div>
              </div>
              <div style={{ width: 70, height: 12, background: 'var(--glass-3)', borderRadius: 3 }}></div>
            </div>
          ))}
        </div>
      </div>

      {/* 弹窗 */}
      <div className="df-modal-backdrop">
        <div className="df-modal" style={{ width: 460 }}>
          <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start', marginBottom: 18 }}>
            <div style={{ width: 48, height: 48, borderRadius: 12, flexShrink: 0,
                          background: 'linear-gradient(180deg, rgba(255,180,92,0.2), rgba(255,180,92,0.08))',
                          border: '1px solid rgba(255,180,92,0.4)',
                          display: 'grid', placeItems: 'center', color: 'var(--warn)' }}>
              {Icon.warning}
            </div>
            <div style={{ flex: 1 }}>
              <h2 style={{ fontSize: 17, fontWeight: 600, margin: 0, color: 'var(--t-1)' }}>确认删除这些文件？</h2>
              <p className="df-p" style={{ marginTop: 6, fontSize: 12.5 }}>
                你即将移除 <b style={{ color: 'var(--t-1)' }}>4 个文件 · 24.2 GB</b>。这些文件会先进入<b style={{ color: 'var(--t-1)' }}>废纸篓</b>，30 天内可以恢复。
              </p>
            </div>
          </div>

          {/* 文件列表预览 */}
          <div style={{ background: 'var(--glass-1)', border: '1px solid var(--line-1)', borderRadius: 10, overflow: 'hidden', marginBottom: 14 }}>
            {[
              { n: 'WWDC25-Keynote.mp4',     s: '8.4 GB' },
              { n: 'Xcode_15.4.xip',         s: '7.2 GB' },
              { n: 'ubuntu-24.04.iso',       s: '4.8 GB' },
              { n: 'screen-recording.mov',   s: '3.8 GB' },
            ].map((f, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 12px',
                                    borderBottom: i < 3 ? '1px solid var(--line-1)' : 0, fontSize: 12 }}>
                <span style={{ color: 'var(--t-3)' }}>{Icon.doc}</span>
                <span style={{ flex: 1, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{f.n}</span>
                <span className="df-mono" style={{ color: 'var(--t-2)' }}>{f.s}</span>
              </div>
            ))}
          </div>

          {/* 复选项 */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 18 }}>
            <Check />
            <span style={{ fontSize: 12, color: 'var(--t-2)' }}>不再为单次删除 &gt; 1 GB 弹出确认</span>
          </div>

          <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
            <button className="df-btn ghost">取消</button>
            <button className="df-btn" style={{ background: 'rgba(255,107,125,0.15)',
                                                  borderColor: 'rgba(255,107,125,0.4)',
                                                  color: 'var(--danger)' }}>
              {Icon.trash}移到废纸篓
            </button>
          </div>
        </div>
      </div>
    </Frame>
  );
}

// ============ 确认弹窗：完全卸载应用 ============

function HiFiConfirmUninstall() {
  return (
    <Frame title="应用程序" sidebarActive="apps">
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost sm" disabled>{Icon.filter}排序</button>
            <button className="df-btn primary" disabled>{Icon.trash}卸载</button>
          </>
        }
      />
      <div className="df-main" style={{ filter: 'blur(2px) saturate(0.7)', opacity: 0.4, pointerEvents: 'none' }}>
        <h1 className="df-h1">应用程序</h1>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, flex: 1 }}>
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="df-card elevated" style={{ height: 120 }}>
              <div style={{ width: 40, height: 40, borderRadius: 10, background: 'var(--glass-3)' }}></div>
            </div>
          ))}
        </div>
      </div>

      <div className="df-modal-backdrop">
        <div className="df-modal" style={{ width: 480 }}>
          <div style={{ display: 'flex', gap: 14, alignItems: 'center', marginBottom: 16 }}>
            <div style={{ width: 56, height: 56, borderRadius: 13, flexShrink: 0,
                          background: 'linear-gradient(135deg, #d287ff, #ff8eb1)',
                          display: 'grid', placeItems: 'center', fontWeight: 700, color: '#fff', fontSize: 18,
                          boxShadow: '0 4px 14px rgba(0,0,0,0.3)' }}>Lp</div>
            <div style={{ flex: 1 }}>
              <h2 style={{ fontSize: 17, fontWeight: 600, margin: 0 }}>完全卸载 Logic Pro？</h2>
              <p className="df-p" style={{ marginTop: 4, fontSize: 12.5 }}>
                此操作不可在应用内撤销 · 文件会进入废纸篓
              </p>
            </div>
          </div>

          <p className="df-p" style={{ fontSize: 12.5, marginBottom: 14, lineHeight: 1.6 }}>
            将删除应用本体及所有相关数据：
          </p>

          <div style={{ background: 'var(--glass-1)', border: '1px solid var(--line-1)', borderRadius: 10, padding: 14,
                        display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 16 }}>
            {[
              { l: '应用本体',          p: '/Applications/Logic Pro.app',                       s: '6.8 GB' },
              { l: '缓存',              p: '~/Library/Caches/com.apple.logic10',                s: '180 MB' },
              { l: '应用支持',          p: '~/Library/Application Support/Logic',               s: '1.4 GB', warn: true },
              { l: '偏好设置',          p: '~/Library/Preferences/com.apple.logic10.plist',     s: '12 KB' },
              { l: '容器',              p: '~/Library/Containers/com.apple.logic10',            s: '440 MB' },
            ].map((it, i) => (
              <div key={i} style={{ display: 'grid', gridTemplateColumns: '90px 1fr 60px', gap: 10, alignItems: 'center', fontSize: 11.5 }}>
                <span style={{ color: it.warn ? 'var(--warn)' : 'var(--t-2)' }}>{it.l}{it.warn && ' ⚠'}</span>
                <span className="df-mono" style={{ fontSize: 10.5, color: 'var(--t-3)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{it.p}</span>
                <span className="df-mono" style={{ color: 'var(--t-1)', textAlign: 'right' }}>{it.s}</span>
              </div>
            ))}
          </div>

          <div style={{ background: 'rgba(255,180,92,0.1)', border: '1px solid rgba(255,180,92,0.3)', borderRadius: 10, padding: 12,
                        display: 'flex', gap: 10, marginBottom: 18, alignItems: 'flex-start' }}>
            <span style={{ color: 'var(--warn)', marginTop: 2 }}>{Icon.warning}</span>
            <p style={{ margin: 0, fontSize: 11.5, color: 'var(--t-2)', lineHeight: 1.5 }}>
              <b style={{ color: 'var(--t-1)' }}>"应用支持"目录</b> 包含你的项目模板和自定义采样库。如需保留这些文件，请选择「保留应用支持目录」。
            </p>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
            <Check on />
            <span style={{ fontSize: 12, color: 'var(--t-2)' }}>保留应用支持目录（1.4 GB）</span>
          </div>

          <div style={{ display: 'flex', gap: 8, justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: 12, color: 'var(--t-3)' }}>
              将释放 <b className="df-mono" style={{ color: 'var(--blue-hi)', fontSize: 14 }}>7.4 GB</b>
            </span>
            <div style={{ display: 'flex', gap: 8 }}>
              <button className="df-btn ghost">取消</button>
              <button className="df-btn" style={{ background: 'rgba(255,107,125,0.15)',
                                                    borderColor: 'rgba(255,107,125,0.4)',
                                                    color: 'var(--danger)' }}>
                {Icon.trash}完全卸载
              </button>
            </div>
          </div>
        </div>
      </div>
    </Frame>
  );
}

Object.assign(window, {
  HiFiExternalDrives, HiFiOnboarding, HiFiConfirmDelete, HiFiConfirmUninstall,
});
