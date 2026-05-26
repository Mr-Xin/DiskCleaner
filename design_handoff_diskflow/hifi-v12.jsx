/* Hi-fi v1.2 — 废纸篓恢复 · 清理历史 · 调度日历 · 通知中心 */

// ============ 废纸篓恢复 ============

function HiFiTrashRecovery() {
  const groups = [
    {
      date: '今天', expired: 30,
      items: [
        { i: 'XCD', g: 'cache',   n: 'DerivedData',                p: '~/Library/Developer/Xcode',     s: '6.2 GB',  from: '智能清理 · 12:42' },
        { i: 'DWN', g: 'folder',  n: 'Xcode_15.4.xip',             p: '~/Downloads',                   s: '7.2 GB',  from: '智能清理 · 12:42', sel: true },
        { i: 'CHR', g: 'cache',   n: 'Chrome/Cache',               p: '~/Library/Caches/Google',       s: '3.1 GB',  from: '智能清理 · 12:42' },
      ],
    },
    {
      date: '昨天', expired: 29,
      items: [
        { i: 'IMG', g: 'image',   n: 'IMG_8421.jpg (副本)',        p: '~/Downloads/from-iphone',       s: '0.8 MB',  from: '重复文件清理' },
        { i: 'PSD', g: 'doc',     n: 'logo-v3 (副本).psd',         p: '~/Desktop',                     s: '88 MB',   from: '重复文件清理', sel: true },
      ],
    },
    {
      date: '12 天前 · 即将过期',
      expired: 18, warning: true,
      items: [
        { i: 'IPA', g: 'archive', n: 'Adobe Photoshop',            p: '/Applications',                 s: '4.2 GB',  from: '应用卸载', warn: true },
      ],
    },
  ];

  return (
    <Frame title="废纸篓恢复 · DiskFlow" sidebarActive="overview">
      <Toolbar
        search="按名称、来源筛选…"
        actions={
          <>
            <button className="df-btn ghost sm">{Icon.filter}排序：删除时间 ↓</button>
            <button className="df-btn ghost sm" style={{ color: 'var(--danger)', borderColor: 'rgba(255,107,125,0.3)' }}>立即清空</button>
          </>
        }
      />
      <div className="df-main">
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div>
            <h1 className="df-h1">废纸篓 · 可恢复</h1>
            <p className="df-p" style={{ marginTop: 4 }}>
              6 项 · <b style={{ color: 'var(--blue-hi)' }}>21.6 GB</b> · 30 天保留期 · 过期后自动永久删除
            </p>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <Chip active>全部</Chip>
            <Chip>今天</Chip>
            <Chip>本周</Chip>
            <Chip variant="warn">即将过期</Chip>
          </div>
        </div>

        {/* 容量条 */}
        <div className="df-card" style={{ padding: 14, display: 'flex', alignItems: 'center', gap: 14 }}>
          <span style={{ color: 'var(--blue-hi)' }}>{Icon.shield}</span>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12.5, color: 'var(--t-1)', fontWeight: 500 }}>所有删除都是可恢复的</div>
            <div style={{ fontSize: 11, color: 'var(--t-3)', marginTop: 2 }}>
              废纸篓占用 21.6 GB · 系统空间充裕时 DiskFlow 不会主动加速清空
            </div>
          </div>
          <div style={{ width: 200 }}>
            <Bar fill={20} />
            <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--t-3)', marginTop: 4, textAlign: 'right' }}>21.6 GB / 可用 200 GB</div>
          </div>
        </div>

        {/* 时间线分组 */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 14, minHeight: 0, overflow: 'hidden' }}>
          {groups.map((g, gi) => (
            <div key={gi}>
              {/* 分组头 */}
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '0 4px 8px',
                            color: g.warning ? 'var(--warn)' : 'var(--t-2)' }}>
                <div style={{ width: 10, height: 10, borderRadius: 5, background: g.warning ? 'var(--warn)' : 'var(--t-3)',
                              boxShadow: g.warning ? '0 0 10px var(--warn)' : 'none' }}></div>
                <h2 style={{ fontSize: 13, fontWeight: 600, margin: 0 }}>{g.date}</h2>
                <span style={{ fontSize: 11, color: 'var(--t-3)' }}>· 还剩 {g.expired} 天可恢复</span>
              </div>

              {/* 项目卡 */}
              <div className="df-card elevated" style={{ padding: 0, overflow: 'hidden',
                                                          borderColor: g.warning ? 'rgba(255,180,92,0.3)' : 'var(--line-1)',
                                                          boxShadow: g.warning ? '0 0 24px -10px rgba(255,180,92,0.3)' : undefined }}>
                {g.items.map((it, i) => (
                  <div key={i} style={{
                    padding: '12px 16px', borderBottom: i < g.items.length - 1 ? '1px solid var(--line-1)' : 0,
                    background: it.sel ? 'rgba(77,158,255,0.10)' : 'transparent',
                    display: 'flex', alignItems: 'center', gap: 12,
                  }}>
                    <Check on={it.sel} />
                    <div className={'df-glyph ' + it.g} style={{ width: 30, height: 30, fontSize: 9 }}>{it.i}</div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 12.5, fontWeight: 500, color: 'var(--t-1)',
                                    overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{it.n}</div>
                      <div className="df-mono" style={{ fontSize: 10.5, color: 'var(--t-3)' }}>{it.p}</div>
                    </div>
                    <span style={{ fontSize: 11, color: it.warn ? 'var(--warn)' : 'var(--t-3)', textAlign: 'right' }}>
                      {it.from}
                    </span>
                    <span className="df-mono" style={{ fontSize: 13, color: 'var(--t-1)', fontWeight: 500, minWidth: 60, textAlign: 'right' }}>{it.s}</span>
                    <button className="df-btn ghost sm">{Icon.refresh}恢复</button>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>

        {/* 浮动操作栏 */}
        <div className="df-faction">
          <Check on />
          <span style={{ fontSize: 13, fontWeight: 500 }}>已选中 2 项</span>
          <span className="df-mono" style={{ fontSize: 18, fontWeight: 700, color: 'var(--blue-hi)' }}>· 7.3 GB</span>
          <div style={{ flex: 1 }}></div>
          <button className="df-btn ghost sm">{Icon.reveal}在 Finder 中显示</button>
          <button className="df-btn">{Icon.refresh}恢复到原位置</button>
          <button className="df-btn danger sm">永久删除</button>
        </div>
      </div>
    </Frame>
  );
}

// ============ 清理历史时间线 ============

function HiFiCleanupHistory() {
  // 月度柱状条：每天释放量
  const days = Array.from({ length: 30 }, (_, i) => {
    const v = [0, 0, 0, 3.4, 0, 0, 1.2, 0, 0, 8.6, 0, 0, 0, 2.1, 0, 0, 0, 0, 4.8, 0, 0, 12.4, 0, 0, 0, 0, 1.8, 0, 0, 6.2][i] || 0;
    return v;
  });
  const maxDay = Math.max(...days);

  return (
    <Frame title="清理历史 · DiskFlow" sidebarActive="overview">
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost sm">本月 ▾</button>
            <button className="df-btn">{Icon.archive}导出报告</button>
          </>
        }
      />
      <div className="df-main">
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div>
            <h1 className="df-h1">清理历史</h1>
            <p className="df-p" style={{ marginTop: 4 }}>
              本月释放 <b style={{ color: 'var(--blue-hi)' }}>40.5 GB</b> · 12 次清理 · 平均每次 3.4 GB
            </p>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <Chip>近 30 天</Chip>
            <Chip active>本月</Chip>
            <Chip>本季</Chip>
            <Chip>全年</Chip>
          </div>
        </div>

        {/* 月度柱状图 */}
        <div className="df-card elevated" style={{ padding: 20, position: 'relative' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
            <span className="df-label">每日释放</span>
            <div style={{ display: 'flex', gap: 14, fontSize: 11, color: 'var(--t-3)' }}>
              <span>最大单次：<b style={{ color: 'var(--blue-hi)' }}>12.4 GB</b> · 6 月 12 日</span>
              <span>累计：<b style={{ color: 'var(--good)' }}>40.5 GB</b></span>
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 4, height: 100 }}>
            {days.map((v, i) => (
              <div key={i} style={{ flex: 1, height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
                <div style={{
                  height: v > 0 ? `${(v / maxDay) * 100}%` : 2,
                  background: v >= 10 ? 'linear-gradient(180deg, var(--blue-hi), var(--cyan))'
                            : v >= 5 ? 'linear-gradient(180deg, var(--blue), var(--cyan))'
                            : v > 0 ? 'var(--blue)' : 'var(--glass-2)',
                  borderRadius: 3,
                  boxShadow: v >= 10 ? '0 0 12px rgba(77,158,255,0.4)' : 'none',
                  position: 'relative',
                }}>
                  {v >= 5 && (
                    <div style={{ position: 'absolute', top: -16, left: '50%', transform: 'translateX(-50%)',
                                  fontSize: 9, fontFamily: 'var(--font-mono)', color: 'var(--t-2)', whiteSpace: 'nowrap' }}>{v}</div>
                  )}
                </div>
              </div>
            ))}
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8, fontSize: 9, color: 'var(--t-3)', fontFamily: 'var(--font-mono)' }}>
            <span>6/1</span><span>6/8</span><span>6/15</span><span>6/22</span><span>6/30</span>
          </div>
        </div>

        {/* 分类统计 + 历史列表 */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.6fr', gap: 16, flex: 1, minHeight: 0 }}>
          {/* 分类汇总 */}
          <div className="df-card elevated" style={{ padding: 18, display: 'flex', flexDirection: 'column', gap: 12 }}>
            <h2 className="df-h2">按类型 · 本月</h2>
            {[
              { l: '应用缓存',     v: 18.4, pct: 45, c: 'var(--cat-cache)' },
              { l: '旧的下载',     v: 9.2,  pct: 23, c: 'var(--cat-other)' },
              { l: '重复文件',     v: 6.8,  pct: 17, c: 'var(--cat-photo)' },
              { l: '应用残留',     v: 4.1,  pct: 10, c: 'var(--cat-apps)' },
              { l: '其他',         v: 2.0,  pct: 5,  c: 'var(--cat-other)' },
            ].map((c, i) => (
              <div key={i}>
                <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 4 }}>
                  <span style={{ fontSize: 12, color: 'var(--t-1)' }}>{c.l}</span>
                  <span className="df-mono" style={{ fontSize: 12, color: 'var(--t-2)', fontWeight: 500 }}>{c.v} GB</span>
                </div>
                <div className="df-bar"><i style={{ width: c.pct + '%', background: `linear-gradient(90deg, ${c.c}, ${c.c}aa)`, boxShadow: `0 0 8px ${c.c}80` }}></i></div>
              </div>
            ))}
            <div className="df-divider" style={{ margin: '6px 0' }}></div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
              <span style={{ fontSize: 12, color: 'var(--t-3)' }}>本月合计</span>
              <span style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.02em',
                             background: 'linear-gradient(180deg, #fff, var(--blue-hi))',
                             WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text' }}>40.5 GB</span>
            </div>
          </div>

          {/* 最近清理记录 */}
          <div className="df-card elevated" style={{ padding: 0, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
            <div style={{ padding: '14px 18px', borderBottom: '1px solid var(--line-1)' }}>
              <h2 className="df-h2">最近清理</h2>
            </div>
            <div style={{ flex: 1, overflow: 'hidden' }}>
              {[
                { t: '智能清理',        s: '12.4 GB', d: '6 月 22 日 · 12:42', items: 'Xcode 缓存 · 旧下载 · 重复照片', undo: true },
                { t: '应用卸载',        s: '7.4 GB',  d: '6 月 20 日 · 09:14', items: 'Adobe Photoshop · 含残留',     undo: true },
                { t: '智能清理',        s: '8.6 GB',  d: '6 月 10 日 · 21:08', items: 'Chrome 缓存 · Slack 缓存',     undo: false },
                { t: '重复文件',        s: '4.8 GB',  d: '6 月 19 日 · 16:30', items: '42 组 · 128 张照片',           undo: false },
                { t: '大文件归档',      s: '6.2 GB',  d: '6 月 27 日 · 11:20', items: '5 个文件 · 移至 Backup-SSD',   undo: false, archive: true },
              ].map((r, i) => (
                <div key={i} style={{ padding: '12px 18px', borderBottom: i < 4 ? '1px solid var(--line-1)' : 0,
                                      display: 'flex', alignItems: 'center', gap: 12 }}>
                  <div style={{ width: 32, height: 32, borderRadius: 8, flexShrink: 0,
                                background: r.archive ? 'rgba(155,139,255,0.15)' : 'rgba(95,212,154,0.15)',
                                border: '1px solid ' + (r.archive ? 'rgba(155,139,255,0.4)' : 'rgba(95,212,154,0.4)'),
                                display: 'grid', placeItems: 'center', color: r.archive ? 'var(--purple)' : 'var(--good)' }}>
                    {r.archive ? Icon.archive : <svg width="14" height="14" viewBox="0 0 24 24"><path d="M5 13l4 4L19 7" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/></svg>}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 12.5, fontWeight: 500 }}>{r.t}</div>
                    <div style={{ fontSize: 11, color: 'var(--t-3)', marginTop: 2 }}>{r.items}</div>
                  </div>
                  <div style={{ textAlign: 'right', minWidth: 100 }}>
                    <div className="df-mono" style={{ fontSize: 13, fontWeight: 600, color: r.archive ? 'var(--purple)' : 'var(--good)' }}>+{r.s}</div>
                    <div style={{ fontSize: 10.5, color: 'var(--t-3)', marginTop: 2 }}>{r.d}</div>
                  </div>
                  {r.undo && <button className="df-btn ghost sm">{Icon.refresh}撤销</button>}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </Frame>
  );
}

// ============ 调度日历 ============

function HiFiSchedule() {
  // 一周 7 天，每天有不同的任务安排
  const week = ['周一','周二','周三','周四','周五','周六','周日'];
  const events = [
    { d: 0, h: 21, dur: 1, t: '快速扫描', kind: 'scan' },
    { d: 1, h: 21, dur: 1, t: '快速扫描', kind: 'scan' },
    { d: 2, h: 21, dur: 1, t: '快速扫描', kind: 'scan' },
    { d: 3, h: 21, dur: 1, t: '快速扫描', kind: 'scan' },
    { d: 4, h: 21, dur: 1, t: '快速扫描', kind: 'scan' },
    { d: 5, h: 14, dur: 2, t: '深度扫描', kind: 'deep' },
    { d: 6, h: 9,  dur: 2, t: '智能清理', kind: 'clean', active: true },
    { d: 6, h: 11, dur: 1, t: '导出周报', kind: 'report' },
  ];

  const hourHeight = 24;
  const startHour = 6;
  const endHour = 24;

  const kindColor = {
    scan:   { c: 'var(--blue)',   bg: 'rgba(77,158,255,0.18)',  br: 'rgba(77,158,255,0.5)' },
    deep:   { c: 'var(--purple)', bg: 'rgba(155,139,255,0.2)',  br: 'rgba(155,139,255,0.5)' },
    clean:  { c: 'var(--good)',   bg: 'rgba(95,212,154,0.2)',   br: 'rgba(95,212,154,0.5)' },
    report: { c: 'var(--cyan)',   bg: 'rgba(93,213,232,0.18)',  br: 'rgba(93,213,232,0.5)' },
  };

  return (
    <Frame title="设置 · 调度计划" sidebarActive="settings">
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost sm">{Icon.refresh}立即运行</button>
            <button className="df-btn primary">+ 新建任务</button>
          </>
        }
      />
      <div className="df-main">
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: 'var(--t-3)', marginBottom: 4 }}>
          <span>设置</span><span>›</span><span>扫描</span><span>›</span><span style={{ color: 'var(--blue-hi)' }}>调度计划</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div>
            <h1 className="df-h1">调度计划</h1>
            <p className="df-p" style={{ marginTop: 4 }}>
              本周 8 个任务 · 下次执行 <b style={{ color: 'var(--good)' }}>周日 9:00 · 智能清理</b>
            </p>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <button className="df-icon-btn">{Icon.chevron}</button>
            <span style={{ fontSize: 13, fontWeight: 500, minWidth: 130, textAlign: 'center' }}>6 月 24 – 30 日</span>
            <button className="df-icon-btn" style={{ transform: 'scaleX(-1)' }}>{Icon.chevron}</button>
            <div style={{ width: 14 }}></div>
            <Chip>周视图</Chip>
            <Chip>月视图</Chip>
          </div>
        </div>

        {/* 周视图日历 */}
        <div className="df-card elevated" style={{ padding: 0, flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
          {/* 表头 */}
          <div style={{ display: 'grid', gridTemplateColumns: '60px repeat(7, 1fr)', borderBottom: '1px solid var(--line-1)' }}>
            <div></div>
            {week.map((d, i) => (
              <div key={i} style={{ padding: '12px 0', textAlign: 'center', borderLeft: '1px solid var(--line-1)',
                                    background: i === 6 ? 'rgba(95,212,154,0.06)' : 'transparent' }}>
                <div style={{ fontSize: 10.5, color: 'var(--t-3)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>{d}</div>
                <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2,
                              color: i === 6 ? 'var(--good)' : 'var(--t-1)' }}>{24 + i}</div>
              </div>
            ))}
          </div>

          {/* 时间网格 */}
          <div style={{ flex: 1, overflow: 'hidden', position: 'relative' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '60px repeat(7, 1fr)', height: '100%' }}>
              {/* 时间标尺 */}
              <div style={{ borderRight: '1px solid var(--line-1)' }}>
                {Array.from({ length: endHour - startHour }, (_, i) => (
                  <div key={i} style={{ height: hourHeight, position: 'relative',
                                          borderBottom: i % 2 ? '1px dashed var(--line-1)' : '1px solid var(--line-1)' }}>
                    {i % 2 === 0 && (
                      <span style={{ position: 'absolute', top: -7, right: 6, fontSize: 10, color: 'var(--t-3)', fontFamily: 'var(--font-mono)' }}>
                        {String(startHour + i).padStart(2, '0')}:00
                      </span>
                    )}
                  </div>
                ))}
              </div>

              {/* 每日列 */}
              {week.map((_, d) => (
                <div key={d} style={{ position: 'relative', borderLeft: '1px solid var(--line-1)',
                                       background: d === 6 ? 'rgba(95,212,154,0.03)' : 'transparent' }}>
                  {/* 小时网格线 */}
                  {Array.from({ length: endHour - startHour }, (_, i) => (
                    <div key={i} style={{ height: hourHeight, borderBottom: i % 2 ? '1px dashed var(--line-1)' : '1px solid var(--line-1)' }}></div>
                  ))}

                  {/* 事件 */}
                  {events.filter(e => e.d === d).map((e, i) => {
                    const col = kindColor[e.kind];
                    const top = (e.h - startHour) * hourHeight;
                    const h = e.dur * hourHeight;
                    return (
                      <div key={i} style={{
                        position: 'absolute', left: 4, right: 4, top, height: h - 2,
                        borderRadius: 6, padding: '4px 8px',
                        background: col.bg,
                        border: '1px solid ' + col.br,
                        borderLeft: '3px solid ' + col.c,
                        fontSize: 10.5,
                        boxShadow: e.active ? `0 0 16px ${col.c}80` : 'none',
                        display: 'flex', flexDirection: 'column', gap: 2,
                      }}>
                        <div style={{ fontWeight: 600, color: col.c, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>
                          {e.t}
                        </div>
                        <div style={{ fontFamily: 'var(--font-mono)', fontSize: 9, color: 'var(--t-3)' }}>
                          {String(e.h).padStart(2,'0')}:00
                        </div>
                      </div>
                    );
                  })}

                  {/* 当前时间指示线（第3天 = 周四，假设现在 16:30） */}
                  {d === 3 && (
                    <div style={{ position: 'absolute', left: 0, right: 0, top: (16.5 - startHour) * hourHeight,
                                  borderTop: '2px solid var(--accent, var(--blue-hi))',
                                  background: 'transparent', pointerEvents: 'none' }}>
                      <div style={{ position: 'absolute', left: -5, top: -5, width: 10, height: 10, borderRadius: 5,
                                    background: 'var(--blue-hi)', boxShadow: '0 0 8px var(--blue-hi)' }}></div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* 任务图例 */}
        <div className="df-card" style={{ padding: '12px 18px', display: 'flex', alignItems: 'center', gap: 18 }}>
          <span className="df-label">任务类型</span>
          {[
            { l: '快速扫描', c: 'var(--blue)' },
            { l: '深度扫描', c: 'var(--purple)' },
            { l: '智能清理', c: 'var(--good)' },
            { l: '导出报告', c: 'var(--cyan)' },
          ].map((k, i) => (
            <div key={i} style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 12 }}>
              <span style={{ width: 8, height: 8, borderRadius: 2, background: k.c, boxShadow: `0 0 6px ${k.c}` }}></span>
              {k.l}
            </div>
          ))}
          <div style={{ flex: 1 }}></div>
          <span style={{ fontSize: 11.5, color: 'var(--t-3)' }}>
            ⚙ 屏幕休眠时<b style={{ color: 'var(--t-1)' }}>暂停任务</b> · 接通电源时<b style={{ color: 'var(--t-1)' }}>优先深度扫描</b>
          </span>
        </div>
      </div>
    </Frame>
  );
}

// ============ 通知中心 ============

function HiFiNotifications() {
  const today = [
    { i: Icon.sparkle, c: 'var(--blue)',   t: '智能清理建议已更新',     b: '发现 12.4 GB 可释放 · 比上周 ↑ 18%',    a: '12:42', new: true, action: '查看' },
    { i: Icon.warning, c: 'var(--warn)',   t: '内存压力变黄',           b: 'Chrome Helper 占用 2.4 GB · 一直存在',  a: '11:08', new: true, action: '释放 RAM' },
  ];
  const yesterday = [
    { i: Icon.check,   c: 'var(--good)',   t: '调度任务已完成',         b: '智能清理释放 8.6 GB · 用时 38 秒',      a: '21:08', action: '查看报告' },
    { i: Icon.shield,  c: 'var(--cyan)',   t: '完全磁盘访问权限已生效', b: 'DiskFlow 现在可以扫描外接磁盘',         a: '14:22' },
  ];
  const older = [
    { i: Icon.bell,    c: 'var(--t-3)',    t: '本周清理总结',           b: '6 月 17–23 日共释放 28.4 GB · 健康分 76 → 89', a: '6 月 24 日', action: '导出 PDF' },
    { i: Icon.refresh, c: 'var(--t-3)',    t: 'DiskFlow 1.2.0 已安装',  b: '新增：废纸篓恢复 · 清理历史 · 调度日历',  a: '6 月 18 日' },
  ];

  const Row = ({ n }) => (
    <div style={{
      padding: '12px 16px',
      borderBottom: '1px solid var(--line-1)',
      display: 'flex', gap: 12, alignItems: 'flex-start',
      background: n.new ? 'rgba(77,158,255,0.05)' : 'transparent',
    }}>
      <div style={{ width: 32, height: 32, borderRadius: 8, flexShrink: 0,
                    background: `linear-gradient(135deg, ${n.c}33, ${n.c}11)`,
                    border: `1px solid ${n.c}55`,
                    display: 'grid', placeItems: 'center', color: n.c }}>{n.i}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ fontSize: 12.5, fontWeight: 600, color: 'var(--t-1)' }}>{n.t}</span>
          {n.new && <span style={{ width: 6, height: 6, borderRadius: 3, background: 'var(--blue-hi)', boxShadow: '0 0 6px var(--blue-hi)' }}></span>}
        </div>
        <div style={{ fontSize: 11.5, color: 'var(--t-3)', marginTop: 2 }}>{n.b}</div>
      </div>
      <span style={{ fontSize: 10.5, color: 'var(--t-4)', fontFamily: 'var(--font-mono)', whiteSpace: 'nowrap' }}>{n.a}</span>
      {n.action && <button className="df-btn ghost sm">{n.action}</button>}
    </div>
  );

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
      {/* 主页背景 */}
      <div className="df-main" style={{ filter: 'blur(2px) saturate(0.7)', opacity: 0.3, pointerEvents: 'none' }}>
        <div className="df-card" style={{ flex: 1 }}></div>
      </div>

      {/* 通知抽屉 · 从顶部铃铛位置弹出 */}
      <div style={{
        position: 'absolute', top: 90, right: 22,
        width: 420, maxHeight: 'calc(100% - 110px)',
        background: 'rgba(20,24,34,0.92)',
        border: '1px solid var(--line-3)',
        borderRadius: 'var(--r-xl)',
        boxShadow: '0 30px 80px rgba(0,0,0,0.6)',
        backdropFilter: 'blur(40px) saturate(180%)',
        display: 'flex', flexDirection: 'column',
        zIndex: 50,
      }}>
        {/* 头部 */}
        <div style={{ padding: '14px 18px', borderBottom: '1px solid var(--line-1)',
                      display: 'flex', alignItems: 'center', gap: 10 }}>
          <h2 className="df-h2">通知</h2>
          <span style={{ fontSize: 10, fontWeight: 700, padding: '1px 7px', borderRadius: 8,
                         background: 'var(--blue)', color: '#fff' }}>2</span>
          <div style={{ flex: 1 }}></div>
          <button className="df-btn ghost sm">全部标为已读</button>
          <button className="df-icon-btn" style={{ width: 26, height: 26 }}>{Icon.settings}</button>
        </div>

        {/* 筛选 */}
        <div style={{ padding: '10px 18px', display: 'flex', gap: 6, borderBottom: '1px solid var(--line-1)' }}>
          <Chip active>全部</Chip>
          <Chip>提醒</Chip>
          <Chip>报告</Chip>
          <Chip>系统</Chip>
        </div>

        {/* 列表 */}
        <div style={{ flex: 1, overflow: 'hidden' }}>
          <div className="df-label" style={{ padding: '10px 18px 4px' }}>今天</div>
          {today.map((n, i) => <Row key={i} n={n} />)}

          <div className="df-label" style={{ padding: '10px 18px 4px' }}>昨天</div>
          {yesterday.map((n, i) => <Row key={i} n={n} />)}

          <div className="df-label" style={{ padding: '10px 18px 4px' }}>更早</div>
          {older.map((n, i) => <Row key={i} n={n} />)}
        </div>

        <div style={{ padding: '10px 18px', borderTop: '1px solid var(--line-1)',
                      background: 'rgba(7,9,13,0.3)', textAlign: 'center' }}>
          <button className="df-btn ghost sm">在设置中管理通知偏好</button>
        </div>
      </div>

      {/* 暗示铃铛在哪里：右上工具栏铃铛附近的高亮 */}
      <div style={{ position: 'absolute', top: 60, right: 124, width: 36, height: 36, borderRadius: '50%',
                    border: '2px solid var(--blue-hi)', boxShadow: '0 0 16px rgba(77,158,255,0.5)', pointerEvents: 'none' }}></div>
    </Frame>
  );
}

Object.assign(window, {
  HiFiTrashRecovery, HiFiCleanupHistory, HiFiSchedule, HiFiNotifications,
});
