/* Hi-fi: Storage Analyzer · Large Files · Duplicates */

// ============ STORAGE ANALYZER (sunburst) ============

function HiFiAnalyzer() {
  // sunburst geometry
  const cx = 0, cy = 0;
  const ringA = { r1: 50, r2: 100 };
  const ringB = { r1: 102, r2: 150 };

  const cats = [
    { from: 0,   to: 80,  fill: 'url(#gApps)',   stroke: 'rgba(77,158,255,0.6)',  label: 'Apps' },
    { from: 80,  to: 132, fill: 'url(#gDocs)',   stroke: 'rgba(155,139,255,0.6)', label: 'Docs' },
    { from: 132, to: 168, fill: 'url(#gVideo)',  stroke: 'rgba(210,135,255,0.6)', label: 'Video' },
    { from: 168, to: 198, fill: 'url(#gPhoto)',  stroke: 'rgba(255,142,177,0.6)', label: 'Photo' },
    { from: 198, to: 224, fill: 'url(#gSystem)', stroke: 'rgba(93,213,232,0.6)',  label: 'System' },
    { from: 224, to: 240, fill: 'url(#gCache)',  stroke: 'rgba(255,180,92,0.6)',  label: 'Cache' },
  ];

  const apps = [
    { from: 0, to: 24, label: 'Xcode',    pct: 30, fill: 'rgba(77,158,255,0.55)' },
    { from: 24, to: 40, label: 'Logic',   pct: 20, fill: 'rgba(77,158,255,0.45)' },
    { from: 40, to: 60, label: 'Adobe',   pct: 25, fill: 'rgba(77,158,255,0.6)' },
    { from: 60, to: 80, label: 'Others',  pct: 25, fill: 'rgba(77,158,255,0.35)' },
  ];
  const docs = [
    { from: 80, to: 102, label: 'Projects', fill: 'rgba(155,139,255,0.55)' },
    { from: 102, to: 132, label: 'Archive', fill: 'rgba(155,139,255,0.4)' },
  ];

  const arc = (a1, a2, r1, r2) => {
    const A1 = (a1 - 90) * Math.PI / 180;
    const A2 = (a2 - 90) * Math.PI / 180;
    const large = a2 - a1 > 180 ? 1 : 0;
    return `M ${Math.cos(A1)*r1} ${Math.sin(A1)*r1} L ${Math.cos(A1)*r2} ${Math.sin(A1)*r2} A ${r2} ${r2} 0 ${large} 1 ${Math.cos(A2)*r2} ${Math.sin(A2)*r2} L ${Math.cos(A2)*r1} ${Math.sin(A2)*r1} A ${r1} ${r1} 0 ${large} 0 ${Math.cos(A1)*r1} ${Math.sin(A1)*r1} Z`;
  };

  return (
    <Frame title="Storage Analysis" sidebarActive="analyze">
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost sm">{Icon.filter}Filter</button>
            <button className="df-btn">{Icon.refresh}Rescan</button>
          </>
        }
      />
      <div className="df-main">
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
          <div>
            <h1 className="df-h1">Where did it all go?</h1>
            <p className="df-p" style={{ marginTop: 4 }}>Drill into any slice to see the folders behind it.</p>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <Chip>Macintosh HD</Chip>
            <Chip>{Icon.chevron}/Users/alex</Chip>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 16, flex: 1, minHeight: 0 }}>
          {/* sunburst card */}
          <div className="df-card elevated" style={{ display: 'grid', placeItems: 'center', position: 'relative', overflow: 'hidden', padding: 18 }}>
            <div style={{
              position: 'absolute', inset: 0,
              background: 'radial-gradient(circle at 50% 50%, rgba(77,158,255,0.18), transparent 60%)',
              pointerEvents: 'none',
            }}></div>

            <svg viewBox="-180 -180 360 360" style={{ width: '100%', maxWidth: 460, height: 'auto', filter: 'drop-shadow(0 8px 32px rgba(77,158,255,0.25))' }}>
              <defs>
                <radialGradient id="gApps"   cx="0.3" cy="0.3"><stop offset="0%" stopColor="#6fb3ff"/><stop offset="100%" stopColor="#3a78e0"/></radialGradient>
                <radialGradient id="gDocs"   cx="0.3" cy="0.3"><stop offset="0%" stopColor="#b3a4ff"/><stop offset="100%" stopColor="#6f5ee0"/></radialGradient>
                <radialGradient id="gVideo"  cx="0.3" cy="0.3"><stop offset="0%" stopColor="#e2a8ff"/><stop offset="100%" stopColor="#a060d0"/></radialGradient>
                <radialGradient id="gPhoto"  cx="0.3" cy="0.3"><stop offset="0%" stopColor="#ffa8c4"/><stop offset="100%" stopColor="#d05a85"/></radialGradient>
                <radialGradient id="gSystem" cx="0.3" cy="0.3"><stop offset="0%" stopColor="#86e7f5"/><stop offset="100%" stopColor="#3aa8c0"/></radialGradient>
                <radialGradient id="gCache"  cx="0.3" cy="0.3"><stop offset="0%" stopColor="#ffcd8a"/><stop offset="100%" stopColor="#d08a3a"/></radialGradient>
              </defs>

              {/* center disc */}
              <circle r="46" fill="rgba(20,24,34,0.85)" stroke="rgba(255,255,255,0.15)" strokeWidth="1"/>
              <text textAnchor="middle" y="-4" style={{ font: '700 19px var(--font-ui)', fill: '#f0f3f8', letterSpacing: '-0.02em' }}>312 GB</text>
              <text textAnchor="middle" y="14" style={{ font: '500 10px var(--font-ui)', fill: '#7a8497', letterSpacing: '0.05em', textTransform: 'uppercase' }}>used</text>

              {/* ring A — categories */}
              {cats.map((s, i) => (
                <path key={i} d={arc(s.from, s.to, ringA.r1, ringA.r2)} fill={s.fill} stroke={s.stroke} strokeWidth="1" />
              ))}
              {/* ring A labels (only large ones) */}
              {cats.filter(c => c.to - c.from > 30).map((s, i) => {
                const mid = (s.from + s.to) / 2;
                const a = (mid - 90) * Math.PI / 180;
                const r = (ringA.r1 + ringA.r2) / 2;
                return (
                  <text key={i} x={Math.cos(a) * r} y={Math.sin(a) * r}
                        textAnchor="middle" dominantBaseline="middle"
                        style={{ font: '600 10px var(--font-ui)', fill: '#fff', letterSpacing: '0.05em' }}>
                    {s.label}
                  </text>
                );
              })}

              {/* ring B — apps subcats */}
              {apps.map((s, i) => (
                <path key={'a' + i} d={arc(s.from, s.to, ringB.r1, ringB.r2)} fill={s.fill}
                      stroke="rgba(255,255,255,0.08)" strokeWidth="0.6" />
              ))}
              {docs.map((s, i) => (
                <path key={'d' + i} d={arc(s.from, s.to, ringB.r1, ringB.r2)} fill={s.fill}
                      stroke="rgba(255,255,255,0.08)" strokeWidth="0.6" />
              ))}
              {/* remaining ring B faint */}
              {[
                { from: 132, to: 168, fill: 'rgba(210,135,255,0.4)' },
                { from: 168, to: 198, fill: 'rgba(255,142,177,0.4)' },
                { from: 198, to: 224, fill: 'rgba(93,213,232,0.4)' },
                { from: 224, to: 240, fill: 'rgba(255,180,92,0.4)' },
              ].map((s, i) => (
                <path key={'o' + i} d={arc(s.from, s.to, ringB.r1, ringB.r2)} fill={s.fill}
                      stroke="rgba(255,255,255,0.08)" strokeWidth="0.6" />
              ))}

              {/* selected slice highlight */}
              <path d={arc(0, 24, ringB.r1, ringB.r2 + 8)} fill="none" stroke="#fff" strokeWidth="2" opacity="0.95"/>
            </svg>

            {/* legend strip */}
            <div style={{ display: 'flex', gap: 14, marginTop: 16, flexWrap: 'wrap', justifyContent: 'center' }}>
              {[
                { c: 'var(--cat-apps)', l: 'Apps' },
                { c: 'var(--cat-docs)', l: 'Docs' },
                { c: 'var(--cat-video)', l: 'Video' },
                { c: 'var(--cat-photo)', l: 'Photo' },
                { c: 'var(--cat-system)', l: 'System' },
                { c: 'var(--cat-cache)', l: 'Cache' },
              ].map((x, i) => (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11.5, color: 'var(--t-2)' }}>
                  <span style={{ width: 8, height: 8, borderRadius: 2, background: x.c, boxShadow: `0 0 8px ${x.c}80` }}></span>
                  {x.l}
                </div>
              ))}
            </div>
          </div>

          {/* detail panel */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12, minHeight: 0 }}>
            <div className="df-card elevated" style={{ padding: 18, display: 'flex', flexDirection: 'column', gap: 12, flex: 1, minHeight: 0 }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, color: 'var(--t-3)', fontFamily: 'var(--font-mono)' }}>
                  <span>Apps</span><span>›</span><span style={{ color: 'var(--blue-hi)' }}>Xcode</span>
                </div>
                <h2 className="df-h2" style={{ marginTop: 4, display: 'flex', alignItems: 'baseline', gap: 8 }}>
                  Xcode
                  <span style={{ fontSize: 20, fontWeight: 700, color: 'var(--blue-hi)', letterSpacing: '-0.02em' }}>20.4 GB</span>
                  <span style={{ fontSize: 11, color: 'var(--t-3)', fontWeight: 400 }}>· 30% of Apps</span>
                </h2>
              </div>

              <div className="df-divider"></div>

              <div className="df-label">Breakdown</div>
              {[
                { n: 'DerivedData',  s: '6.2 GB', f: 30, c: 'var(--cat-cache)', tag: 'Cleanable' },
                { n: 'iOS Simulator', s: '5.8 GB', f: 28, c: 'var(--blue)' },
                { n: 'Archives',     s: '3.1 GB', f: 15, c: 'var(--blue)' },
                { n: 'App binary',   s: '2.4 GB', f: 12, c: 'var(--blue)' },
                { n: 'Other',        s: '2.9 GB', f: 15, c: 'var(--cat-other)' },
              ].map((r, i) => (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <span style={{ width: 8, height: 8, borderRadius: 2, background: r.c, boxShadow: `0 0 6px ${r.c}80` }}></span>
                  <span style={{ flex: 1, fontSize: 12.5 }}>{r.n}</span>
                  {r.tag && <Chip variant="warn">{r.tag}</Chip>}
                  <span className="df-mono" style={{ fontSize: 12.5, color: 'var(--t-1)', minWidth: 56, textAlign: 'right' }}>{r.s}</span>
                </div>
              ))}

              <div style={{ marginTop: 'auto', display: 'flex', gap: 8 }}>
                <button className="df-btn ghost sm" style={{ flex: 1, justifyContent: 'center' }}>{Icon.reveal}Reveal</button>
                <button className="df-btn primary sm" style={{ flex: 1, justifyContent: 'center' }}>{Icon.bolt}Clean 6.2 GB</button>
              </div>
            </div>

            {/* mini insight */}
            <div className="df-card" style={{ padding: 14, display: 'flex', alignItems: 'center', gap: 12 }}>
              <span style={{ color: 'var(--blue-hi)' }}>{Icon.sparkle}</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, color: 'var(--t-1)', fontWeight: 500 }}>Insight</div>
                <div style={{ fontSize: 11.5, color: 'var(--t-3)' }}>Xcode caches grew by 6.2 GB this month.</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Frame>
  );
}

// ============ LARGE FILES ============

function HiFiLargeFiles() {
  const rows = [
    { n: 'WWDC25-Keynote.mp4',           p: '~/Movies',                    s: '8.4 GB', a: '14 days ago',  t: 'video',   sel: true },
    { n: 'Xcode_15.4.xip',               p: '~/Downloads',                 s: '7.2 GB', a: '3 months ago', t: 'archive', sel: true },
    { n: 'final-cut-project.fcpbundle',  p: '~/Movies/FCP',                s: '6.1 GB', a: '2 days ago',   t: 'folder' },
    { n: 'ubuntu-24.04.iso',             p: '~/Downloads',                 s: '4.8 GB', a: '5 months ago', t: 'image' },
    { n: 'wedding-raw-2023.zip',         p: '~/Documents/Backups',         s: '4.2 GB', a: '1 year ago',   t: 'archive' },
    { n: 'screen-recording.mov',         p: '~/Desktop',                   s: '3.8 GB', a: '8 days ago',   t: 'video',   sel: true },
    { n: 'DerivedData',                  p: '~/Library/Developer/Xcode',   s: '3.2 GB', a: '2 hours ago',  t: 'cache' },
    { n: 'sample-dataset.parquet',       p: '~/Code/ml-prototype',         s: '2.8 GB', a: '4 months ago', t: 'data' },
    { n: 'iPad-backup.zip',              p: '~/Downloads',                 s: '2.4 GB', a: '2 months ago', t: 'archive' },
  ];

  const ext = (t) => ({ video: 'MP4', archive: 'ZIP', folder: 'DIR', image: 'ISO', cache: 'TMP', data: 'PRQ' }[t] || 'FIL');

  return (
    <Frame title="Large Files" sidebarActive="large">
      <Toolbar
        search="Filter by name, path, type…"
        actions={
          <>
            <button className="df-btn ghost sm">{Icon.filter}Filter</button>
            <button className="df-btn">{Icon.archive}Archive</button>
            <button className="df-btn primary">{Icon.trash}Move to Trash</button>
          </>
        }
      />
      <div className="df-main" style={{ flexDirection: 'row', padding: 0, gap: 0 }}>
        {/* main panel */}
        <div style={{ flex: 1, padding: 22, display: 'flex', flexDirection: 'column', gap: 16, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 16 }}>
            <div>
              <h1 className="df-h1">Large files</h1>
              <p className="df-p" style={{ marginTop: 4 }}>128 files over 100 MB · 142.8 GB total</p>
            </div>
            <div style={{ display: 'flex', gap: 6 }}>
              {['All', 'Video', 'Archive', 'Image', 'Folder', 'Other'].map((t, i) => (
                <Chip key={t} active={i === 0}>{t}</Chip>
              ))}
            </div>
          </div>

          {/* table */}
          <div className="df-card elevated" style={{ padding: 0, flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0, overflow: 'hidden' }}>
            <div className="df-row head" style={{ gridTemplateColumns: '32px 44px 1fr 110px 130px 100px 32px' }}>
              <span></span>
              <span></span>
              <span>Name · Path</span>
              <span>Size</span>
              <span>Last opened</span>
              <span>Type</span>
              <span></span>
            </div>
            <div style={{ flex: 1, overflow: 'hidden' }}>
              {rows.map((r, i) => (
                <div key={i} className={'df-row ' + (r.sel ? 'selected' : '')}
                     style={{ gridTemplateColumns: '32px 44px 1fr 110px 130px 100px 32px' }}>
                  <Check on={r.sel} />
                  <div className={'df-glyph ' + r.t}>{ext(r.t)}</div>
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
          </div>

          {/* batch bar */}
          <div className="df-faction">
            <Check on />
            <span style={{ fontSize: 13, fontWeight: 500 }}>3 files selected</span>
            <span className="df-mono" style={{ fontSize: 18, fontWeight: 700, color: 'var(--blue-hi)' }}>· 19.4 GB</span>
            <div style={{ flex: 1 }}></div>
            <button className="df-btn ghost sm">Clear</button>
            <button className="df-btn sm">{Icon.reveal}Reveal</button>
            <button className="df-btn sm">{Icon.archive}Archive</button>
            <button className="df-btn danger sm">{Icon.trash}Trash</button>
          </div>
        </div>

        {/* preview pane */}
        <div style={{ width: 280, borderLeft: '1px solid var(--line-1)', padding: 18, display: 'flex', flexDirection: 'column', gap: 12,
                      background: 'rgba(7,9,13,0.4)', backdropFilter: 'blur(20px)' }}>
          <span className="df-label">Preview</span>
          <div style={{ aspectRatio: '16/10', borderRadius: 'var(--r-lg)', overflow: 'hidden', position: 'relative',
                        background: 'linear-gradient(135deg, #1a2030, #0e131c)', border: '1px solid var(--line-2)',
                        display: 'grid', placeItems: 'center' }}>
            <span style={{ color: '#fff', opacity: 0.5 }}>{Icon.play}</span>
            <div style={{ position: 'absolute', bottom: 8, right: 8, fontSize: 10, fontFamily: 'var(--font-mono)',
                          background: 'rgba(0,0,0,0.5)', padding: '2px 6px', borderRadius: 4, color: '#fff' }}>
              1:52:14
            </div>
          </div>

          <div>
            <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--t-1)' }}>WWDC25-Keynote.mp4</div>
            <div className="df-mono" style={{ fontSize: 10.5, color: 'var(--t-3)', marginTop: 2 }}>~/Movies/WWDC25/</div>
          </div>

          <div className="df-divider"></div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, fontSize: 12 }}>
            {[
              ['Size', '8.4 GB'],
              ['Type', 'H.264 video'],
              ['Resolution', '3840 × 2160'],
              ['Duration', '1h 52m'],
              ['Last opened', '14 days ago'],
              ['Created', 'Jun 10, 2025'],
            ].map((row, i) => (
              <div key={i} style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--t-3)' }}>{row[0]}</span>
                <span style={{ color: 'var(--t-1)', fontWeight: 500 }}>{row[1]}</span>
              </div>
            ))}
          </div>

          <div className="df-divider"></div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            <button className="df-btn sm" style={{ justifyContent: 'center' }}>{Icon.play}Open</button>
            <button className="df-btn sm" style={{ justifyContent: 'center' }}>{Icon.archive}Archive externally</button>
            <button className="df-btn danger sm" style={{ justifyContent: 'center' }}>{Icon.trash}Move to Trash</button>
          </div>
        </div>
      </div>
    </Frame>
  );
}

// ============ DUPLICATES ============

function HiFiDuplicates() {
  const groups = [
    { n: 'IMG_8421.HEIC',         c: 4, s: '480 MB',  active: true },
    { n: 'tax-return-2024.pdf',   c: 3, s: '12.4 MB' },
    { n: 'screencast-final.mov',  c: 2, s: '1.2 GB' },
    { n: 'logo-v3.psd',           c: 5, s: '88 MB' },
    { n: 'song-demo.wav',         c: 2, s: '210 MB' },
    { n: 'resume.docx',           c: 4, s: '4.2 MB' },
    { n: 'presentation.key',      c: 2, s: '320 MB' },
    { n: 'IMG_3392.HEIC',         c: 3, s: '12.8 MB' },
  ];

  return (
    <Frame title="Duplicates" sidebarActive="dupes">
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost sm">{Icon.sparkle}Auto-pick all</button>
            <button className="df-btn primary">{Icon.trash}Clean 4.8 GB</button>
          </>
        }
      />
      <div className="df-main">
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 16 }}>
          <div>
            <h1 className="df-h1">42 duplicate groups</h1>
            <p className="df-p" style={{ marginTop: 4 }}>
              <b style={{ color: 'var(--blue-hi)' }}>4.8 GB</b> recoverable · matched by content hash + perceptual similarity.
            </p>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            {['All', 'Images', 'Docs', 'Audio', 'Video'].map((t, i) => (
              <Chip key={t} active={i === 1}>{t}</Chip>
            ))}
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '260px 1fr', gap: 16, flex: 1, minHeight: 0 }}>
          {/* group list */}
          <div className="df-card elevated" style={{ padding: 0, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
            <div style={{ padding: '12px 14px', borderBottom: '1px solid var(--line-1)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span className="df-label">42 groups</span>
              <span className="df-label" style={{ color: 'var(--t-3)' }}>by size ↓</span>
            </div>
            <div style={{ flex: 1, overflow: 'hidden' }}>
              {groups.map((g, i) => (
                <div key={i} style={{
                  padding: '10px 14px',
                  borderBottom: '1px solid var(--line-1)',
                  background: g.active ? 'rgba(77,158,255,0.10)' : 'transparent',
                  borderLeft: g.active ? '2px solid var(--blue)' : '2px solid transparent',
                  display: 'flex', flexDirection: 'column', gap: 4,
                }}>
                  <div style={{ fontSize: 12.5, color: 'var(--t-1)', fontWeight: g.active ? 600 : 500,
                                overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{g.n}</div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10.5, color: 'var(--t-3)' }}>
                    <span>{g.c} copies</span>
                    <span className="df-mono">{g.s}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* compare panel */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12, minHeight: 0 }}>
            <div className="df-card elevated" style={{ padding: 18, display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <h2 className="df-h2">IMG_8421.HEIC</h2>
                  <p className="df-p" style={{ marginTop: 2 }}>4 copies · perceptual match 99.7% · 480 MB total</p>
                </div>
                <span className="df-chip good"><span className="dot"></span>{Icon.sparkle}Smart pick ready</span>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr auto 1fr 1fr 1fr', gap: 12, alignItems: 'stretch' }}>
                {/* keep card */}
                <div style={{
                  borderRadius: 'var(--r-lg)', padding: 10, position: 'relative',
                  background: 'linear-gradient(180deg, rgba(95,212,154,0.12), rgba(95,212,154,0.04))',
                  border: '1px solid rgba(95,212,154,0.35)',
                  display: 'flex', flexDirection: 'column', gap: 8,
                  boxShadow: '0 0 24px rgba(95,212,154,0.15)',
                }}>
                  <div style={{ position: 'absolute', top: 8, right: 8 }}>
                    <Chip variant="good">{Icon.check}Keep</Chip>
                  </div>
                  <div style={{ aspectRatio: '4/3', borderRadius: 8, border: '1px solid var(--line-2)',
                                background: 'linear-gradient(135deg, #d287ff20, #4d9eff20)', display: 'grid', placeItems: 'center',
                                fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--t-3)' }}>4032 × 3024</div>
                  <div style={{ fontSize: 12, fontWeight: 600 }}>IMG_8421.HEIC</div>
                  <div className="df-mono" style={{ fontSize: 10, color: 'var(--t-3)' }}>~/Pictures/Photos Library</div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10.5, color: 'var(--t-3)' }}>
                    <span>4.2 MB</span>
                    <span style={{ color: 'var(--good)' }}>newest, highest-res</span>
                  </div>
                </div>

                <div style={{ display: 'grid', placeItems: 'center', fontSize: 11, color: 'var(--t-3)', fontWeight: 600 }}>VS</div>

                {[
                  { n: 'IMG_8421.jpg',       p: '~/Downloads/from-iphone/', s: '0.8 MB',  d: '1920 × 1440', meta: 'lower-res copy' },
                  { n: 'IMG_8421 (2).HEIC',  p: '~/Desktop/old/',           s: '4.1 MB',  d: '4032 × 3024', meta: 'older duplicate' },
                  { n: 'IMG_8421-edit.jpg',  p: '~/iCloud Drive/Camera/',    s: '1.2 MB',  d: '2880 × 2160', meta: 'lower-res edit' },
                ].map((c, i) => (
                  <div key={i} style={{
                    borderRadius: 'var(--r-lg)', padding: 10,
                    background: 'rgba(255,107,125,0.05)',
                    border: '1px solid rgba(255,107,125,0.2)',
                    display: 'flex', flexDirection: 'column', gap: 8,
                    position: 'relative',
                  }}>
                    <div style={{ position: 'absolute', top: 8, right: 8 }}>
                      <Chip variant="danger">{Icon.trash}Delete</Chip>
                    </div>
                    <div style={{ aspectRatio: '4/3', borderRadius: 8, border: '1px solid var(--line-2)',
                                  background: 'linear-gradient(135deg, #d287ff20, #4d9eff20)', display: 'grid', placeItems: 'center',
                                  fontFamily: 'var(--font-mono)', fontSize: 9.5, color: 'var(--t-3)' }}>{c.d}</div>
                    <div style={{ fontSize: 11.5, fontWeight: 500, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{c.n}</div>
                    <div className="df-mono" style={{ fontSize: 9.5, color: 'var(--t-3)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{c.p}</div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: 'var(--t-3)' }}>
                      <span>{c.s}</span>
                      <span style={{ color: 'var(--danger)' }}>{c.meta}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="df-faction">
              <span style={{ fontSize: 13 }}>Group cleanup</span>
              <span className="df-mono" style={{ fontSize: 14, fontWeight: 600, color: 'var(--good)' }}>·  keep 1, delete 3  ·  save 6.1 MB</span>
              <div style={{ flex: 1 }}></div>
              <button className="df-btn ghost sm">Skip</button>
              <button className="df-btn sm">Customize</button>
              <button className="df-btn primary">{Icon.sparkle}Apply smart pick</button>
            </div>
          </div>
        </div>
      </div>
    </Frame>
  );
}

Object.assign(window, { HiFiAnalyzer, HiFiLargeFiles, HiFiDuplicates });
