# Source Registry

## S1 Polymarket Gamma API

- 用途：市场元数据、当前 outcomePrices、总成交量、流动性、未平仓量
- 链接：
  `https://gamma-api.polymarket.com/events/slug/will-russia-enter-vasylivka-by`
- 可靠度：0.92
- 备注：适合做 `MARKET_SIGNAL` 和 `RESOLUTION_RULE` 辅助源，不是前线事实源

## S2 Polymarket CLOB API

- 用途：YES token 价格时间序列
- 链接：
  `https://clob.polymarket.com/prices-history?market=94849762948484196776489774840530703889063110696739270514476879607667108495085&interval=max&fidelity=1440`
- 可靠度：0.95
- 备注：只提供价格历史，不直接提供逐点成交量与逐点未平仓量

## S3 ISW Ukraine map

- 用途：主决议源
- 链接：
  `https://storymaps.arcgis.com/stories/36a7f6a6f5a9448496de641cf64bd375`
- 可靠度：1.00（对该市场的规则层面）
- 备注：这不是一般报道源，而是本盘的触发判据

## S4 DeepStateMap

- 用途：备用地图源
- 链接：
  `https://deepstatemap.live/`
- 可靠度：0.85
- 备注：仅在 ISW 不可用时进入决议链条

## S5 Ukrainska Pravda / General Staff of Ukraine

- 用途：战报、攻击方向、攻击次数
- 样例链接：
  `https://www.pravda.com.ua/eng/news/2026/04/20/8030879/index.amp`
  `https://www.pravda.com.ua/eng/news/2026/04/21/8031041/`
  `https://www.pravda.com.ua/eng/news/2026/05/12/8034272/`
  `https://www.pravda.com.ua/eng/news/2026/05/13/8034442/index.amp`
  `https://www.pravda.com.ua/eng/news/2026/05/15/8034769/index.amp`
- 可靠度：0.78-0.82
- 备注：适合描述“towards Vasylivka”与攻击强度，但不等于地图控制确认

## S6 Syrskyi statement via Ukrainska Pravda

- 用途：兵力密度、前线压力
- 链接：
  `https://www.pravda.com.ua/eng/news/2026/05/08/8033865/`
- 可靠度：0.82

## S7 Ukrainska Pravda on Russian fuel shortages

- 用途：俄军战争机器的燃料与炼化约束
- 链接：
  `https://www.pravda.com.ua/eng/news/2026/05/12/8034334/index.amp`
- 可靠度：0.74
- 备注：这是间接变量，不是 Vasylivka 局地控制的直接证据
