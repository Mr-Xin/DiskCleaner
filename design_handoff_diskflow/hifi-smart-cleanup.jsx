/* Hi-fi: 智能清理中心 */

function HiFiSmartCleanup() {
  // 左侧分类
  const cats = [
    { id: 'cache',    label: '应用与系统缓存',  count: 14, size: '6.8 GB', sel: 8,  active: true,  color: 'var(--cat-cache)' },
    { id: 'down',     label: '旧的下载',         count: 42, size: '3.8 GB', sel: 0,  color: 'var(--cat-other)' },
    { id: 'dupes',    label: '重复文件',         count: 128, size: '2.4 GB', sel: 0, color: 'var(--cat-photo)' },
    { id: 'large',    label: '大型未使用文件',   count: 12, size: '4.2 GB', sel: 0,  color: 'var(--cat-video)' },
    { id: 'leftover', label: '应用残留数据',     count: 8,  size: '1.6 GB', sel: 0,  color: 'var(--cat-apps)' },
    { id: 'temp',     label: '系统临时文件',     count: 56, size: '820 MB', sel: 0,  color: 'var(--cat-system)' },
  ];

  // 风险等级颜色
  const Risk = ({ level }) => {
    const map = {
      safe:    { c: 'var(--good)',   t: '安全',    bg: 'rgba(95,212,154,0.12)', br: 'rgba(95,212,154,0.4)' },
      normal:  { c: 'var(--blue-hi)', t: '一般',    bg: 'rgba(77,158,255,0.12)', br: 'rgba(77,158,255,0.4)' },
      caution: { c: 'var(--warn)',   t: '需复核',  bg: 'rgba(255,180,92,0.12)', br: 'rgba(255,180,92,0.4)' },
    };
    const x = map[level];
    return (
      <span style={{
        display: 'inline-flex', alignItems: 'center', gap: 4,
        height: 18, padding: '0 7px', borderRadius: 9,
        background: x.bg, border: '1px solid ' + x.br,
        fontSize: 10.5, fontWeight: 600, color: x.c, flexShrink: 0,
      }}>
        <span style={{ width: 4, height: 4, borderRadius: 2, background: 'currentColor', boxShadow: '0 0 4px currentColor' }}></span>
        {x.t}
      </span>
    );
  };

  // 展开的"应用与系统缓存"项目
  const cacheItems = [
    { n: 'DerivedData',         p: '~/Library/Developer/Xcode/DerivedData',         s: '6.2 GB',  a: '2 小时前',  r: 'safe',   reason: '14 个旧项目的构建产物 · 需要时会自动重建',  sel: true },
    { n: 'iOS DeviceSupport',   p: '~/Library/Developer/Xcode/iOS DeviceSupport',   s: '2.4 GB',  a: '4 个月前',  r: 'normal', reason: '已升级 iOS 设备的旧调试符号',                 sel: true },
    { n: 'Chrome/Cache',         p: '~/Library/Caches/Google/Chrome/Default/Cache',  s: '3.1 GB',  a: '今天',       r: 'safe',   reason: '浏览缓存 · 重启 Chrome 后会自动重新生成',     sel: true },
    { n: 'Slack/Cache',          p: '~/Library/Caches/com.tinyspeck.slackmacgap',    s: '1.6 GB',  a: '2 小时前',  r: 'safe',   reason: '聊天图片与文件缓存',                          sel: true },
    { n: 'Spotify/PersistentCache', p: '~/Library/Caches/com.spotify.client',        s: '1.2 GB',  a: '今天',       r: 'safe',   reason: '播放过的音频本地缓存',                        sel: true },
    { n: 'com.apple.bird',       p: '~/Library/Caches/com.apple.bird',               s: '480 MB',  a: '今天',       r: 'normal', reason: 'iCloud 同步元数据 · 重新同步会重建',         sel: true },
    { n: 'Adobe/Common/Media Cache', p: '~/Library/Caches/Adobe/Common/Media Cache',  s: '820 MB',  a: '3 周前',     r: 'safe',   reason: 'Premiere/After Effects 的媒体缓存',           sel: true },
    { n: 'WebKit/MediaCache',    p: '~/Library/Caches/com.apple.WebKit',             s: '380 MB',  a: '昨天',       r: 'safe',   reason: 'Safari 与 WebKit 应用的媒体缓存',             sel: true },
    { n: 'JetBrains/IDE Cache',  p: '~/Library/Caches/JetBrains/IntelliJIdea2024.3', s: '1.4 GB',  a: '8 天前',     r: 'caution', reason: 'IDE 索引缓存 · 删除后下次打开会较慢',         sel: false },
  ];

  return (
    <Frame title="智能清理 · DiskFlow" sidebarActive="cleanup">
      <Toolbar
        search="筛选 · 例如 size:>1GB risk:safe"
        actions={
          <>
            <button className="df-btn ghost sm">{Icon.sparkle}全选安全项</button>
            <button className="df-btn ghost sm">{Icon.filter}排序：大小 ↓</button>
          </>
        }
      />
      <div className="df-main" style={{ flexDirection: 'row', padding: 0, gap: 0, alignItems: 'stretch' }}>

        {/* 左侧分类筛选 */}
        <div style={{
          width: 240, padding: '20px 14px', display: 'flex', flexDirection: 'column', gap: 8,
          borderRight: '1px solid var(--line-1)', background: 'rgba(7,9,13,0.4)',
          backdropFilter: 'blur(20px)',
        }}>
          <div>
            <div className="df-label" style={{ marginBottom: 6, paddingLeft: 4 }}>清理建议</div>
            <div style={{ paddingLeft: 4, display: 'flex', alignItems: 'baseline', gap: 6 }}>
              <span style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.02em', color: 'var(--blue-hi)' }}>19.6 GB</span>
              <span style={{ fontSize: 11, color: 'var(--t-3)' }}>共 6 类 · 260 项</span>
            </div>
          </div>

          <div style={{ height: 1, background: 'var(--line-1)', margin: '8px 0' }}></div>

          <div className="df-label" style={{ paddingLeft: 4 }}>分类</div>
          {cats.map((c, i) => (
            <div key={i} style={{
              padding: '10px 12px',
              borderRadius: 'var(--r-md)',
              background: c.active ? 'rgba(77,158,255,0.10)' : 'transparent',
              border: '1px solid ' + (c.active ? 'rgba(77,158,255,0.25)' : 'transparent'),
              display: 'flex', flexDirection: 'column', gap: 6,
              cursor: 'default',
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ width: 8, height: 8, borderRadius: 2, background: c.color, boxShadow: `0 0 8px ${c.color}80`, flexShrink: 0 }}></span>
                <span style={{ flex: 1, fontSize: 12.5, color: c.active ? 'var(--t-1)' : 'var(--t-2)', fontWeight: c.active ? 600 : 500 }}>{c.label}</span>
                {c.sel > 0 && (
                  <span style={{ background: 'var(--blue)', color: '#fff', fontSize: 10, fontWeight: 700,
                                 padding: '1px 6px', borderRadius: 8, fontVariantNumeric: 'tabular-nums' }}>{c.sel}</span>
                )}
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', paddingLeft: 16, fontSize: 10.5, color: 'var(--t-3)' }}>
                <span>{c.count} 项</span>
                <span className="df-mono">{c.size}</span>
              </div>
            </div>
          ))}

          <div style={{ marginTop: 'auto', padding: '12px', borderRadius: 'var(--r-lg)', background: 'var(--glass-1)',
                        border: '1px solid var(--line-1)', display: 'flex', flexDirection: 'column', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <span style={{ color: 'var(--blue-hi)' }}>{Icon.shield}</span>
              <span style={{ fontSize: 11.5, fontWeight: 500 }}>安全保障</span>
            </div>
            <p style={{ margin: 0, fontSize: 10.5, color: 'var(--t-3)', lineHeight: 1.45 }}>
              所有清理都先移到废纸篓 · 30 天内可完整恢复 · 系统关键文件已自动保护。
            </p>
          </div>
        </div>

        {/* 主区 */}
        <div style={{ flex: 1, padding: 22, display: 'flex', flexDirection: 'column', gap: 14, minWidth: 0 }}>

          {/* 标题与全局筛选 */}
          <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ color: 'var(--blue-hi)' }}>{Icon.sparkle}</span>
              <h1 className="df-h1">智能清理</h1>
              <span style={{ fontSize: 12, color: 'var(--t-3)' }}>· 自动找出可释放的空间，给出风险评级</span>
            </div>
            <div style={{ display: 'flex', gap: 6 }}>
              <Chip active>全部风险</Chip>
              <Chip>仅安全</Chip>
              <Chip>需复核</Chip>
            </div>
          </div>

          {/* 分组列表 */}
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10, minHeight: 0, overflow: 'hidden' }}>

            {/* 第一组：应用与系统缓存（展开） */}
            <div className="df-card elevated" style={{ padding: 0, overflow: 'hidden' }}>
              <div style={{
                padding: '14px 18px', display: 'flex', alignItems: 'center', gap: 12,
                borderBottom: '1px solid var(--line-1)',
                background: 'linear-gradient(180deg, rgba(255,180,92,0.06), transparent)',
              }}>
                <Check on />
                <span style={{ width: 10, height: 10, borderRadius: 3, background: 'var(--cat-cache)', boxShadow: '0 0 10px var(--cat-cache)' }}></span>
                <div style={{ flex: 1 }}>
                  <h2 className="df-h2">应用与系统缓存</h2>
                  <p style={{ margin: 0, fontSize: 11.5, color: 'var(--t-3)', marginTop: 2 }}>14 项 · 应用临时数据，删除后会按需重建</p>
                </div>
                <span className="df-mono" style={{ fontSize: 16, fontWeight: 700, color: 'var(--cat-cache)' }}>6.8 GB</span>
                <span style={{ color: 'var(--t-3)', transform: 'rotate(90deg)' }}>{Icon.chevron}</span>
              </div>

              {/* 表头 */}
              <div className="df-row head" style={{ gridTemplateColumns: '32px 80px 32px 1fr 110px 110px 70px 24px' }}>
                <span></span>
                <span>风险</span>
                <span></span>
                <span>项目 · 路径</span>
                <span>说明</span>
                <span>最近访问</span>
                <span>大小</span>
                <span></span>
              </div>

              {/* 项目行 */}
              <div style={{ maxHeight: 320, overflow: 'hidden' }}>
                {cacheItems.map((it, i) => (
                  <div key={i} className={'df-row ' + (it.sel ? 'selected' : '')}
                       style={{ gridTemplateColumns: '32px 80px 32px 1fr 110px 110px 70px 24px' }}>
                    <Check on={it.sel} />
                    <Risk level={it.r} />
                    <div className="df-glyph cache" style={{ width: 22, height: 22, borderRadius: 5, fontSize: 7 }}>{it.n[0]}{it.n[1] || ''}</div>
                    <div style={{ minWidth: 0 }}>
                      <div style={{ fontSize: 12.5, color: 'var(--t-1)', fontWeight: 500, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{it.n}</div>
                      <div className="df-mono" style={{ fontSize: 10, color: 'var(--t-3)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{it.p}</div>
                    </div>
                    <span style={{ fontSize: 11, color: 'var(--t-3)', overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{it.reason}</span>
                    <span style={{ fontSize: 11, color: 'var(--t-3)' }}>{it.a}</span>
                    <span className="df-mono" style={{ fontSize: 13, color: 'var(--t-1)', fontWeight: 600 }}>{it.s}</span>
                    <span style={{ color: 'var(--t-3)' }}>{Icon.more}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* 后续分组（折叠） */}
            {[
              { l: '旧的下载',         d: '42 项 · 90 天未打开的下载', s: '3.8 GB', c: 'var(--cat-other)' },
              { l: '重复文件',         d: '42 组 · 智能挑选已就绪',     s: '2.4 GB', c: 'var(--cat-photo)' },
              { l: '大型未使用文件',   d: '12 项 · 超过 90 天未访问',   s: '4.2 GB', c: 'var(--cat-video)' },
              { l: '应用残留数据',     d: '8 项 · 已卸载应用的遗留',    s: '1.6 GB', c: 'var(--cat-apps)' },
            ].map((g, i) => (
              <div key={i} className="df-card" style={{ padding: '14px 18px', display: 'flex', alignItems: 'center', gap: 12 }}>
                <Check />
                <span style={{ width: 10, height: 10, borderRadius: 3, background: g.c, boxShadow: `0 0 10px ${g.c}80` }}></span>
                <div style={{ flex: 1 }}>
                  <h2 className="df-h2">{g.l}</h2>
                  <p style={{ margin: 0, fontSize: 11.5, color: 'var(--t-3)', marginTop: 2 }}>{g.d}</p>
                </div>
                <span className="df-mono" style={{ fontSize: 16, fontWeight: 700, color: g.c }}>{g.s}</span>
                <span style={{ color: 'var(--t-3)' }}>{Icon.chevron}</span>
              </div>
            ))}
          </div>

          {/* 浮动操作栏 */}
          <div className="df-faction">
            <Check on />
            <span style={{ fontSize: 13, fontWeight: 500 }}>已选中 8 项</span>
            <span className="df-mono" style={{ fontSize: 18, fontWeight: 700, color: 'var(--blue-hi)' }}>· 15.8 GB</span>
            <div style={{ flex: 1 }}></div>
            <span style={{ fontSize: 11, color: 'var(--t-3)' }}>
              <span style={{ color: 'var(--good)' }}>● 7 项安全</span> · <span style={{ color: 'var(--blue-hi)' }}>● 1 项一般</span>
            </span>
            <button className="df-btn ghost sm">仅勾选安全项</button>
            <button className="df-btn primary">{Icon.bolt}立即清理 15.8 GB</button>
          </div>
        </div>
      </div>
    </Frame>
  );
}

Object.assign(window, { HiFiSmartCleanup });
