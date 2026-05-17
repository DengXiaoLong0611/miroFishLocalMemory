# 背景报告：俄罗斯是否会在 2026-05-31 之前进入 Vasylivka

## 1. 事件对象

本市场并不直接预测“俄军会不会在 Pokrovsk 方向继续进攻”，而是预测一个更窄、更可验证的结果：

- 在 2026-05-31 截止之前
- ISW 地图是否会把 Vasylivka 的任意部分标成俄军渗透、控制、推进或过去 24 小时增益
- 且该着色至少持续一个完整日更周期

这意味着：

- 前线战斗强度高，不自动等于 YES
- 接近村庄、炮击、侦察、突击，都不自动等于 YES
- 该盘本质上是“前线战况 + 地图确认机制 + 时间窗口”的复合事件

## 2. 地理与战场意义

Vasylivka 位于顿涅茨克州、Pokrovsk 作战方向相关区域。该市场关注的是俄军是否能把局部战术活动转化为足以在 ISW 地图上留下可持续着色的结果。

对这个市场最重要的不是宏大战略叙事，而是以下三个层面：

1. 俄军是否持续把攻击轴线压到 Vasylivka 一线
2. 乌军是否能把攻击限制在“towards Vasylivka”而非“inside / control of Vasylivka”
3. ISW 或 DeepState 是否最终把这些变化落图

## 3. 为什么这不是一个简单的战场方向盘

这个市场的难点在于：

- 决议依赖地图，而不是任何一篇新闻
- 地图需要持续性，不接受单次瞬时变化
- "capture any territory" 的阈值低于“完全占领村庄”，但高于“发起攻击”

换句话说，这个盘容易被以下情况误导：

- 新闻里反复出现 “towards Vasylivka”
- 市场误把高频进攻当成即将触发 YES
- 但 ISW 一直没有给出符合标准的着色

## 4. 先验背景

与同一主题相关的前两档期限盘：

- `Will Russia enter Vasylivka by March 31, 2026?`
- `Will Russia enter Vasylivka by April 30, 2026?`

两者都已结束，且都没有触发 YES。这个历史很重要，因为它说明：

- 俄军确实长期在相关方向施压
- 但至少到 4 月底，压力尚未转化为该市场要求的地图判定事件
- 5 月 31 日盘并不是“首次出现的战场猜测”，而是建立在两次未兑现截止基础上的延长期限盘

## 5. 关键参与方

- `Russian Armed Forces`
  负责实际推进，决定是否形成地图层面的渗透/控制/增益

- `Ukrainian Armed Forces / General Staff`
  提供日常战报，常用语言是“stopped assaults towards...”，这类表述很关键，因为它通常意味着尚未形成确定控制

- `ISW Ukraine map`
  主决议源。不是普通媒体，而是触发 YES/NO 的核心裁决性信息层

- `DeepStateMap`
  当 ISW 不可用时的重要替代地图源

- `Polymarket traders`
  通过赔率对短期推进、渗透传闻、地图更新预期进行定价

## 6. 当前市场结构

截至 2026-05-17 抓取时：

- 当前市场仍 active
- 5 月 31 日盘未关闭
- 过去 24 小时有成交
- YES 价格历史从 4 月下旬高位回落后，5 月中旬重新回升到约 0.40 一线

这表明交易者没有把市场视为已基本失败，但也没有把 YES 定到高确定性区域。

## 7. 影响结果的核心变量

### 7.1 支持 YES 的变量

- Pokrovsk 方向持续高压攻击
- 乌军战报继续频繁出现 “towards Vasylivka”
- 俄军在局部形成可被 ISW 标记的渗透或短时增益
- ISW 对 infiltration / gains 的着色标准被满足并延续到下一次完整更新

### 7.2 支持 NO 的变量

- 攻击虽然频繁，但继续停留在“towards Vasylivka”
- 乌军防御把推进限制在外围接触而非地图可确认进入
- 俄军后勤、补给、燃料或攻势连续性受限
- 截止日之前没有持续性地图着色

## 8. 对 MiroFish 的建图建议

该主题适合优先抽取这些实体类型：

- Organization
- MilitaryForce
- GovernmentAgency
- MediaOutlet
- MarketDataPlatform
- WebArchiveService
- Event
- Place
- MapSource
- Deadline

最适合保留为 Agent 的节点：

- Russian Armed Forces
- Ukrainian General Staff
- ISW
- DeepStateMap
- Polymarket
- Ukrainska Pravda
- Reuters / Reuters-derived reporting

不适合直接做 Agent 的节点：

- 2026-05-31
- 48.357760 / 37.038017
- raw odds numbers
- TextEntry

