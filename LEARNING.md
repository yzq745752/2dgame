# Loot Hunter — 学习路线图

> 🎯 目标：从零开始，做出一个能玩的 2D 暗黑Like 刷宝游戏
> 🕐 节奏：周末项目，每周 4-8 小时
> 🧰 工具：Godot 4.6 + GDScript
> 📖 前提：不需要任何编程经验

---

## 总览

```
里程碑 1：能动的方块        (第 1-2 周末)  ✅ 已完成
里程碑 2：砍怪 + 掉血        (第 3-5 周末)  ← 你现在在这里
里程碑 3：爆装备 + 背包      (第 6-10 周末)
里程碑 4：游戏感打磨         (第 11-16 周末)
```

**进度：** 里程碑 1 实际完成远超原始计划（动画 + 攻击 + 地图已实现）
**原则：** 每个周末结束时，都有一个能运行的版本。不追求完美，追求「做完」。

---

## 里程碑 1：能动的方块 ✅ 已完成（远超计划）

**核心目标：** 一个角色在地图上走起来 + 攻击 + 动画。

### 实际学到的概念（按学习顺序）

| 概念 | 掌握程度 | 说明 |
|------|---------|------|
| Godot 编辑器界面 | ✅ 熟练 | 场景/节点/Inspector/FileSystem/Debugger |
| 场景和节点树 | ✅ 熟练 | CharacterBody2D, Sprite2D, CollisionShape2D, Camera2D, AnimationTree |
| GDScript 基础 | ✅ 熟练 | 变量、函数、枚举、条件、match、await |
| 输入处理 | ✅ 熟练 | Input.get_axis, is_action_pressed, _unhandled_input |
| 2D 物理 | ✅ 掌握 | move_and_slide(), velocity, CircleShape2D |
| SpriteSheet | ✅ 掌握 | hframes/vframes 分割、帧索引、Sprite2D:frame |
| AnimationTree | ✅ 入门 | StateMachine、BlendSpace2D、travel() |
| 状态机模式 | ✅ 掌握 | IDLE/RUN/ATTACK/DEAD 枚举状态 |
| TileMap/TileSet | ✅ 入门 | AtlasSource、瓦片绘制、动画瓦片 |
| Linux 双显卡 | ⚠️ 了解 | prime-run, NVIDIA Optimus, Wayland |

### 🌟 里程碑 1 实际成果

| 功能 | 文件 | 说明 |
|------|------|------|
| WASD 移动 | `player.gd` | velocity = direction * speed, move_and_slide() |
| 角色精灵 | `Warrior_Blue.png` | 6x8 SpriteSheet, 48 帧 |
| 碰撞检测 | `player.tscn` | CircleShape2D |
| 相机跟随 | `player.tscn` | Camera2D 子节点 |
| 动画系统 | `player.tscn` | AnimationTree: idle/run/attack 状态机 |
| 攻击系统 | `player.gd` | 鼠标左键, BlendSpace2D 四方向 |
| 朝向翻转 | `player.gd` | flip_h |
| 地图场景 | `test_map.tscn` | 多层 TileMap, 12 个 AtlasSource |
| 渲染器 | `project.godot` | gl_compatibility (OpenGL) |

### 当前代码

**player.gd (81 行)：**
```gdscript
extends CharacterBody2D

enum State { IDLE, RUN, ATTACK, DEAD }

@export var speed: float = 500.0
@export var attack_speed: float = 0.6

var state: State = State.IDLE
var move_direction: Vector2

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback = $AnimationTree["parameters/playback"]

func _ready():
    animation_tree.set_active(true)

func _physics_process(_delta):
    if not state == State.ATTACK:
        movement_loop()

func movement_loop():
    # 读取 WASD 输入
    move_direction.x = float(Input.is_action_pressed("right")) - float(Input.is_action_pressed("left"))
    move_direction.y = float(Input.is_action_pressed("down")) - float(Input.is_action_pressed("up"))
    velocity = move_direction.normalized() * speed
    move_and_slide()
    # 状态切换 + 动画
    if motion != Vector2.ZERO and state == State.IDLE:
        state = State.RUN
        update_animation()
    elif motion == Vector2.ZERO and state == State.RUN:
        state = State.IDLE
        update_animation()

func _unhandled_input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        attack()

func attack():
    if state == State.ATTACK: return
    state = State.ATTACK
    var attack_dir = (get_global_mouse_position() - global_position).normalized()
    animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)
    update_animation()
    await get_tree().create_timer(attack_speed).timeout
    state = State.IDLE

func update_animation():
    match state:
        State.IDLE: animation_playback.travel("idle")
        State.RUN: animation_playback.travel("run")
        State.ATTACK: animation_playback.travel("attack")
```

### 待修复

- `player.gd:41` 逻辑错误（已识别）
- Image width 0 错误（图片资源损坏待排查）
- 墙壁碰撞未实现（下一阶段做）

### ✅ 验证标准（实际）

- [x] WASD 控制角色上下左右移动
- [x] 鼠标左键攻击，四方向动画
- [x] 角色自动切换 idle/run/attack 动画
- [x] 地图有 TileMap 地面
- [x] 相机跟随玩家
- [ ] 角色不能跑出地图（墙壁待实现）
- [ ] 无报错（2 个 Image 错误待排查）

---

## 里程碑 2：砍怪 + 掉血

**核心目标：** 地图上有怪物，砍它会掉血，你也会被打。

### 你需要学的

| 新概念 | 做什么用 |
|--------|---------|
| Area2D 和信号 | 检测攻击是否打中怪物 |
| 生命值系统 | 玩家和怪物都有 HP |
| 实例化 (instantiate) | 生成多个怪物 |
| 简单的 AI | 怪物朝你走过来 |

### 第 3 周任务：能做战的 demo

1. **创建 Enemy 场景**：根节点 `CharacterBody2D`，加 Sprite2D + CollisionShape2D
2. **写一个简单的敌人 AI**：在 `_physics_process` 里让敌人朝 Player 的位置移动
3. **玩家攻击**：按空格键时，在玩家前方生成一个 `Area2D`，检测是否碰到了敌人
4. **生命值系统**：玩家和敌人各自有 HP 变量，攻击时扣 HP，HP ≤ 0 时消失

### 🌟 验证标准

- [ ] 地图上有 3+ 怪物在游荡
- [ ] 按空格/左键可以攻击，怪物会消失
- [ ] 碰到怪物玩家会掉血
- [ ] 玩家 HP 归零时游戏结束/重启

---

## 里程碑 3：爆装备 + 背包

**核心目标：** 刷宝循环的核心——砍怪、掉装备、变强。

### 你需要学的

| 新概念 | 做什么用 |
|--------|---------|
| 资源 (Resource) 类 | 定义物品模板（剑、盾、药水） |
| 随机数 | 决定爆不爆、爆什么 |
| 背包 UI | Grid 布局显示物品 |
| 拖拽/点击交互 | 装备/卸下物品 |
| 属性系统 | 装备加攻击力、防御力 |

### 🌟 验证标准

- [ ] 怪物死亡时掉落物品（在地上一道光）
- [ ] 走近按 E 捡起，进背包
- [ ] 打开背包能看到物品列表
- [ ] 点击装备 → 人物攻击力上升
- [ ] 装备有稀有度（白/蓝/金）

---

## 里程碑 4：游戏感打磨

**核心目标：** 让它更像一个"真正的游戏"。

### 你可以挑着做的

- 技能系统：火球术、旋风斩（投掷物 + 冷却时间）
- 商店 NPC：卖垃圾换金币
- 2-3 种不同怪物：近战、远程、Boss
- 升级系统：打怪涨经验 → 升级加属性
- 血条 UI：怪物头上飘血条
- 音效：砍中的声音、捡装备的声音
- 小地图

### 🌟 验证标准

- [ ] 有至少 2 种技能可以放
- [ ] 有商店可以买卖
- [ ] 有升级系统
- [ ] 有一个 Boss 战

---

## 给新手的 GDScript 速查

```gdscript
# 变量
var hp = 100
var player_name = "战士"

# 常量
const GRAVITY = 980

# 函数
func take_damage(amount):
    hp -= amount
    if hp <= 0:
        die()

# 条件
if hp <= 0:
    die()
elif hp < 30:
    print("快死了！")
else:
    print("还行")

# 循环
for enemy in enemies_on_screen:
    enemy.take_damage(10)

# 数组
var inventory = ["木剑", "药水", "金币"]
inventory.append("稀有戒指")
print(inventory[0])  # "木剑"

# 字典
var sword = {
    "name": "火焰之剑",
    "damage": 15,
    "rarity": "rare"
}
print(sword["damage"])  # 15
```

---

## 推荐学习资源

**优先看这些（最直接相关）：**

- **YouTube: "Godot 4 2D RPG Tutorial" by Brackeys** — 最好的入门系列
- **YouTube: "Godot 4 入门教程" by 开发者日志** — 中文，适合你
- **Godot 官方文档（中文）**：https://docs.godotengine.org/zh-cn/4.x/

**遇到具体问题：**
- 英文搜索：`godot 4 how to [你想做的事]`
- 中文搜索：`godot 4 [你想做的事]`
- 或者直接来问我

---

## 一些对你重要的建议

1. **别一开始就追求完美**。你的第一个角色会是个方块，没关系。暗黑2的第一个版本也是个方块。
2. **做出来的东西自己玩一下**。每次加一个新功能，运行它，走两步，感受一下。这是游戏开发最快乐的部分。
3. **保持项目能运行**。每次加一个小功能就运行一次。不要写 3 小时代码然后发现跑不起来——你会找不到 bug。
4. **卡住是正常的，不是你的问题**。每个开发者每天都会卡住。关键是知道自己卡在哪里，然后去搜或者来问。
5. **不做对比**。不要去跟 Steam 上的游戏比。你的目标不是超越别人，是比上周的自己多会一点。

---

**准备好了就去打开 Godot 吧。第一个周末的目标：让一个方块在屏幕上走起来。**
