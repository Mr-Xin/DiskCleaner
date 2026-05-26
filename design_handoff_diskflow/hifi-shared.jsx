/* Hi-fi shared chrome — Frame, Sidebar, Toolbar, icons, primitives */

// === SVG ICONS (Lucide-style monoline, 18×18) ===
const Icon = {
  grid:    <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>,
  disk:    <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="3"/></svg>,
  doc:     <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/></svg>,
  copy:    <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>,
  apps:    <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="7" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/><circle cx="17.5" cy="17.5" r="3.5"/></svg>,
  cpu:     <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="6" y="6" width="12" height="12" rx="2"/><path d="M9 2v4M15 2v4M9 18v4M15 18v4M2 9h4M2 15h4M18 9h4M18 15h4"/></svg>,
  drive:   <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="14" width="20" height="6" rx="2"/><rect x="2" y="4" width="20" height="6" rx="2"/><path d="M6 7h.01M6 17h.01"/></svg>,
  settings:<svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33h0a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51h0a1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82v0a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>,
  search:  <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></svg>,
  bolt:    <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>,
  sparkle: <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.1 2.1M16.3 16.3l2.1 2.1M5.6 18.4l2.1-2.1M16.3 7.7l2.1-2.1"/></svg>,
  arrow:   <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14M13 5l7 7-7 7"/></svg>,
  check:   <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 6 9 17l-5-5"/></svg>,
  trash:   <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/></svg>,
  archive: <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="4" width="20" height="5" rx="2"/><path d="M4 9v10a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9M10 13h4"/></svg>,
  reveal:  <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>,
  refresh: <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M21 12a9 9 0 0 0-15.5-6.4L3 8M3 3v5h5M3 12a9 9 0 0 0 15.5 6.4L21 16M21 21v-5h-5"/></svg>,
  more:    <svg className="icn" viewBox="0 0 24 24" fill="currentColor"><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></svg>,
  bell:    <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10 21a2 2 0 0 0 4 0"/></svg>,
  chevron: <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="m9 18 6-6-6-6"/></svg>,
  folder:  <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M3 7a2 2 0 0 1 2-2h4l2 3h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>,
  play:    <svg className="icn" viewBox="0 0 24 24" fill="currentColor"><polygon points="6 4 20 12 6 20"/></svg>,
  pause:   <svg className="icn" viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="4" width="4" height="16" rx="1"/><rect x="14" y="4" width="4" height="16" rx="1"/></svg>,
  warning: <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M10.3 3.86a2 2 0 0 1 3.4 0l8.4 14.14a2 2 0 0 1-1.73 3H3.63a2 2 0 0 1-1.73-3z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>,
  shield:  <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>,
  filter:  <svg className="icn" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>,
};

const SIDE_ITEMS = [
  { id: 'overview',  label: '总览',         icon: 'grid' },
  { id: 'cleanup',   label: '智能清理',     icon: 'sparkle',  badge: '12.4 GB' },
  { id: 'analyze',   label: '存储分析',     icon: 'disk',     badge: '312 GB' },
  { id: 'large',     label: '大文件',         icon: 'doc',      badge: '128' },
  { id: 'dupes',     label: '重复文件',     icon: 'copy',     badge: '42' },
  { id: 'apps',      label: '应用程序',     icon: 'apps' },
  { id: 'memory',    label: '内存',           icon: 'cpu' },
  { id: 'drives',    label: '外接磁盘',     icon: 'drive' },
];

function Frame({ title, children, sidebarActive = 'overview' }) {
  return (
    <div className="df">
      <div className="df-titlebar">
        <div className="df-traffic"><span></span><span></span><span></span></div>
        <div className="df-title">{title}</div>
        <div style={{ width: 56 }}></div>
      </div>
      <div className="df-body">
        <Sidebar active={sidebarActive} />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
          {children}
        </div>
      </div>
    </div>
  );
}

function Sidebar({ active }) {
  return (
    <aside className="df-sidebar">
      <div className="df-brand">
        <div className="df-brand-mark">D</div>
        <div className="df-brand-text">DiskFlow</div>
      </div>

      <div className="df-section-label">工作区</div>
      {SIDE_ITEMS.map(it => (
        <div key={it.id} className={'df-nav ' + (active === it.id ? 'active' : '')}>
          <span className="df-nav-icon">{Icon[it.icon]}</span>
          <span>{it.label}</span>
          {it.badge && <span className="badge">{it.badge}</span>}
        </div>
      ))}

      <div className="df-section-label">系统</div>
      <div className={'df-nav ' + (active === 'settings' ? 'active' : '')}>
        <span className="df-nav-icon">{Icon.settings}</span>
        <span>设置</span>
      </div>

      <div className="df-side-stat">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ fontSize: 11, color: 'var(--t-3)' }}>Macintosh HD</span>
          <span className="df-chip good" style={{ height: 18, fontSize: 10, padding: '0 6px' }}>
            <span className="dot"></span>健康
          </span>
        </div>
        <div className="df-stacked-bar">
          <span style={{ width: '22%', background: 'var(--cat-apps)' }}></span>
          <span style={{ width: '14%', background: 'var(--cat-docs)' }}></span>
          <span style={{ width: '10%', background: 'var(--cat-video)' }}></span>
          <span style={{ width: '8%',  background: 'var(--cat-photo)' }}></span>
          <span style={{ width: '7%',  background: 'var(--cat-system)' }}></span>
          <span style={{ width: '4%',  background: 'var(--cat-cache)' }}></span>
        </div>
        <div className="stat-row"><span>已用 <b>312 GB</b></span><span>剩余 <b>200 GB</b></span></div>
      </div>
    </aside>
  );
}

function Toolbar({ search = '搜索文件、应用、缓存…', actions, leftExtra }) {
  return (
    <div className="df-toolbar">
      {leftExtra}
      <div className="df-search">
        <span style={{ color: 'var(--t-3)' }}>{Icon.search}</span>
        <span>{search}</span>
        <span className="kbd">⌘K</span>
      </div>
      <div style={{ flex: 1 }}></div>
      <button className="df-icon-btn" title="Refresh">{Icon.refresh}</button>
      <button className="df-icon-btn" title="Notifications">{Icon.bell}</button>
      {actions}
    </div>
  );
}

// === DONUT ===
function Donut({ size = 200, stroke = 22, segments, label, sub }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  let offset = 0;
  return (
    <div className="df-donut" style={{ width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth={stroke} />
        {segments.map((s, i) => {
          const dash = (s.pct / 100) * c;
          const el = (
            <circle key={i} cx={size/2} cy={size/2} r={r} fill="none"
                    stroke={s.color} strokeWidth={stroke}
                    strokeDasharray={`${dash - 1.5} ${c - dash + 1.5}`}
                    strokeDashoffset={-offset}
                    strokeLinecap="butt" />
          );
          offset += dash;
          return el;
        })}
      </svg>
      <div className="donut-center">
        <div>
          <div className="donut-big">{label}</div>
          <div className="donut-sub">{sub}</div>
        </div>
      </div>
    </div>
  );
}

function Bar({ fill = 50, variant }) {
  return <div className={'df-bar' + (variant ? ' ' + variant : '')}><i style={{ width: fill + '%' }}></i></div>;
}

function Chip({ children, active, variant }) {
  let cls = 'df-chip';
  if (active) cls += ' active';
  if (variant) cls += ' ' + variant;
  return <span className={cls}>{children}</span>;
}

function Check({ on }) {
  return <span className={'df-check' + (on ? ' on' : '')}></span>;
}

function Sparkline({ data, color = 'var(--blue)', filled = false }) {
  const w = 80, h = 24;
  const max = Math.max(...data);
  const min = Math.min(...data);
  const pts = data.map((v, i) => `${(i / (data.length - 1)) * w},${h - ((v - min) / (max - min || 1)) * (h - 4) - 2}`).join(' ');
  return (
    <svg className="df-spark" viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none">
      {filled && <polygon points={`0,${h} ${pts} ${w},${h}`} fill={color} opacity="0.18" />}
      <polyline points={pts} fill="none" stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

Object.assign(window, {
  Icon, SIDE_ITEMS, Frame, Sidebar, Toolbar, Donut, Bar, Chip, Check, Sparkline,
});
