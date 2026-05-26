/* Hi-fi Dashboard */

function HiFiDashboard() {
  return (
    <Frame title="DiskFlow" sidebarActive="overview">
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost">Rescan</button>
            <button className="df-btn primary">{Icon.sparkle}Clean 12.4 GB</button>
          </>
        }
      />
      <div className="df-main">
        {/* greeting strip */}
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 16 }}>
          <div>
            <h1 className="df-h1">Good morning, Alex</h1>
            <p className="df-p" style={{ marginTop: 4 }}>
              MacBook Pro 14" · last scan 2 hours ago · 142,840 files indexed
            </p>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <Chip>Macintosh HD</Chip>
            <Chip variant="good"><span className="dot"></span>Healthy · 82</Chip>
          </div>
        </div>

        {/* main grid */}
        <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: 16, minHeight: 0 }}>
          {/* donut card */}
          <div className="df-card elevated" style={{ display: 'flex', alignItems: 'center', gap: 24, padding: 24, position: 'relative', overflow: 'hidden' }}>
            {/* glow blob */}
            <div style={{
              position: 'absolute', top: -60, left: -60, width: 280, height: 280, borderRadius: '50%',
              background: 'radial-gradient(circle, rgba(77,158,255,0.25), transparent 70%)',
              filter: 'blur(20px)', pointerEvents: 'none',
            }}></div>

            <Donut
              size={220}
              stroke={26}
              segments={[
                { pct: 22, color: 'var(--cat-apps)' },
                { pct: 14, color: 'var(--cat-docs)' },
                { pct: 10, color: 'var(--cat-video)' },
                { pct: 8,  color: 'var(--cat-photo)' },
                { pct: 7,  color: 'var(--cat-system)' },
                { pct: 4,  color: 'var(--cat-cache)' },
              ]}
              label="312 GB"
              sub="of 512 GB used"
            />

            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 6 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                <h2 className="df-h2">Storage breakdown</h2>
                <span className="df-label">7 categories</span>
              </div>
              <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 10 }}>
                {[
                  { label: 'Applications', size: '68.2 GB', pct: 22, color: 'var(--cat-apps)' },
                  { label: 'Documents',    size: '42.1 GB', pct: 14, color: 'var(--cat-docs)' },
                  { label: 'Videos',       size: '31.4 GB', pct: 10, color: 'var(--cat-video)' },
                  { label: 'Photos',       size: '26.0 GB', pct: 8,  color: 'var(--cat-photo)' },
                  { label: 'System',       size: '22.6 GB', pct: 7,  color: 'var(--cat-system)' },
                  { label: 'Cache + Misc', size: '12.1 GB', pct: 4,  color: 'var(--cat-cache)' },
                ].map((c, i) => (
                  <div key={i} style={{ display: 'grid', gridTemplateColumns: '10px 1fr 70px 36px', alignItems: 'center', gap: 10 }}>
                    <span style={{ width: 10, height: 10, borderRadius: 3, background: c.color, boxShadow: `0 0 10px ${c.color}80` }}></span>
                    <span style={{ fontSize: 12.5, color: 'var(--t-1)' }}>{c.label}</span>
                    <span className="df-mono" style={{ fontSize: 12, color: 'var(--t-2)', textAlign: 'right' }}>{c.size}</span>
                    <span className="df-mono" style={{ fontSize: 11, color: 'var(--t-3)', textAlign: 'right' }}>{c.pct}%</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* right column stack */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16, minWidth: 0 }}>
            {/* health score */}
            <div className="df-card glow-blue" style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span className="df-label">System Health</span>
                <span className="df-chip good"><span className="dot"></span>Healthy</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                <div style={{
                  fontSize: 64, lineHeight: 1, fontWeight: 700, letterSpacing: '-0.04em',
                  background: 'linear-gradient(180deg, #fff, var(--blue-hi) 60%, var(--cyan))',
                  WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
                }}>82</div>
                <div style={{ fontSize: 18, color: 'var(--t-3)', fontWeight: 500 }}>/ 100</div>
                <div style={{ marginLeft: 'auto', fontSize: 11, color: 'var(--good)', display: 'flex', alignItems: 'center', gap: 4 }}>
                  <svg width="10" height="10" viewBox="0 0 10 10"><path d="M5 1l4 5H1z" fill="currentColor"/></svg>
                  +6 this week
                </div>
              </div>
              <Bar fill={82} variant="good" />
              <p className="df-p">3 quick wins available — could free <b style={{ color: 'var(--t-1)' }}>12.4 GB</b> in under 30 seconds.</p>
              <button className="df-btn primary" style={{ width: '100%', justifyContent: 'center', height: 36 }}>
                {Icon.bolt}Run smart cleanup
              </button>
            </div>

            {/* memory mini */}
            <div className="df-card" style={{ padding: 16 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
                <span className="df-label">Memory pressure</span>
                <span className="df-chip warn"><span className="dot"></span>Yellow</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginBottom: 8 }}>
                <span style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.02em' }}>12.4</span>
                <span style={{ fontSize: 13, color: 'var(--t-3)' }}>/ 16 GB</span>
                <span style={{ marginLeft: 'auto', fontSize: 11, color: 'var(--t-3)' }}>78% in use</span>
              </div>
              <Bar fill={78} variant="warn" />
            </div>
          </div>
        </div>

        {/* smart suggestions */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, minHeight: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div>
              <h2 className="df-h2" style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                <span style={{ color: 'var(--blue-hi)' }}>{Icon.sparkle}</span>
                Smart cleanup
              </h2>
              <span className="df-p" style={{ marginLeft: 8 }}>· 3 recommendations · 12.4 GB total</span>
            </div>
            <button className="df-btn ghost sm">View all</button>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12 }}>
            {[
              { glyph: 'cache', tag: 'Caches', t: 'Xcode build cache', s: '6.2 GB',
                d: 'DerivedData from 14 old projects — rebuilt automatically when needed.',
                color: 'var(--cat-cache)' },
              { glyph: 'folder', tag: 'Downloads', t: 'Old downloads', s: '3.8 GB',
                d: '42 files older than 90 days · installers, ISOs, archives.',
                color: 'var(--cat-other)' },
              { glyph: 'image', tag: 'Photos', t: 'Duplicate photos', s: '2.4 GB',
                d: '128 likely duplicates across iCloud and Pictures.',
                color: 'var(--cat-photo)' },
            ].map((c, i) => (
              <div key={i} className="df-card elevated" style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 10 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <div className={'df-glyph ' + c.glyph} style={{ width: 36, height: 36 }}>{c.tag.slice(0, 3).toUpperCase()}</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 10.5, color: 'var(--t-4)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>{c.tag}</div>
                    <div style={{ fontSize: 13.5, fontWeight: 600, color: 'var(--t-1)' }}>{c.t}</div>
                  </div>
                  <div style={{ fontSize: 16, fontWeight: 700, color: c.color, letterSpacing: '-0.01em' }}>{c.s}</div>
                </div>
                <p className="df-p" style={{ fontSize: 12 }}>{c.d}</p>
                <div style={{ display: 'flex', gap: 6, marginTop: 'auto' }}>
                  <button className="df-btn sm" style={{ flex: 1, justifyContent: 'center' }}>Review</button>
                  <button className="df-btn ghost sm">Skip</button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Frame>
  );
}

Object.assign(window, { HiFiDashboard });
