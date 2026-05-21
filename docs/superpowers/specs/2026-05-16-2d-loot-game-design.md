# 2D 刷宝游戏 — 设计文档

> 生成时间：2026-05-16
> 项目：Loot Hunter
> 引擎：Godot 4.6.2 + GDScript
> 开发者：零基础，周末项目

---

## 1. 游戏概述

**一句话描述：** 正俯视 2D 暗黑Like 刷宝游戏——砍怪、爆装、变强、砍更强的怪。

**核心循环：**
```
进入地牢 → 砍怪 → 怪物掉落装备 → 捡起装备看属性 → 换上更强的 → 砍更难的怪
```

**成功标准：** 16 个周末后，有一个可玩的 demo——单一地牢、3+ 种怪物、5 级品质装备系统、背包、商店、基础技能。

---

## 2. 关键设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 视角 | 正俯视 (Top-Down) | 开发难度最低，素材匹配最容易，碰撞检测内置 |
| 美术 | 免费素材包混搭 | 零美术基础，Kenney.nl + OpenGameArt 足够 |
| 装备品质 | 绿→蓝→紫→金→暗金 | WoW 系经典配色，5 级足够有层次感 |
| 首个地图 | 单一固定地牢 | 先跑通所有系统，v2 再做随机地牢 |
| 学习方式 | 模块化跟写 | 每个系统独立学教程，最后拼合，理解最深 |
| 核心优先 | 爆装快感 | 这是游戏最上瘾的部分，优先做深 |

---

## 3. 技术架构预览

### 3.1 场景结构

```
World.tscn (主场景)
├── TileMap (地牢地图)
├── Player.tscn (玩家)
│   ├── Sprite2D
│   ├── CollisionShape2D
│   ├── Hitbox (Area2D)
│   └── Hurtbox (Area2D)
├── Enemies (Node2D)
│   ├── Enemy1.tscn (实例化)
│   ├── Enemy2.tscn (实例化)
│   └── Boss.tscn (实例化)
├── Items (Node2D)
│   └── 掉落物 (运行时动态生成)
├── UI (CanvasLayer)
│   ├── HUD (血条、经验条)
│   ├── Inventory.tscn (背包界面)
│   └── Shop.tscn (商店界面)
└── Camera2D (跟随玩家)
```

### 3.2 数据流

```
物品定义 (Resource)
    ↓ 怪物死亡时
掉落生成 (随机选择物品 + 随机品质)
    ↓ 玩家靠近按 E
捡起 → 存入 Inventory (数组)
    ↓ 打开背包点击
装备 → 修改 Player 属性 (攻击力/防御力/血量)
    ↓ 关闭背包
属性生效 → 砍怪更快/更耐打
```

### 3.3 核心类/资源

| 名称 | 类型 | 职责 |
|------|------|------|
| `Player.gd` | CharacterBody2D 脚本 | 移动、攻击、HP、属性计算 |
| `Enemy.gd` | CharacterBody2D 脚本 | AI 移动、HP、掉落逻辑 |
| `ItemData.gd` | Resource | 物品模板（名称、基础属性、图标） |
| `Inventory.gd` | Node/Singleton | 背包管理、装备/卸下 |
| `DropTable.gd` | Resource | 定义怪物掉落什么、概率多少 |
| `DamageNumber.gd` | Node2D | 飘字伤害数字 |

---

## 4. 装备系统设计

### 4.1 品质等级

| 品质 | 颜色 | 属性加成倍率 | 掉落概率 |
|------|------|-------------|---------|
| 绿色 (Uncommon) | #2ecc71 | 1.0x | 50% |
| 蓝色 (Rare) | #3498db | 1.5x | 30% |
| 紫色 (Epic) | #9b59b6 | 2.0x | 12% |
| 金色 (Legendary) | #f1c40f | 3.0x | 6% |
| 暗金 (Unique) | #e67e22 | 5.0x | 2% |

### 4.2 物品类型

**v1 只做这些：**
- 武器：剑、斧、弓（加攻击力）
- 护甲：头盔、胸甲、鞋子（加防御力）
- 饰品：戒指、项链（加血量或暴击）
- 消耗品：血瓶、蓝瓶

**v2 再加：**
- 前缀/后缀随机词缀系统
- 套装效果
- 装备等级要求

### 4.3 掉落流程

```
怪物死亡
    ↓
查 DropTable → 决定掉落什么物品类型
    ↓
随机决定品质（按概率表）
    ↓
根据品质 × 基础属性 = 最终属性
    ↓
生成 Item 节点在地面上（发光效果）
    ↓
玩家靠近 + 按 E → 捡起
```

---

## 5. 里程碑详细计划

### 里程碑 1：能动的方块（第 1-2 周末）

**目标：** 角色在地图上走起来。

| 周末 | 任务 | 学什么 | 教程关键词 |
|------|------|--------|-----------|
| W1 周六 | 安装 Godot，创建项目，了解编辑器 | 场景、节点、Inspector | "godot 4 editor tutorial" |
| W1 周日 | 创建 Player 场景，WASD 移动 | CharacterBody2D, Input, GDScript 基础 | "godot 4 characterbody2d movement" |
| W2 周六 | 创建 TileMap 地牢地图 | TileSet, TileMap, 导入素材 | "godot 4 tilemap tutorial" |
| W2 周日 | 相机跟随玩家，角色不会穿墙 | Camera2D, CollisionShape2D | "godot 4 camera follow player" |

**验收：** WASD 控制角色在地图上走，相机跟随，不穿墙。

### 里程碑 2：砍怪 + 掉血（第 3-5 周末）

**目标：** 有怪物能砍，有血条。

| 周末 | 任务 | 学什么 | 教程关键词 |
|------|------|--------|-----------|
| W3 | 创建 Enemy 场景，简单 AI（朝玩家走） | 向量 math, position | "godot 4 enemy ai follow player" |
| W4 | 玩家攻击（空格/左键），碰撞检测 | Area2D, 信号, hitbox/hurtbox | "godot 4 hitbox hurtbox" |
| W5 | HP 系统，血条 UI，怪物死亡 | 信号, 进度条, 实例化/销毁 | "godot 4 health bar ui" |

**验收：** 3+ 怪物在地图上，能砍死，玩家也会被打，有血条。

### 里程碑 3：爆装备（第 6-10 周末）⭐ 核心里程碑

**目标：** 完整的掉落→背包→装备循环。

| 周末 | 任务 | 学什么 | 教程关键词 |
|------|------|--------|-----------|
| W6 | ItemData Resource 定义物品模板 | Resource 类, @export | "godot 4 resource tutorial" |
| W7 | 掉落系统：怪物死亡随机生成物品 | 随机数, 实例化, DropTable | "godot 4 loot drop system" |
| W8 | 地面物品：发光效果，按 E 捡起 | Area2D 检测, 输入, 动画 | "godot 4 item pickup" |
| W9 | 背包 UI：Grid 显示物品列表 | GridContainer, 按钮, 信号 | "godot 4 inventory ui" |
| W10 | 装备系统：点击装备→属性变化 | 字典, 属性计算, UI 更新 | "godot 4 equipment system" |

**验收：** 怪物掉落 5 级品质装备，捡起进背包，装备后攻击力/防御力变化。

### 里程碑 4：游戏感打磨（第 11-16 周末）

**目标：** 更像一个真正的游戏。

| 周末 | 任务 | 学什么 |
|------|------|--------|
| W11-12 | 商店 NPC：卖垃圾换金币 | 对话系统, 交易 UI |
| W13-14 | 技能系统：火球术（投掷物 + 冷却） | 投掷物, Timer, 冷却 |
| W15 | 升级系统：经验条→升级→加属性 | 经验曲线, 升级事件 |
| W16 | Boss 战 + 音效 + 打磨 | 状态机, AudioStreamPlayer |

**验收：** 有商店、有技能、有升级、有 Boss，能连续玩 30 分钟。

---

## 6. 素材资源清单

### 推荐素材包（全部免费，CC0 或 CC-BY）

| 用途 | 推荐来源 | 链接 |
|------|---------|------|
| 角色/怪物 | Kenney.nl | kenney.nl/assets/category/2d |
| 地牢 TileSet | Kenney - Dungeon Tileset | kenney.nl/assets/dungeon-tileset |
| 武器/装备图标 | Kenney - RPG Pack | kenney.nl/assets/rpg-pack |
| 通用 2D 素材 | OpenGameArt.org | opengameart.org |
| 字体 | Google Fonts | fonts.google.com (选像素风) |

**素材导入流程：** 下载 → 放入 `assets/sprites/` → 在 Godot 里拖到 Sprite2D 的 Texture 属性。

---

## 7. 常见坑 & 避坑指南

| 坑 | 症状 | 怎么避 |
|---|------|--------|
| 场景不运行 | 按 F5 报错 "no main scene" | Project → Project Settings → Application → Run → Main Scene 设一下 |
| 角色穿墙 | 有 CollisionShape2D 但没用 | 确保 Player 是 CharacterBody2D，墙是 StaticBody2D |
| 信号不触发 | connect() 写错了或节点路径不对 | 用 Godot 编辑器的 Node → Signals 面板连，别手写 |
| 变量不更新 | @export 改了但没保存场景 | 改完 @export 变量后 Ctrl+S 保存场景 |
| 背包不显示 | UI 节点层级不对 | UI 必须在 CanvasLayer 下，且 viewport 设置正确 |

---

## 8. 每周开发节奏建议

```
周六（3-4 小时）：
  1. 看教程（30-60 分钟）— 不要一次看太多
  2. 跟着做（1-2 小时）— 边看边写
  3. 自己改（30 分钟）— 把教程的代码改成自己的版本

周日（2-3 小时）：
  1. 回顾上周代码（15 分钟）— 还能看懂吗？
  2. 继续做（1-2 小时）— 完成本周任务
  3. 运行测试（15 分钟）— 能跑通就是成功
```

**规则：** 每次只学一个系统。不要同时改移动 + 战斗 + 掉落。做完一个，运行一次。

---

## 9. 架构原则（写给未来的你）

1. **每个场景做一件事** — Player 管移动和 HP，Enemy 管 AI 和掉落，Inventory 管背包。不要把所有代码写在一个文件里。
2. **用信号通信** — Player 不要直接改 Enemy 的 HP。Player 发出 "attacked" 信号，Enemy 监听并处理。这是 Godot 的最佳实践。
3. **物品用 Resource 定义** — 不要硬编码物品数据。创建一个 `ItemData` Resource，在编辑器里填属性。
4. **先跑通再优化** — 第一版代码丑没关系。跑通了再重构。

---

## 10. 下一步

1. 打开 Godot，Import 项目
2. 按照里程碑 1 的 W1 任务开始
3. 卡住了随时来问

---

*文档版本：v1.0*
*下次更新：里程碑 1 完成后回顾*
