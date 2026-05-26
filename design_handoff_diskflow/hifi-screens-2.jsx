/* Hi-fi: 内存 · 应用程序 · 设置 · 状态屏 */

// ============ 内存监控 ============

function HiFiMemory() {
  const ram = [62, 64, 60, 65, 70, 68, 72, 75, 70, 73, 78, 75, 80, 82, 78, 80, 77, 79, 76, 78];
  const cpu = [22, 25, 20, 28, 35, 30, 38, 42, 36, 40, 48, 42, 38, 32, 28, 30, 34, 36, 30, 34];

  return (
    <Frame title="内存" sidebarActive="memory">
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost sm">{Icon.pause}暂停</button>
            <button className="df-btn primary">{Icon.bolt}释放内存</button>
          </>
        }
      />
      <div className="df-main">
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div>
            <h1 className="df-h1">内存监控</h1>
            <p className="df-p" style={{ marginTop: 4 }}>实时 · 每秒采样一次 · 16 GB 统一内存。</p>
          </div>
          <Chip variant="warn"><span className="dot"></span>黄色压力</Chip>
        </div>

        {/* 顶部统计 */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          {[
            { l: '已使用', v: '12.4 GB', s: '共 16 GB',           pct: 78, variant: 'warn',   spark: ram, color: 'var(--warn)' },
            { l: '缓存',   v: '2.8 GB',  s: '可回收',              pct: 18, variant: '',       spark: [40,42,44,41,45,43,46,44,47,45,48,46,47,49,47,48,50,48,49,51], color: 'var(--blue)' },
            { l: '交换区', v: '1.2 GB',  s: '↑ 正在增长',          pct: 8,  variant: 'danger', spark: [10,11,11,12,12,13,14,14,15,16,18,20,22,24,26,28,30,32,34,38], color: 'var(--danger)' },
            { l: 'CPU',   v: '34%',     s: '8 核 · 3.2 GHz',     pct: 34, variant: '',       spark: cpu, color: 'var(--cyan)' },
          ].map((s, i) => (
            <div key={i} className="df-card elevated" style={{ padding: 16 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span className="df-label">{s.l}</span>
                <Sparkline data={s.spark} color={s.color} filled />
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 10 }}>
                <span style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-0.02em' }}>{s.v}</span>
                <span style={{ fontSize: 11.5, color: s.l === '交换区' ? 'var(--danger)' : 'var(--t-3)' }}>{s.s}</span>
              </div>
              <div style={{ marginTop: 10 }}><Bar fill={s.pct} variant={s.variant} /></div>
            </div>
          ))}
        </div>

        {/* 实时图 */}
        <div className="df-card elevated" style={{ padding: 18, height: 180, position: 'relative' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
            <span className="df-label">RAM + CPU · 最近 60 秒</span>
            <div style={{ display: 'flex', gap: 12, fontSize: 11, color: 'var(--t-2)' }}>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                <span style={{ width: 8, height: 8, borderRadius: 2, background: 'var(--blue)', boxShadow: '0 0 6px var(--blue)' }}></span> RAM
              </span>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                <span style={{ width: 8, height: 8, borderRadius: 2, background: 'var(--cyan)', boxShadow: '0 0 6px var(--cyan)' }}></span> CPU
              </span>
              <span className="df-chip good" style={{ height: 20 }}><span className="dot"></span>实时</span>
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
            {[20, 40, 60, 80].map(y => <line key={y} x1="0" x2="600" y1={y} y2={y} stroke="rgba(255,255,255,0.04)" />)}
            <path d="M 0 38 L 30 35 L 60 40 L 90 32 L 120 26 L 150 30 L 180 22 L 210 18 L 240 24 L 270 20 L 300 15 L 330 20 L 360 12 L 390 10 L 420 16 L 450 14 L 480 18 L 510 14 L 540 16 L 570 12 L 600 14 L 600 100 L 0 100 Z"
                  fill="url(#memGradBlue)" />
            <polyline points="0,38 30,35 60,40 90,32 120,26 150,30 180,22 210,18 240,24 270,20 300,15 330,20 360,12 390,10 420,16 450,14 480,18 510,14 540,16 570,12 600,14"
                      fill="none" stroke="#4d9eff" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"
                      style={{ filter: 'drop-shadow(0 0 4px rgba(77,158,255,0.6))' }} />
            <path d="M 0 76 L 30 72 L 60 78 L 90 68 L 120 60 L 150 64 L 180 56 L 210 52 L 240 58 L 270 54 L 300 48 L 330 56 L 360 64 L 390 70 L 420 66 L 450 62 L 480 60 L 510 64 L 540 60 L 570 66 L 600 62 L 600 100 L 0 100 Z"
                  fill="url(#memGradCyan)" />
            <polyline points="0,76 30,72 60,78 90,68 120,60 150,64 180,56 210,52 240,58 270,54 300,48 330,56 360,64 390,70 420,66 450,62 480,60 510,64 540,60 570,66 600,62"
                      fill="none" stroke="#5dd5e8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"
                      style={{ filter: 'drop-shadow(0 0 4px rgba(93,213,232,0.5))' }} />
            <line x1="595" x2="595" y1="0" y2="100" stroke="rgba(255,255,255,0.25)" strokeDasharray="2 3"/>
            <circle cx="595" cy="14" r="3" fill="#4d9eff" stroke="#fff" strokeWidth="1"/>
          </svg>
        </div>

        {/* 进程表 */}
        <div className="df-card elevated" style={{ padding: 0, flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0, overflow: 'hidden' }}>
          <div style={{ padding: '12px 18px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--line-1)' }}>
            <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
              <h2 className="df-h2">占用最高进程</h2>
              <span className="df-label">按内存排序</span>
            </div>
            <div style={{ display: 'flex', gap: 6 }}>
              <Chip active>全部</Chip>
              <Chip>用户</Chip>
              <Chip>系统</Chip>
            </div>
          </div>
          <div className="df-row head" style={{ gridTemplateColumns: '32px 1fr 120px 80px 90px 32px' }}>
            <span></span>
            <span>进程</span>
            <span>内存</span>
            <span>CPU</span>
            <span>能耗</span>
            <span></span>
          </div>
          <div style={{ flex: 1, overflow: 'hidden' }}>
            {[
              { n: 'Google Chrome Helper (renderer)', sub: 'PID 8421 · github.com', m: 2.4, c: 14, e: '高',  sel: true, sp: [12,14,18,20,22,24,22,24] },
              { n: 'Xcode',                           sub: 'PID 4221',              m: 1.8, c: 8,  e: '中',  sp: [14,16,15,17,18,17,16,18] },
              { n: 'Slack',                           sub: 'PID 2934',              m: 0.98, c: 4, e: '中',  sp: [8,8,9,9,10,9,9,10] },
              { n: 'Figma Desktop',                   sub: 'PID 6612',              m: 0.84, c: 3, e: '低',  sp: [6,6,7,7,8,7,8,8] },
              { n: 'kernel_task',                     sub: 'PID 0',                 m: 0.62, c: 6, e: '—',   sp: [5,5,6,6,6,5,6,6] },
              { n: 'Notion',                          sub: 'PID 5781',              m: 0.42, c: 1, e: '低',  sp: [3,3,3,4,4,3,4,4] },
            ].map((p, i) => (
              <div key={i} className={'df-row ' + (p.sel ? 'selected' : '')}
                   style={{ gridTemplateColumns: '32px 1fr 120px 80px 90px 32px' }}>
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
                <Chip variant={p.e === '高' ? 'warn' : ''}>{p.e}</Chip>
                <span style={{ color: 'var(--t-3)' }}>{Icon.more}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Frame>
  );
}

// ============ 应用卸载 ============

function HiFiApps() {
  const apps = [
    { n: 'Adobe Photoshop',  v: '25.1',   s: '4.2 GB',  l: '2 个月前',   sel: true,  init: 'Ps', grad: 'linear-gradient(135deg, #4d9eff, #9b8bff)' },
    { n: 'Logic Pro',        v: '10.7',   s: '6.8 GB',  l: '从未打开',   sel: true,  init: 'Lp', grad: 'linear-gradient(135deg, #d287ff, #ff8eb1)' },
    { n: 'Sketch',           v: '99.3',   s: '380 MB',  l: '1 年前',                init: 'Sk', grad: 'linear-gradient(135deg, #ffb45c, #ff8b6b)' },
    { n: 'Slack',            v: '4.36.1', s: '720 MB',  l: '2 小时前',              init: 'Sl', grad: 'linear-gradient(135deg, #9b8bff, #5dd5e8)' },
    { n: 'Figma',            v: '124.8',  s: '210 MB',  l: '昨天',                  init: 'Fi', grad: 'linear-gradient(135deg, #5fd49a, #5dd5e8)' },
    { n: 'Notion',           v: '3.5',    s: '180 MB',  l: '今天',                  init: 'No', grad: 'linear-gradient(135deg, #f0f3f8, #b6bfcf)' },
    { n: 'Spotify',          v: '1.2',    s: '320 MB',  l: '今天',                  init: 'Sp', grad: 'linear-gradient(135deg, #5fd49a, #4d9eff)' },
    { n: 'Zoom',             v: '6.1',    s: '90 MB',   l: '3 周前',                init: 'Zo', grad: 'linear-gradient(135deg, #4d9eff, #5dd5e8)' },
  ];

  return (
    <Frame title="应用程序" sidebarActive="apps">
      <Toolbar
        actions={
          <>
            <button className="df-btn ghost sm">{Icon.filter}排序：最后打开</button>
            <button className="df-btn primary">{Icon.trash}卸载 2 项</button>
          </>
        }
      />
      <div className="df-main">
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div>
            <h1 className="df-h1">你可能不需要的应用</h1>
            <p className="df-p" style={{ marginTop: 4 }}>
              142 个应用共占用 68 GB · DiskFlow 能找出 <b style={{ color: 'var(--t-1)' }}>应用残留</b>，哪怕你已经把它拖到了废纸篓。
            </p>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <Chip active>全部应用</Chip>
            <Chip>闲置 30 天以上</Chip>
            <Chip>从未打开</Chip>
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
                  <span className="df-label">残留数据</span>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 3, fontFamily: 'var(--font-mono)', fontSize: 10.5, color: 'var(--t-2)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>缓存</span><span style={{ color: 'var(--t-1)' }}>220 MB</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>应用支持</span><span style={{ color: 'var(--t-1)' }}>1.4 GB</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>偏好设置</span><span style={{ color: 'var(--t-1)' }}>4 KB</span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>

        <div className="df-faction">
          <Check on />
          <span style={{ fontSize: 13 }}>2 个应用 + 残留</span>
          <span className="df-mono" style={{ fontSize: 18, fontWeight: 700, color: 'var(--blue-hi)' }}>· 11.0 GB</span>
          <div style={{ flex: 1 }}></div>
          <button className="df-btn ghost sm">清除选择</button>
          <button className="df-btn sm">保留应用 · 仅清理残留</button>
          <button className="df-btn primary">{Icon.trash}完全卸载</button>
        </div>
      </div>
    </Frame>
  );
}

// ============ 设置 ============

function HiFiSettings() {
  const sections = [
    { t: '扫描', rows: [
      { l: '启动时扫描',                  sub: 'DiskFlow 打开时自动运行快速扫描',          r: 'toggle-on' },
      { l: '自动扫描计划',                sub: '后台扫描以保持数据新鲜',                  r: '每周 · 周日 9:00' },
      { l: '包含的文件夹',                sub: '限定扫描的根目录',                       r: '主目录、下载、+2 项' },
      { l: '忽略隐藏文件',                sub: '跳过点开头文件与 .DS_Store',             r: 'toggle-off' },
    ]},
    { t: '清理', rows: [
      { l: '安全删除（移到废纸篓而非抹除）', sub: '始终移到废纸篓，方便撤销',               r: 'toggle-on' },
      { l: '删除超过 1 GB 时需确认',        sub: '大型操作的额外保护',                    r: 'toggle-on' },
      { l: '智能挑选规则',                sub: '决定保留哪一份重复文件',                 r: '最高分辨率 · 最新' },
    ]},
    { t: '通知', rows: [
      { l: '磁盘剩余低于 20%',              sub: '剩余空间过低时提醒',                    r: 'toggle-on' },
      { l: '内存压力变黄',                sub: '交换区开始增长时通知',                    r: 'toggle-off' },
      { l: '每周清理总结',                sub: '每周五汇总已清理的内容',                  r: 'toggle-on' },
    ]},
    { t: '高级', rows: [
      { l: '完全磁盘访问权限',             sub: '扫描外接驱动器所必需',                    r: 'badge-good' },
      { l: '菜单栏小组件',                sub: '随时随地查看存储情况',                    r: 'toggle-on' },
      { l: '发送匿名诊断数据',             sub: '帮助我们改进 DiskFlow',                  r: 'toggle-off' },
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
    <Frame title="设置" sidebarActive="settings">
      <div className="df-main" style={{ maxWidth: 760, alignSelf: 'center', width: '100%', overflow: 'auto' }}>
        <h1 className="df-h1">设置</h1>

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
                  {r.r === 'badge-good' && <Chip variant="good"><span className="dot"></span>已授权</Chip>}
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
            <button className="df-btn ghost sm">检查更新</button>
            <button className="df-btn sm">关于</button>
          </div>
        </div>
      </div>
    </Frame>
  );
}

// ============ 状态屏 ============

function HiFiEmpty() {
  return (
    <Frame title="存储分析" sidebarActive="analyze">
      <Toolbar actions={<button className="df-btn primary">{Icon.bolt}开始扫描</button>}/>
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
          <h1 className="df-h1">准备就绪</h1>
          <p className="df-p" style={{ marginTop: 8, fontSize: 13 }}>
            运行首次扫描，可视化存储分布、找出重复文件、生成清理建议。大约需要 2 分钟。
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button className="df-btn">选择文件夹…</button>
          <button className="df-btn primary">{Icon.bolt}扫描整个 Mac</button>
        </div>
        <div style={{ display: 'flex', gap: 16, marginTop: 8, fontSize: 11.5, color: 'var(--t-3)' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>{Icon.shield}默认只读</span>
          <span>·</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>{Icon.check}不会自动删除任何文件</span>
        </div>
      </div>
    </Frame>
  );
}

function HiFiLoading() {
  return (
    <Frame title="扫描中…" sidebarActive="analyze">
      <Toolbar actions={<button className="df-btn ghost sm">取消</button>}/>
      <div className="df-main" style={{ alignItems: 'center', justifyContent: 'center', padding: 30, gap: 22 }}>
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
          <h1 className="df-h1">正在扫描你的 Mac…</h1>
          <p className="df-p" style={{ marginTop: 6 }}>大约还剩 1 分钟 · 已索引 142,840 个文件。</p>
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
            { l: '已索引文件', v: '142.8k' },
            { l: '重复文件组', v: '42' },
            { l: '可回收',     v: '12.4 GB' },
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

function HiFiCleaning() {
  const tasks = [
    { code: 'XCD', glyph: 'cache',  tag: 'Xcode 构建缓存', total: '6.2 GB', cur: '6.2 GB', pct: 100, status: 'done',     color: 'var(--cat-cache)' },
    { code: 'DWN', glyph: 'folder', tag: '旧的下载',        total: '3.8 GB', cur: '2.2 GB', pct: 58,  status: 'running',  color: 'var(--cat-other)' },
    { code: 'PIC', glyph: 'image',  tag: '重复照片',        total: '2.4 GB', cur: '—',      pct: 0,   status: 'queued',   color: 'var(--cat-photo)' },
  ];

  return (
    <Frame title="正在清理 · DiskFlow" sidebarActive="overview">
      <div className="df-toolbar">
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span className="df-status-dot"></span>
          <span style={{ fontSize: 12.5, color: 'var(--t-2)' }}>正在清理 · 请勿关闭窗口</span>
        </div>
        <div style={{ flex: 1 }}></div>
        <button className="df-btn ghost sm">在后台运行</button>
        <button className="df-btn ghost sm" style={{ color: 'var(--danger)', borderColor: 'rgba(255,107,125,0.25)' }}>取消</button>
      </div>

      <div className="df-main" style={{ padding: 28, alignItems: 'center', justifyContent: 'flex-start', gap: 22, overflow: 'hidden', position: 'relative' }}>

        {/* 背景渐变光晕 */}
        <div style={{
          position: 'absolute', top: -200, left: '50%', transform: 'translateX(-50%)',
          width: 700, height: 700, borderRadius: '50%', pointerEvents: 'none',
          background: 'radial-gradient(circle, rgba(77,158,255,0.28), rgba(93,213,232,0.14) 40%, transparent 70%)',
          filter: 'blur(20px)', animation: 'df-pulse 3s ease-in-out infinite',
        }}></div>

        {/* 中央轨道动画 */}
        <div style={{ position: 'relative', width: 260, height: 260, display: 'grid', placeItems: 'center', flexShrink: 0 }}>
          <div className="df-orbit-ring" style={{ width: 240, height: 240, animation: 'df-spin 18s linear infinite' }}>
            <span style={{ position: 'absolute', top: -3, left: '50%', marginLeft: -3, width: 6, height: 6, borderRadius: 3, background: 'var(--blue)', boxShadow: '0 0 12px var(--blue)' }}></span>
          </div>
          <div className="df-orbit-ring" style={{ width: 184, height: 184, animation: 'df-spin-rev 13s linear infinite' }}>
            <span style={{ position: 'absolute', top: -2, left: '50%', marginLeft: -2, width: 5, height: 5, borderRadius: 3, background: 'var(--cyan)', boxShadow: '0 0 10px var(--cyan)' }}></span>
            <span style={{ position: 'absolute', bottom: -2, right: '30%', width: 4, height: 4, borderRadius: 2, background: 'var(--purple)', boxShadow: '0 0 8px var(--purple)' }}></span>
          </div>
          <div className="df-orbit-ring" style={{ width: 132, height: 132, animation: 'df-spin 8s linear infinite' }}>
            <span style={{ position: 'absolute', top: '50%', right: -2, marginTop: -2, width: 4, height: 4, borderRadius: 2, background: 'var(--cyan)', boxShadow: '0 0 8px var(--cyan)' }}></span>
          </div>

          {/* 漂浮粒子 */}
          {[
            { r: 110, dur: 9,  delay: 0,    size: 3, color: 'var(--blue)' },
            { r: 110, dur: 11, delay: -3,   size: 2, color: 'var(--cyan)' },
            { r: 92,  dur: 7,  delay: -2,   size: 3, color: 'var(--purple)' },
            { r: 70,  dur: 6,  delay: -1.5, size: 2, color: 'var(--blue-hi)' },
            { r: 70,  dur: 8,  delay: -4,   size: 2, color: 'var(--cyan)' },
          ].map((p, i) => (
            <div key={i} className="df-orbit-particle"
                 style={{
                   '--orbit-r': p.r + 'px',
                   width: p.size * 2, height: p.size * 2,
                   margin: `-${p.size}px 0 0 -${p.size}px`,
                   background: p.color,
                   boxShadow: `0 0 ${p.size * 4}px ${p.color}`,
                   animationDuration: p.dur + 's',
                   animationDelay: p.delay + 's',
                 }}></div>
          ))}

          {/* 中心数字 */}
          <div style={{ position: 'relative', zIndex: 2, textAlign: 'center', padding: '0 16px' }}>
            <div style={{ fontSize: 11, color: 'var(--t-3)', marginBottom: 6, letterSpacing: '0.1em', textTransform: 'uppercase', fontWeight: 600 }}>已释放</div>
            <div style={{
              fontSize: 48, fontWeight: 700, lineHeight: 1, letterSpacing: '-0.03em',
              background: 'linear-gradient(180deg, #fff, var(--blue-hi) 60%, var(--cyan))',
              WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
              fontVariantNumeric: 'tabular-nums',
            }}>8.4 GB</div>
            <div style={{ fontSize: 11.5, color: 'var(--t-3)', marginTop: 6 }}>共 12.4 GB · 已完成 68%</div>
          </div>
        </div>

        {/* 状态文本 */}
        <div style={{ textAlign: 'center', marginTop: -4 }}>
          <h1 className="df-h1" style={{ fontSize: 22 }}>正在为你腾出空间…</h1>
          <p className="df-p" style={{ marginTop: 6, fontSize: 12.5 }}>
            <span style={{ color: 'var(--blue-hi)' }}>正在清理</span>
            <span className="df-mono" style={{ marginLeft: 6 }}>~/Downloads/old/ubuntu-24.04.iso</span>
          </p>
        </div>

        {/* 任务列表 */}
        <div style={{ width: '100%', maxWidth: 620, display: 'flex', flexDirection: 'column', gap: 10 }}>
          {tasks.map((t, i) => (
            <div key={i} className="df-card elevated"
                 style={{
                   padding: '12px 16px',
                   display: 'flex', alignItems: 'center', gap: 14,
                   opacity: t.status === 'queued' ? 0.55 : 1,
                   borderColor: t.status === 'running' ? 'rgba(77,158,255,0.32)' : 'var(--line-1)',
                   boxShadow: t.status === 'running' ? '0 0 28px -8px rgba(77,158,255,0.45)' : undefined,
                 }}>
              {/* 状态图标 */}
              {t.status === 'done' && (
                <span style={{ width: 24, height: 24, borderRadius: 12, background: 'rgba(95,212,154,0.18)',
                               border: '1px solid var(--good)', display: 'grid', placeItems: 'center', color: 'var(--good)', flexShrink: 0 }}>
                  <svg width="12" height="12" viewBox="0 0 24 24"><path d="M5 13l4 4L19 7" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
                </span>
              )}
              {t.status === 'running' && (
                <span style={{ width: 24, height: 24, borderRadius: 12, flexShrink: 0,
                               background: 'rgba(77,158,255,0.14)', border: '1px solid var(--blue)',
                               display: 'grid', placeItems: 'center', color: 'var(--blue-hi)' }}>
                  <svg width="14" height="14" viewBox="0 0 14 14" style={{ animation: 'df-spin 1s linear infinite' }}>
                    <circle cx="7" cy="7" r="5" fill="none" stroke="rgba(77,158,255,0.2)" strokeWidth="1.5"/>
                    <path d="M 7 2 A 5 5 0 0 1 12 7" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
                  </svg>
                </span>
              )}
              {t.status === 'queued' && (
                <span style={{ width: 24, height: 24, borderRadius: 12, border: '1px dashed var(--line-3)',
                               display: 'grid', placeItems: 'center', color: 'var(--t-3)', fontSize: 11, fontWeight: 600, flexShrink: 0 }}>3</span>
              )}

              {/* 分类图标 */}
              <div className={'df-glyph ' + t.glyph} style={{ width: 30, height: 30, fontSize: 9, flexShrink: 0 }}>{t.code}</div>

              {/* 名称 + 进度条 */}
              <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 4 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                  <span style={{ fontSize: 13, fontWeight: 500, color: 'var(--t-1)' }}>{t.tag}</span>
                  <span className="df-mono" style={{ fontSize: 11, color: 'var(--t-3)' }}>
                    {t.status === 'running' ? `${t.cur} / ${t.total}` : t.status === 'done' ? '✓ 完成' : `等待中 · ${t.total}`}
                  </span>
                </div>
                <div className={'df-bar' + (t.status === 'done' ? ' good' : t.status === 'running' ? ' flow' : '')}>
                  <i style={{ width: t.pct + '%' }}></i>
                </div>
              </div>

              {/* 大小 */}
              <span style={{ minWidth: 64, textAlign: 'right',
                             fontSize: 15, fontWeight: 700, letterSpacing: '-0.01em',
                             color: t.status === 'done' ? 'var(--good)' : t.status === 'running' ? 'var(--blue-hi)' : 'var(--t-3)' }}>
                {t.status === 'done' ? '+' + t.total : t.total}
              </span>
            </div>
          ))}
        </div>

        {/* 底部提示 */}
        <div style={{ display: 'flex', gap: 18, fontSize: 11.5, color: 'var(--t-3)', marginTop: 'auto', paddingTop: 8, alignItems: 'center' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            <span style={{ color: 'var(--blue-hi)' }}>{Icon.shield}</span>
            <span>文件会先移到废纸篓，30 天内可恢复</span>
          </span>
          <span>·</span>
          <span>预计剩余 8 秒</span>
        </div>
      </div>
    </Frame>
  );
}

function HiFiSuccess() {
  return (
    <Frame title="清理完成" sidebarActive="overview">
      <Toolbar actions={<button className="df-btn primary">{Icon.check}完成</button>}/>
      <div className="df-main" style={{ alignItems: 'center', justifyContent: 'center', padding: 30, gap: 18 }}>
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
          <div style={{ fontSize: 14, color: 'var(--t-3)', marginBottom: 6 }}>已释放</div>
          <div style={{
            fontSize: 56, fontWeight: 700, lineHeight: 1, letterSpacing: '-0.04em',
            background: 'linear-gradient(180deg, #fff, var(--good))',
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
          }}>12.4 GB</div>
          <p className="df-p" style={{ marginTop: 8 }}>已清理 3 类 · 用时 28 秒</p>
        </div>

        <div style={{ width: 460, display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { l: 'Xcode 构建缓存', v: '6.2 GB',  c: 'var(--cat-cache)' },
            { l: '旧的下载',       v: '3.8 GB',  c: 'var(--cat-other)' },
            { l: '重复照片',       v: '2.4 GB',  c: 'var(--cat-photo)' },
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
            <div className="df-label">健康分</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 2 }}>
              <span style={{ fontSize: 22, fontWeight: 700 }}>82</span>
              <svg width="14" height="14" viewBox="0 0 24 24"><path d="M5 12h14M13 5l7 7-7 7" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
              <span style={{ fontSize: 22, fontWeight: 700, color: 'var(--good)' }}>94</span>
              <span style={{ marginLeft: 8, fontSize: 11.5, color: 'var(--good)' }}>提升 +12</span>
            </div>
          </div>
          <button className="df-btn ghost sm">查看变更详情</button>
        </div>
      </div>
    </Frame>
  );
}

function HiFiError() {
  return (
    <Frame title="外接磁盘" sidebarActive="drives">
      <Toolbar actions={<button className="df-btn ghost sm">{Icon.refresh}重试</button>}/>
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
          <h1 className="df-h1">需要授权</h1>
          <p className="df-p" style={{ marginTop: 8, fontSize: 13 }}>
            DiskFlow 需要 <b style={{ color: 'var(--t-1)' }}>完全磁盘访问权限</b>才能扫描外接磁盘。
            请在系统设置中授予权限后重试。
          </p>
        </div>

        <div style={{ display: 'flex', gap: 10 }}>
          <button className="df-btn ghost sm">了解更多</button>
          <button className="df-btn primary">打开系统设置{Icon.arrow}</button>
        </div>

        <div className="df-card elevated" style={{ width: 480, padding: 0 }}>
          <div style={{ padding: '10px 16px', borderBottom: '1px solid var(--line-1)' }}>
            <span className="df-label">已连接的驱动器</span>
          </div>
          {[
            { n: 'Macintosh HD',  s: '312 / 512 GB',                ok: true },
            { n: 'Backup-SSD',    s: '已锁定 — 需要完全磁盘访问权限',  ok: false },
            { n: 'Time Machine',  s: '1.8 / 4 TB',                  ok: true },
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
  HiFiCleaning, HiFiEmpty, HiFiLoading, HiFiSuccess, HiFiError,
});
