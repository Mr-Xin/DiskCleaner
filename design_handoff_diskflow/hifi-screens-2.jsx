/* Hi-fi: Memory · Applications · Settings · States */

// ============ MEMORY ============

function HiFiMemory() {
  // generate a smoother live graph
  const ram = [62, 64, 60, 65, 70, 68, 72, 75, 70, 73, 78, 75, 80, 82, 78, 80, 77, 79, 76, 78];
  const cpu = [22, 25, 20, 28, 35, 30, 38, 42, 36, 40, 48, 42, 38, 32, 28, 30, 34, 36, 30, 34];

  return (
    <Frame title="Memory" sidebarActive="memory">
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost sm">{Icon.pause}Pause</button>
            <button className="df-btn primary">{Icon.bolt}Free RAM</button>
          </>
        }
      />
      <div className="df-main">
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div>
            <h1 className="df-h1">Memory monitor</h1>
            <p className="df-p" style={{ marginTop: 4 }}>Live · samples every 1s · 16 GB unified memory.</p>
          </div>
          <Chip variant="warn"><span className="dot"></span>Yellow pressure</Chip>
        </div>

        {/* top stats */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          {[
            { l: 'In use',  v: '12.4 GB', s: 'of 16 GB',         pct: 78, variant: 'warn', spark: ram, color: 'var(--warn)' },
            { l: 'Cached',  v: '2.8 GB',  s: 'reclaimable',      pct: 18, variant: '',     spark: [40,42,44,41,45,43,46,44,47,45,48,46,47,49,47,48,50,48,49,51], color: 'var(--blue)' },
            { l: 'Swap',    v: '1.2 GB',  s: '↑ growing',        pct: 8,  variant: 'danger', spark: [10,11,11,12,12,13,14,14,15,16,18,20,22,24,26,28,30,32,34,38], color: 'var(--danger)' },
            { l: 'CPU',     v: '34%',     s: '8 cores · 3.2GHz', pct: 34, variant: '',     spark: cpu, color: 'var(--cyan)' },
          ].map((s, i) => (
            <div key={i} className="df-card elevated" style={{ padding: 16 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span className="df-label">{s.l}</span>
                <Sparkline data={s.spark} color={s.color} filled />
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 10 }}>
                <span style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.02em' }}>{s.v}</span>
                <span style={{ fontSize: 11.5, color: s.l === 'Swap' ? 'var(--danger)' : 'var(--t-3)' }}>{s.s}</span>
              </div>
              <div style={{ marginTop: 10 }}><Bar fill={s.pct} variant={s.variant} /></div>
            </div>
          ))}
        </div>

        {/* live graph */}
        <div className="df-card elevated" style={{ padding: 18, height: 180, position: 'relative' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
            <span className="df-label">RAM + CPU · last 60 seconds</span>
            <div style={{ display: 'flex', gap: 12, fontSize: 11, color: 'var(--t-2)' }}>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                <span style={{ width: 8, height: 8, borderRadius: 2, background: 'var(--blue)', boxShadow: '0 0 6px var(--blue)' }}></span> RAM
              </span>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                <span style={{ width: 8, height: 8, borderRadius: 2, background: 'var(--cyan)', boxShadow: '0 0 6px var(--cyan)' }}></span> CPU
              </span>
              <span className="df-chip good" style={{ height: 20 }}><span className="dot"></span>Live</span>
            </div>
          </div>
          <svg viewBox="0 0 600 100" preserveAspectRatio="none" style={{ width: '100%', height: 120 }}>
            <defs>
              <linearGradient id="memGradBlue" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stopColor="#4d9eff" stopOpacity="0.4"/>
                <stop offset="100%" stopColor="#4d9eff" stopOpacity="0"/>
              </linearGradient>
              <linearGradient id="memGradCyan" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stopColor="#5dd5e8" stopOpacity="0.3"/>
                <stop offset="100%" stopColor="#5dd5e8" stopOpacity="0"/>
              </linearGradient>
            </defs>
            {/* grid */}
            {[20, 40, 60, 80].map(y => <line key={y} x1="0" x2="600" y1={y} y2={y} stroke="rgba(255,255,255,0.04)" />)}
            {/* RAM area */}
            <path d="M 0 38 L 30 35 L 60 40 L 90 32 L 120 26 L 150 30 L 180 22 L 210 18 L 240 24 L 270 20 L 300 15 L 330 20 L 360 12 L 390 10 L 420 16 L 450 14 L 480 18 L 510 14 L 540 16 L 570 12 L 600 14 L 600 100 L 0 100 Z"
                  fill="url(#memGradBlue)" />
            <polyline points="0,38 30,35 60,40 90,32 120,26 150,30 180,22 210,18 240,24 270,20 300,15 330,20 360,12 390,10 420,16 450,14 480,18 510,14 540,16 570,12 600,14"
                      fill="none" stroke="#4d9eff" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"
                      style={{ filter: 'drop-shadow(0 0 4px rgba(77,158,255,0.6))' }} />
            {/* CPU area */}
            <path d="M 0 76 L 30 72 L 60 78 L 90 68 L 120 60 L 150 64 L 180 56 L 210 52 L 240 58 L 270 54 L 300 48 L 330 56 L 360 64 L 390 70 L 420 66 L 450 62 L 480 60 L 510 64 L 540 60 L 570 66 L 600 62 L 600 100 L 0 100 Z"
                  fill="url(#memGradCyan)" />
            <polyline points="0,76 30,72 60,78 90,68 120,60 150,64 180,56 210,52 240,58 270,54 300,48 330,56 360,64 390,70 420,66 450,62 480,60 510,64 540,60 570,66 600,62"
                      fill="none" stroke="#5dd5e8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"
                      style={{ filter: 'drop-shadow(0 0 4px rgba(93,213,232,0.5))' }} />
            {/* now marker */}
            <line x1="595" x2="595" y1="0" y2="100" stroke="rgba(255,255,255,0.25)" strokeDasharray="2 3"/>
            <circle cx="595" cy="14" r="3" fill="#4d9eff" stroke="#fff" strokeWidth="1"/>
          </svg>
        </div>

        {/* processes */}
        <div className="df-card elevated" style={{ padding: 0, flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0, overflow: 'hidden' }}>
          <div style={{ padding: '12px 18px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--line-1)' }}>
            <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
              <h2 className="df-h2">Top processes</h2>
              <span className="df-label">by memory</span>
            </div>
            <div style={{ display: 'flex', gap: 6 }}>
              <Chip active>All</Chip>
              <Chip>User</Chip>
              <Chip>System</Chip>
            </div>
          </div>
          <div className="df-row head" style={{ gridTemplateColumns: '32px 1fr 100px 80px 90px 32px' }}>
            <span></span>
            <span>Process</span>
            <span>Memory</span>
            <span>CPU</span>
            <span>Energy</span>
            <span></span>
          </div>
          <div style={{ flex: 1, overflow: 'hidden' }}>
            {[
              { n: 'Google Chrome Helper (renderer)', sub: 'PID 8421 · github.com', m: 2.4, c: 14, e: 'High', sel: true, sp: [12,14,18,20,22,24,22,24] },
              { n: 'Xcode',                           sub: 'PID 4221',              m: 1.8, c: 8,  e: 'Medium', sp: [14,16,15,17,18,17,16,18] },
              { n: 'Slack',                           sub: 'PID 2934',              m: 0.98, c: 4, e: 'Medium', sp: [8,8,9,9,10,9,9,10] },
              { n: 'Figma Desktop',                   sub: 'PID 6612',              m: 0.84, c: 3, e: 'Low', sp: [6,6,7,7,8,7,8,8] },
              { n: 'kernel_task',                     sub: 'PID 0',                 m: 0.62, c: 6, e: '—', sp: [5,5,6,6,6,5,6,6] },
              { n: 'Notion',                          sub: 'PID 5781',              m: 0.42, c: 1, e: 'Low', sp: [3,3,3,4,4,3,4,4] },
            ].map((p, i) => (
              <div key={i} className={'df-row ' + (p.sel ? 'selected' : '')}
                   style={{ gridTemplateColumns: '32px 1fr 100px 80px 90px 32px' }}>
                <Check on={p.sel} />
                <div>
                  <div style={{ fontSize: 12.5, color: 'var(--t-1)', fontWeight: 500 }}>{p.n}</div>
                  <div className="df-mono" style={{ fontSize: 10, color: 'var(--t-3)' }}>{p.sub}</div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <Sparkline data={p.sp} color="var(--blue)" />
                  <span className="df-mono" style={{ fontSize: 12, color: 'var(--t-1)' }}>{p.m.toFixed(2)} GB</span>
                </div>
                <span className="df-mono" style={{ fontSize: 12 }}>{p.c}%</span>
                <Chip variant={p.e === 'High' ? 'warn' : ''}>{p.e}</Chip>
                <span style={{ color: 'var(--t-3)' }}>{Icon.more}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Frame>
  );
}

// ============ APPS ============

function HiFiApps() {
  const apps = [
    { n: 'Adobe Photoshop',  v: '25.1',   s: '4.2 GB',  l: '2 months ago', sel: true,  init: 'Ps', grad: 'linear-gradient(135deg, #4d9eff, #9b8bff)' },
    { n: 'Logic Pro',        v: '10.7',   s: '6.8 GB',  l: 'Never opened', sel: true,  init: 'Lp', grad: 'linear-gradient(135deg, #d287ff, #ff8eb1)' },
    { n: 'Sketch',           v: '99.3',   s: '380 MB',  l: '1 year ago',                init: 'Sk', grad: 'linear-gradient(135deg, #ffb45c, #ff8b6b)' },
    { n: 'Slack',            v: '4.36.1', s: '720 MB',  l: '2 hours ago',               init: 'Sl', grad: 'linear-gradient(135deg, #9b8bff, #5dd5e8)' },
    { n: 'Figma',            v: '124.8',  s: '210 MB',  l: 'Yesterday',                 init: 'Fi', grad: 'linear-gradient(135deg, #5fd49a, #5dd5e8)' },
    { n: 'Notion',           v: '3.5',    s: '180 MB',  l: 'Today',                     init: 'No', grad: 'linear-gradient(135deg, #f0f3f8, #b6bfcf)' },
    { n: 'Spotify',          v: '1.2',    s: '320 MB',  l: 'Today',                     init: 'Sp', grad: 'linear-gradient(135deg, #5fd49a, #4d9eff)' },
    { n: 'Zoom',             v: '6.1',    s: '90 MB',   l: '3 weeks ago',               init: 'Zo', grad: 'linear-gradient(135deg, #4d9eff, #5dd5e8)' },
  ];

  return (
    <Frame title="Applications" sidebarActive="apps">
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost sm">{Icon.filter}Sort: Last opened</button>
            <button className="df-btn primary">{Icon.trash}Uninstall 2</button>
          </>
        }
      />
      <div className="df-main">
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div>
            <h1 className="df-h1">Apps you might not need</h1>
            <p className="df-p" style={{ marginTop: 4 }}>
              68 GB across 142 apps · DiskFlow finds <b style={{ color: 'var(--t-1)' }}>leftover data</b> even after dragging an app to Trash.
            </p>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <Chip active>All apps</Chip>
            <Chip>Unused 30d+</Chip>
            <Chip>Never opened</Chip>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, flex: 1, minHeight: 0, alignContent: 'start' }}>
          {apps.map((a, i) => (
            <div key={i} className={'df-card elevated' + (a.sel ? ' df-sel-ring' : '')}
                 style={{ padding: 14, display: 'flex', flexDirection: 'column', gap: 10,
                          background: a.sel ? 'rgba(77,158,255,0.06)' : 'var(--glass-2)' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                <div style={{ width: 44, height: 44, borderRadius: 10, background: a.grad,
                              display: 'grid', placeItems: 'center', fontWeight: 700, color: '#fff', fontSize: 14,
                              boxShadow: '0 4px 14px rgba(0,0,0,0.3), inset 0 1px 0 rgba(255,255,255,0.2)',
                              flexShrink: 0 }}>{a.init}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--t-1)',
                                overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{a.n}</div>
                  <div className="df-mono" style={{ fontSize: 10, color: 'var(--t-3)', marginTop: 2 }}>v{a.v}</div>
                </div>
                <Check on={a.sel} />
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: 18, fontWeight: 700, letterSpacing: '-0.02em',
                               color: a.sel ? 'var(--blue-hi)' : 'var(--t-1)' }}>{a.s}</span>
                <span style={{ fontSize: 10.5, color: 'var(--t-3)' }}>{a.l}</span>
              </div>

              {a.sel && (
                <div style={{ borderTop: '1px solid var(--line-1)', paddingTop: 8, display: 'flex', flexDirection: 'column', gap: 4 }}>
                  <span className="df-label">Leftover data</span>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 3, fontFamily: 'var(--font-mono)', fontSize: 10.5, color: 'var(--t-2)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>Caches</span><span style={{ color: 'var(--t-1)' }}>220 MB</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>App Support</span><span style={{ color: 'var(--t-1)' }}>1.4 GB</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>Preferences</span><span style={{ color: 'var(--t-1)' }}>4 KB</span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>

        <div className="df-faction">
          <Check on />
          <span style={{ fontSize: 13 }}>2 apps + leftovers</span>
          <span className="df-mono" style={{ fontSize: 18, fontWeight: 700, color: 'var(--blue-hi)' }}>· 11.0 GB</span>
          <div style={{ flex: 1 }}></div>
          <button className="df-btn ghost sm">Clear selection</button>
          <button className="df-btn sm">Keep apps, clean leftovers</button>
          <button className="df-btn primary">{Icon.trash}Uninstall completely</button>
        </div>
      </div>
    </Frame>
  );
}

// ============ SETTINGS ============

function HiFiSettings() {
  const sections = [
    { t: 'Scanning', rows: [
      { l: 'Scan on launch',                        sub: 'Run a quick scan when DiskFlow opens',     r: 'toggle-on' },
      { l: 'Auto-scan schedule',                    sub: 'Background scan to keep data fresh',       r: 'Weekly · Sun 9:00 AM' },
      { l: 'Folders to include',                    sub: 'Limit scans to specific roots',            r: 'Home, Downloads, +2' },
      { l: 'Ignore hidden files',                   sub: 'Skip dotfiles and .DS_Store',              r: 'toggle-off' },
    ]},
    { t: 'Cleanup', rows: [
      { l: 'Safe-delete (Trash, not erase)',        sub: 'Always move to Trash so you can undo',     r: 'toggle-on' },
      { l: 'Confirm before deleting > 1 GB',        sub: 'Extra check on large operations',          r: 'toggle-on' },
      { l: 'Smart pick defaults',                   sub: 'How to choose which duplicate to keep',    r: 'Highest-res · Newest' },
    ]},
    { t: 'Notifications', rows: [
      { l: 'Disk below 20% free',                   sub: 'Alert when free space gets low',           r: 'toggle-on' },
      { l: 'Memory pressure yellow',                sub: 'Notify when swap starts growing',          r: 'toggle-off' },
      { l: 'Weekly cleanup summary',                sub: 'Friday digest of what was cleaned',        r: 'toggle-on' },
    ]},
    { t: 'Advanced', rows: [
      { l: 'Full Disk Access',                      sub: 'Required to scan external drives',         r: 'badge-good' },
      { l: 'Menu bar widget',                       sub: 'Quick storage glance from anywhere',       r: 'toggle-on' },
      { l: 'Send anonymous diagnostics',            sub: 'Help us improve DiskFlow',                 r: 'toggle-off' },
    ]},
  ];

  const Toggle = ({ on }) => (
    <div style={{
      width: 34, height: 20, borderRadius: 10, position: 'relative', flexShrink: 0,
      background: on ? 'linear-gradient(180deg, var(--blue), #3a87f0)' : 'var(--glass-3)',
      border: '1px solid ' + (on ? 'rgba(77,158,255,0.6)' : 'var(--line-2)'),
      boxShadow: on ? '0 2px 8px rgba(77,158,255,0.4), inset 0 1px 0 rgba(255,255,255,0.2)' : 'inset 0 1px 0 rgba(0,0,0,0.2)',
      transition: 'all 200ms',
    }}>
      <div style={{
        position: 'absolute', top: 1, left: on ? 16 : 1,
        width: 16, height: 16, borderRadius: 8,
        background: '#fff',
        boxShadow: '0 1px 2px rgba(0,0,0,0.3)',
        transition: 'left 200ms',
      }}></div>
    </div>
  );

  return (
    <Frame title="Settings" sidebarActive="settings">
      <div className="df-main" style={{ maxWidth: 760, alignSelf: 'center', width: '100%', overflow: 'auto' }}>
        <h1 className="df-h1">Settings</h1>

        {sections.map((sec, i) => (
          <div key={i} style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <h2 className="df-h2" style={{ paddingLeft: 4 }}>{sec.t}</h2>
            <div className="df-card elevated" style={{ padding: 0, overflow: 'hidden' }}>
              {sec.rows.map((r, j) => (
                <div key={j} style={{
                  display: 'flex', alignItems: 'center', gap: 12,
                  padding: '14px 18px',
                  borderBottom: j < sec.rows.length - 1 ? '1px solid var(--line-1)' : 0,
                }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 13, color: 'var(--t-1)', fontWeight: 500 }}>{r.l}</div>
                    <div style={{ fontSize: 11.5, color: 'var(--t-3)', marginTop: 2 }}>{r.sub}</div>
                  </div>
                  {r.r === 'toggle-on'  && <Toggle on={true} />}
                  {r.r === 'toggle-off' && <Toggle on={false} />}
                  {r.r === 'badge-good' && <Chip variant="good"><span className="dot"></span>Granted</Chip>}
                  {r.r !== 'toggle-on' && r.r !== 'toggle-off' && r.r !== 'badge-good' && (
                    <button className="df-btn ghost sm">{r.r}{Icon.chevron}</button>
                  )}
                </div>
              ))}
            </div>
          </div>
        ))}

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 4px 30px' }}>
          <span style={{ fontSize: 11.5, color: 'var(--t-3)', fontFamily: 'var(--font-mono)' }}>DiskFlow 1.2.0 · macOS 15.4 · Apple Silicon</span>
          <div style={{ display: 'flex', gap: 8 }}>
            <button className="df-btn ghost sm">Check for updates</button>
            <button className="df-btn sm">About</button>
          </div>
        </div>
      </div>
    </Frame>
  );
}

// ============ STATES ============

function HiFiEmpty() {
  return (
    <Frame title="Storage Analysis" sidebarActive="analyze">
      <Toolbar actions={<button className="df-btn primary">{Icon.bolt}Start scan</button>}/>
      <div className="df-main" style={{ alignItems: 'center', justifyContent: 'center', padding: 40, gap: 20 }}>
        <div style={{ position: 'relative' }}>
          <div style={{
            width: 120, height: 120, borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(77,158,255,0.2), transparent 70%)',
            filter: 'blur(8px)', position: 'absolute', inset: 0,
          }}></div>
          <div style={{
            position: 'relative', width: 120, height: 120, borderRadius: '50%',
            border: '1.5px dashed rgba(255,255,255,0.15)',
            display: 'grid', placeItems: 'center',
            background: 'linear-gradient(180deg, var(--glass-2), transparent)',
          }}>
            <span style={{ color: 'var(--blue-hi)', transform: 'scale(2.5)' }}>{Icon.disk}</span>
          </div>
        </div>
        <div style={{ textAlign: 'center', maxWidth: 380 }}>
          <h1 className="df-h1">Ready when you are</h1>
          <p className="df-p" style={{ marginTop: 8, fontSize: 13 }}>
            Run your first scan to map storage, find duplicates, and surface cleanup suggestions. Takes about 2 minutes.
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button className="df-btn">Pick folders…</button>
          <button className="df-btn primary">{Icon.bolt}Scan entire Mac</button>
        </div>
        <div style={{ display: 'flex', gap: 16, marginTop: 8, fontSize: 11.5, color: 'var(--t-3)' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>{Icon.shield}Read-only by default</span>
          <span>·</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>{Icon.check}Nothing is deleted automatically</span>
        </div>
      </div>
    </Frame>
  );
}

function HiFiLoading() {
  return (
    <Frame title="Scanning…" sidebarActive="analyze">
      <Toolbar actions={<button className="df-btn ghost sm">Cancel</button>}/>
      <div className="df-main" style={{ alignItems: 'center', justifyContent: 'center', padding: 30, gap: 22 }}>
        {/* animated-feeling concentric spinner */}
        <div style={{ position: 'relative', width: 120, height: 120 }}>
          <svg width="120" height="120" viewBox="0 0 120 120">
            <defs>
              <linearGradient id="ldGrad" x1="0" y1="0" x2="1" y2="0">
                <stop offset="0%" stopColor="#4d9eff" stopOpacity="0"/>
                <stop offset="100%" stopColor="#4d9eff" stopOpacity="1"/>
              </linearGradient>
            </defs>
            <circle cx="60" cy="60" r="52" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="3"/>
            <circle cx="60" cy="60" r="52" fill="none" stroke="url(#ldGrad)" strokeWidth="3"
                    strokeDasharray="220 326" strokeLinecap="round" transform="rotate(-90 60 60)"
                    style={{ filter: 'drop-shadow(0 0 6px rgba(77,158,255,0.6))' }}/>
            <circle cx="60" cy="60" r="40" fill="none" stroke="rgba(255,255,255,0.04)" strokeWidth="2"/>
            <circle cx="60" cy="60" r="40" fill="none" stroke="rgba(93,213,232,0.6)" strokeWidth="2"
                    strokeDasharray="60 251" strokeLinecap="round" transform="rotate(60 60 60)"/>
            <circle cx="60" cy="60" r="28" fill="none" stroke="rgba(155,139,255,0.4)" strokeWidth="2"
                    strokeDasharray="40 176" strokeLinecap="round" transform="rotate(-30 60 60)"/>
          </svg>
          <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center',
                        fontSize: 22, fontWeight: 700, letterSpacing: '-0.02em',
                        color: 'var(--blue-hi)' }}>68%</div>
        </div>

        <div style={{ textAlign: 'center', maxWidth: 380 }}>
          <h1 className="df-h1">Scanning your Mac…</h1>
          <p className="df-p" style={{ marginTop: 6 }}>About 1 minute remaining · 142,840 files indexed so far.</p>
        </div>

        <div style={{ width: 440, display: 'flex', flexDirection: 'column', gap: 6 }}>
          <Bar fill={68} />
          <div className="df-mono" style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10.5, color: 'var(--t-3)' }}>
            <span>~/Library/Caches/com.apple.bird</span>
            <span>68%</span>
          </div>
        </div>

        <div className="df-card elevated" style={{ width: 440, padding: 14, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 14 }}>
          {[
            { l: 'Files indexed', v: '142.8k' },
            { l: 'Duplicate groups', v: '42' },
            { l: 'Reclaimable', v: '12.4 GB' },
          ].map((s, i) => (
            <div key={i}>
              <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.02em', color: 'var(--t-1)' }}>{s.v}</div>
              <div className="df-label" style={{ marginTop: 2 }}>{s.l}</div>
            </div>
          ))}
        </div>
      </div>
    </Frame>
  );
}

function HiFiSuccess() {
  return (
    <Frame title="Cleanup complete" sidebarActive="overview">
      <Toolbar actions={<button className="df-btn primary">{Icon.check}Done</button>}/>
      <div className="df-main" style={{ alignItems: 'center', justifyContent: 'center', padding: 30, gap: 18 }}>
        {/* big check */}
        <div style={{ position: 'relative' }}>
          <div style={{
            position: 'absolute', inset: -20, borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(95,212,154,0.35), transparent 60%)',
            filter: 'blur(12px)',
          }}></div>
          <div style={{
            position: 'relative', width: 96, height: 96, borderRadius: '50%',
            background: 'linear-gradient(180deg, var(--good), #4abf80)',
            display: 'grid', placeItems: 'center',
            boxShadow: '0 12px 40px rgba(95,212,154,0.35), inset 0 1px 0 rgba(255,255,255,0.3)',
          }}>
            <svg width="44" height="44" viewBox="0 0 24 24"><path d="M5 13l4 4L19 7" fill="none" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
          </div>
        </div>

        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 14, color: 'var(--t-3)', marginBottom: 6 }}>Freed</div>
          <div style={{
            fontSize: 56, fontWeight: 700, lineHeight: 1, letterSpacing: '-0.04em',
            background: 'linear-gradient(180deg, #fff, var(--good))',
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
          }}>12.4 GB</div>
          <p className="df-p" style={{ marginTop: 8 }}>3 categories cleaned · 28 seconds</p>
        </div>

        <div style={{ width: 460, display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { l: 'Xcode build caches', v: '6.2 GB',  c: 'var(--cat-cache)' },
            { l: 'Old downloads',      v: '3.8 GB',  c: 'var(--cat-other)' },
            { l: 'Duplicate photos',   v: '2.4 GB',  c: 'var(--cat-photo)' },
          ].map((r, i) => (
            <div key={i} className="df-card elevated" style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 12 }}>
              <span style={{ width: 22, height: 22, borderRadius: 11, background: 'rgba(95,212,154,0.15)',
                             border: '1px solid var(--good)', display: 'grid', placeItems: 'center', color: 'var(--good)' }}>
                <svg width="12" height="12" viewBox="0 0 24 24"><path d="M5 13l4 4L19 7" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
              </span>
              <span style={{ flex: 1, fontSize: 13, color: 'var(--t-1)' }}>{r.l}</span>
              <span className="df-mono" style={{ fontSize: 15, fontWeight: 600, color: r.c }}>{r.v}</span>
            </div>
          ))}
        </div>

        <div className="df-card" style={{ width: 460, padding: 14, display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ flex: 1 }}>
            <div className="df-label">Health score</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 2 }}>
              <span style={{ fontSize: 22, fontWeight: 700 }}>82</span>
              <svg width="14" height="14" viewBox="0 0 24 24"><path d="M5 12h14M13 5l7 7-7 7" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
              <span style={{ fontSize: 22, fontWeight: 700, color: 'var(--good)' }}>94</span>
              <span style={{ marginLeft: 8, fontSize: 11.5, color: 'var(--good)' }}>+12 improvement</span>
            </div>
          </div>
          <button className="df-btn ghost sm">View what changed</button>
        </div>
      </div>
    </Frame>
  );
}

function HiFiError() {
  return (
    <Frame title="External Drives" sidebarActive="drives">
      <Toolbar actions={<button className="df-btn ghost sm">{Icon.refresh}Retry</button>}/>
      <div className="df-main" style={{ alignItems: 'center', justifyContent: 'center', padding: 30, gap: 18 }}>
        <div style={{ position: 'relative' }}>
          <div style={{ position: 'absolute', inset: -20, borderRadius: '50%',
                        background: 'radial-gradient(circle, rgba(255,180,92,0.25), transparent 60%)', filter: 'blur(12px)' }}></div>
          <div style={{ position: 'relative', width: 88, height: 88, borderRadius: 20,
                        background: 'linear-gradient(180deg, rgba(255,180,92,0.15), rgba(255,180,92,0.05))',
                        border: '1px solid rgba(255,180,92,0.4)',
                        display: 'grid', placeItems: 'center',
                        boxShadow: '0 12px 40px rgba(255,180,92,0.2)' }}>
            <span style={{ transform: 'scale(2)', color: 'var(--warn)' }}>{Icon.shield}</span>
          </div>
        </div>

        <div style={{ textAlign: 'center', maxWidth: 420 }}>
          <h1 className="df-h1">Permission needed</h1>
          <p className="df-p" style={{ marginTop: 8, fontSize: 13 }}>
            DiskFlow needs <b style={{ color: 'var(--t-1)' }}>Full Disk Access</b> to scan external drives.
            Grant access in System Settings, then retry.
          </p>
        </div>

        <div style={{ display: 'flex', gap: 10 }}>
          <button className="df-btn ghost sm">Learn more</button>
          <button className="df-btn primary">Open System Settings{Icon.arrow}</button>
        </div>

        <div className="df-card elevated" style={{ width: 480, padding: 0 }}>
          <div style={{ padding: '10px 16px', borderBottom: '1px solid var(--line-1)' }}>
            <span className="df-label">Connected drives</span>
          </div>
          {[
            { n: 'Macintosh HD',  s: '312 / 512 GB', ok: true },
            { n: 'Backup-SSD',    s: 'Locked — needs Full Disk Access',     ok: false },
            { n: 'Time Machine',  s: '1.8 / 4 TB',   ok: true },
          ].map((d, i) => (
            <div key={i} style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 12,
                                  borderBottom: i < 2 ? '1px solid var(--line-1)' : 0 }}>
              <span style={{ color: d.ok ? 'var(--blue-hi)' : 'var(--warn)' }}>{Icon.drive}</span>
              <span style={{ flex: 1, fontSize: 13, color: 'var(--t-1)' }}>{d.n}</span>
              <span className="df-mono" style={{ fontSize: 11.5, color: d.ok ? 'var(--t-3)' : 'var(--warn)' }}>{d.s}</span>
            </div>
          ))}
        </div>
      </div>
    </Frame>
  );
}

Object.assign(window, {
  HiFiMemory, HiFiApps, HiFiSettings,
  HiFiEmpty, HiFiLoading, HiFiSuccess, HiFiError,
});
