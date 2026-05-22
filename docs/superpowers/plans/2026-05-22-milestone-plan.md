# 完整里程碑计划（M1-M4）

> **版本：** v2.0
> **上次更新：** 2026-05-22
> **上一个文件：** `2026-05-16-milestone-1-movable-player.md`（保留未删）
> **引擎：** Godot 4.6.2 + GDScript
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development

---

## 目录

1. [里程碑 1：能动的方块（回顾）](#里程碑-1能动的方块回顾)
2. [里程碑 2：砍怪 + 掉血](#里程碑-2砍怪--掉血第-3-5-周末)
3. [里程碑 3：爆装备](#里程碑-3爆装备第-6-10-周末)
4. [里程碑 4：游戏感打磨](#里程碑-4游戏感打磨第-11-16-周末)
5. [每周开发节奏](#每周开发节奏)
6. [避坑指南汇总](#避坑指南汇总)

---

## 里程碑 1：能动的方块（回顾）

> **当前进度：** 第 1-2 周末已完成 ✅（远超原始计划）
> **原始计划：** 方块占位图 + WASD 移动
> **实际实现：** SpriteSheet 角色 + 完整动画状态机 + 四方向攻击 + TileMap 多层地图

### 1.1 已完成功能清单

| 功能 | 状态 | 说明 |
|------|------|------|
| WASD 移动 | ✅ | CharacterBody2D, `velocity = direction × speed`, `move_and_slide()` |
| 角色 SpriteSheet | ✅ | Warrior_Blue.png (6×8=48帧) |
| 碰撞检测 | ✅ | CircleShape2D, radius=22 |
| Camera2D 跟随 | ✅ | Camera2D 作为 player 的子节点 |
| AnimationTree 状态机 | ✅ | IDLE / RUN / ATTACK / DEAD |
| 四方向攻击 (BlendSpace2D) | ✅ | 鼠标左键触发，四方向混合 |
| 朝向自动翻转 (flip_h) | ✅ | 移动 + 攻击时自动切换 |
| TileMap 多层地图 | ✅ | 12 个 AtlasSource, 5 层（Water/FoamRocks/Ground/Shadows/Plateau/Props） |
| 动画瓦片 | ✅ | 水面、灌木、树木动画 |

### 1.2 用户自行扩展的功能

以下功能是实施过程中**自行添加**的，超出原始计划：

#### SpriteSheet 与动画系统
- `Warrior_Blue.png`（6x8 帧 SpriteSheet）
- `AnimationPlayer` 管理动画库（idle / run / attack_down / attack_right / attack_up）
- `AnimationNodeStateMachine` 状态间切换（Start → idle ↔ run ↔ attack → idle）

#### BlendSpace2D 四方向攻击
- 4 个方向点：(-1,0)=左, (1,0)=右, (0,-1)=上, (0,1)=下
- 攻击方向通过鼠标位置计算 `(mouse_pos - global_position).normalized()`
- 右攻击复用左攻击帧 + `flip_h` 镜像

#### 状态机保护逻辑
- `_physics_process` 中 `if not state == State.ATTACK` 防止攻击时移动
- `attack()` 中 `if state == State.ATTACK: return` 防止重复攻击

### 1.3 当前文件结构

```
2dgame/
├── project.godot                    # 项目配置（gl_compatibility 渲染器）
├── scenes/
│   ├── player/
│   │   ├── player.tscn              # 玩家场景（207 行）
│   │   └── player.gd                # 玩家全部逻辑（81 行）
│   └── maps/
│       └── test_map.tscn            # 主场景（446 行）
├── assets/
│   ├── sprites/
│   │   └── Warrior_Blue.png         # 角色 SpriteSheet（6x8=48帧）
│   └── environment/
│       ├── tilesheets/              # 地图瓦片素材（6 张）
│       └── animated_tiles/          # 动画瓦片素材（7 张）
└── docs/superpowers/
    ├── specs/
    │   └── 2026-05-16-2d-loot-game-design.md
    └── plans/
        ├── 2026-05-16-milestone-1-movable-player.md
        └── 2026-05-22-milestone-plan.md   # ← 本文件
```

### 1.4 已有代码参考（M1 最终状态）

**`scenes/player/player.gd`（81 行）：**

```gdscript
extends CharacterBody2D

enum State {
	IDLE,
	RUN,
	ATTACK,
	DEAD
}

@export_category("Stats")
@export var speed: float = 500.0
@export var attack_speed: float = 0.6

var state: State = State.IDLE
var move_direction: Vector2 = Vector2(0.0, 0.0)

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

func _ready() -> void:
	animation_tree.set_active(true)
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		attack()
	
		
func _physics_process(_delta: float) -> void:	
	if not state == State.ATTACK:
		movement_loop()	
	
	
func movement_loop() -> void:
	move_direction.x = float(Input.is_action_pressed("right")) - float(Input.is_action_pressed("left"))
	move_direction.y = float(Input.is_action_pressed("down")) - float(Input.is_action_pressed("up"))
	var motion: Vector2 = move_direction.normalized() * speed
	velocity = motion
	move_and_slide()

	# Sprite flipping (only in idle/run)
	if state == State.IDLE or State.RUN:   # ⚠️ BUG: 应为 state == State.RUN
		if move_direction.x < -0.01:
			$Sprite2D.flip_h = true
		elif move_direction.x > 0.01:
			$Sprite2D.flip_h = false
				
	if motion != Vector2.ZERO and state == State.IDLE:
		state = State.RUN
		update_animation()
	elif motion == Vector2.ZERO and state == State.RUN:   
		state = State.IDLE
		update_animation()
		
		
func update_animation() -> void:
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.RUN:
			animation_playback.travel("run")
		State.ATTACK:
			animation_playback.travel("attack")
			
			
func attack() -> void:
	if state == State.ATTACK:
		return
	state = State.ATTACK
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	var attack_dir: Vector2 = (mouse_pos - global_position).normalized()
	$Sprite2D.flip_h = attack_dir.x < 0 and abs(attack_dir.x) >= abs(attack_dir.y)
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)
	update_animation()
	
	await get_tree().create_timer(attack_speed).timeout
	state = State.IDLE
```

**`scenes/player/player.tscn`（207 行）：** 节点树如下

```
player (CharacterBody2D)
├── Sprite2D (Warrior_Blue.png, hframes=6, vframes=8)
├── CollisionShape2D (CircleShape2D, radius=22)
├── Camera2D
├── AnimationPlayer (动画库: idle/run/attack_down/attack_right/attack_up/RESET)
└── AnimationTree (状态机: Start→idle↔run↔attack)
```

**`scenes/maps/test_map.tscn`（446 行）：** 节点树如下

```
TestMap (Node2D)
├── Water (TileMapLayer)
├── FoamRocks (TileMapLayer)
├── Ground (TileMapLayer)
├── Shadows (TileMapLayer)
├── Plateau (TileMapLayer)
├── Props (TileMapLayer)
└── player (实例: player.tscn)
```

### 1.5 剩余任务（待完成）

以下任务在 M1 阶段未完成，需要在进入 M2 前做完：

- [ ] **修复 `player.gd:41` 逻辑错误**
  ```gdscript
  # ❌ 当前错误
  if state == State.IDLE or State.RUN:
  # ✅ 改为
  if state == State.IDLE or state == State.RUN:
  ```
  影响：`State.RUN` 枚举值为 1，GDScript 视作 `true`，条件永远成立。攻击时 flip_h 仍使用上次 `move_direction`，可能造成翻转方向错误。

- [ ] **Image width 0 错误排查**
  症状：控制台报 `Image width is 0` / `Invalid image`
  位置：`assets/environment/` 下有损坏的图片资源
  修复：在 FileSystem 面板中逐个选中右键 → **Reimport**，找到报错的图片

- [ ] **添加墙壁碰撞（StaticBody2D）**

  在 `scenes/maps/test_map.tscn` 中添加四面墙壁，防止玩家走出地图边界。

  ```tscn
  [sub_resource type="RectangleShape2D" id="RectangleShape2D_wall"]
  size = Vector2(1280, 32)
  
  [node name="Walls" type="Node2D" parent="."]
  
  [node name="TopWall" type="StaticBody2D" parent="Walls"]
  position = Vector2(640, -16)
  [node name="CollisionShape2D" parent="Walls/TopWall"]
  shape = SubResource("RectangleShape2D_wall")
  
  [node name="BottomWall" type="StaticBody2D" parent="Walls"]
  position = Vector2(640, 976)
  [node name="CollisionShape2D" parent="Walls/BottomWall"]
  shape = SubResource("RectangleShape2D_wall")
  
  [sub_resource type="RectangleShape2D" id="RectangleShape2D_wall_side"]
  size = Vector2(32, 960)
  
  [node name="LeftWall" type="StaticBody2D" parent="Walls"]
  position = Vector2(-16, 480)
  [node name="CollisionShape2D" parent="Walls/LeftWall"]
  shape = SubResource("RectangleShape2D_wall_side")
  
  [node name="RightWall" type="StaticBody2D" parent="Walls"]
  position = Vector2(1296, 480)
  [node name="CollisionShape2D" parent="Walls/RightWall"]
  shape = SubResource("RectangleShape2D_wall_side")
  ```

  > **注意：** `TileMapLayer` 使用了 `position` 偏移，墙壁坐标需要手动调整。目前 test_map 的 Ground 层范围大约是 0-20 格×64px。在 Godot 编辑器中拖拽 StaticBody2D 调整位置更精确。

- [ ] **提交 Git**

  ```bash
  git add -A
  git commit -m "feat(milestone-1): player movement, camera, animation, attack, and tilemap"
  ```

### 1.6 已知问题汇总

| 问题 | 位置 | 描述 | 优先级 |
|------|------|------|--------|
| `State.IDLE or State.RUN` | player.gd:41 | 永远为 true，翻转逻辑不精确 | 🟢 低 |
| Image width 0 报错 | assets/environment/ | 图片资源损坏 | 🟡 中 |
| 无墙壁碰撞 | test_map.tscn | 玩家可走出地图 | 🔴 高（M2 前修复） |
| FIFO protocol warning | 控制台 | Wayland 下 Godot 4 的已知无害警告 | ⚪ 忽略 |

### 1.7 M1 学到的知识点

| 知识点 | 掌握程度 |
|--------|---------|
| Godot 编辑器界面操作 | 💪 熟练 |
| 场景 (Scene) 和节点 (Node) 树 | 💪 熟练 |
| GDScript 基础：变量、函数、枚举、match | 💪 熟练 |
| CharacterBody2D + `move_and_slide()` | 💪 熟练 |
| Input 输入处理（键盘 + 鼠标） | 💪 熟练 |
| Sprite2D + SpriteSheet 动画 | 💪 熟练 |
| AnimationTree + AnimationNodeStateMachine | 🧠 理解 |
| BlendSpace2D 方向混合 | 🧠 理解 |
| TileMap + TileSet 配置 | 💪 熟练 |
| 状态机设计模式 | 🧠 理解 |

---

## 里程碑 2：砍怪 + 掉血（第 3-5 周末）

### 目标

**一句话：** 有怪物能砍，有血条。

### 验收标准

- [ ] 3 种以上怪物在地图上（骷髅、史莱姆、蝙蝠）
- [ ] 怪物有简单 AI（朝玩家方向追踪移动）
- [ ] 玩家攻击可以命中怪物（Area2D 碰撞检测）
- [ ] 怪物受伤减血，血条 UI 显示
- [ ] 怪物也会攻击玩家，玩家受伤
- [ ] 怪物死亡有消失效果
- [ ] 玩家和怪物都有血条（ProgressBar）

### 视频教程关键词

| 周末 | 搜索关键词 |
|------|-----------|
| W3 | `godot 4 enemy ai follow player`, `godot 4 characterbody2d enemy` |
| W4 | `godot 4 hitbox hurtbox`, `godot 4 area2d signal`, `godot 4 melee combat` |
| W5 | `godot 4 health bar ui`, `godot 4 progressbar tutorial`, `godot 4 queue_free` |

### 新概念

| 概念 | 说明 | 难度 |
|------|------|------|
| `Area2D` + `CollisionShape2D` 区域检测 | 检测触碰但不产生物理反弹 | 🟢 易 |
| 信号 (Signal) 通信 | Godot 的发布/订阅模式，解耦组件 | 🟡 中 |
| Hitbox / Hurtbox 架构 | RPG 通用的碰撞设计模式 | 🟡 中 |
| 节点实例化与销毁 | `preload()` + `instance()` + `queue_free()` | 🟡 中 |
| `ProgressBar` + CanvasLayer UI | UI 布局基础 | 🟢 易 |
| 向量追踪 (Vector2 tracking) | 怪物朝玩家移动的数学原理 | 🟡 中 |

---

### W3：创建 Enemy 场景 + 追踪 AI（第 3 周末）

#### W3 目标

创建第一个敌人（骷髅），让它看到玩家后自动追过来。

#### W3 文件结构

```
scenes/
└── enemies/
    └── skeleton/
        ├── skeleton.tscn      # 敌人场景
        └── skeleton.gd        # 敌人 AI 脚本
assets/
└── sprites/
    └── Skeleton.png           # 骷髅 SpriteSheet（需要下载）
```

> **素材：** 从 [Kenney.nl - Top-Down Shooter](https://kenney.nl/assets/top-down-shooter) 或 [OpenGameArt.org](https://opengameart.org) 下载骷髅/怪物 SpriteSheet。如果找不到合适的，先用矩形占位图（ColorRect）代替。

#### W3 Day 1（周六上午）：创建 Enemy 基类场景

- [ ] **Step 1: 创建敌人文件夹和场景**

  创建 `scenes/enemies/` 目录。新建 `Enemy` 场景，根节点为 `CharacterBody2D`，保存为 `scenes/enemies/enemy.tscn`。

  ```tscn
  [gd_scene format=4 uid="uid://enemy_base"]
  
  [sub_resource type="RectangleShape2D" id="RectShape_enemy"]
  size = Vector2(32, 32)
  
  [node name="Enemy" type="CharacterBody2D"]
  script = ExtResource("enemy_base_gd")
  
  [node name="CollisionShape2D" type="CollisionShape2D" parent="."]
  shape = SubResource("RectShape_enemy")
  
  [node name="Sprite2D" type="Sprite2D" parent="."]
  color = Color(1, 0, 0, 1)  # 红色占位，后续换 SpriteSheet
  ```

- [ ] **Step 2: 创建 Enemy.gd 脚本**

  ```gdscript
  # scenes/enemies/enemy.gd
  extends CharacterBody2D
  
  @export_category("Stats")
  @export var speed: float = 200.0
  @export var hp: int = 30
  @export var damage: int = 10
  @export var detection_range: float = 300.0
  
  var player: CharacterBody2D = null
  
  
  func _ready() -> void:
      # 通过组 (Group) 找到玩家
      player = get_tree().get_first_node_in_group("player")
      if player == null:
          push_error("Enemy: no player found in group 'player'")
  
  
  func _physics_process(_delta: float) -> void:
      if player == null:
          return
      
      var dist: float = global_position.distance_to(player.global_position)
      if dist > detection_range:
          return  # 超出检测范围，不动
      
      # 朝玩家方向移动
      var dir: Vector2 = (player.global_position - global_position).normalized()
      velocity = dir * speed
      move_and_slide()
  ```

  别忘了在 `player.tscn` 的根节点（CharacterBody2D）添加 Groups：在场景面板选中 player → Node 选项卡 → Groups → 输入 `player` → Add。

  或者在 `player.gd` 的 `_ready()` 中添加：

  ```gdscript
  # 放在 player.gd 的 _ready() 中
  add_to_group("player")
  ```

- [ ] **Step 3: 修改 test_map.tscn，添加几个 Enemy 实例**

  ```tscn
  [ext_resource type="PackedScene" uid="uid://enemy_base" path="res://scenes/enemies/enemy.tscn" id="14_enemy"]
  
  [node name="Enemies" type="Node2D" parent="."]
  
  [node name="Skeleton1" parent="Enemies" instance=ExtResource("14_enemy")]
  position = Vector2(400, 300)
  
  [node name="Skeleton2" parent="Enemies" instance=ExtResource("14_enemy")]
  position = Vector2(600, 500)
  
  [node name="Skeleton3" parent="Enemies" instance=ExtResource("14_enemy")]
  position = Vector2(800, 200)
  ```

- [ ] **Step 4: F5 验证**

  运行后应该看到 3 个红色方块分布在在地图上。玩家接近它们 300px 范围内时，红色方块会朝玩家移动。

#### W3 Day 2（周六下午/周日上午）：美化敌人 + 碰撞体完善

- [ ] **Step 1: 替换怪物 SpriteSheet**

  下载 Kenney 的骷髅或怪物 SpriteSheet，放入 `assets/sprites/monsters/`。

  更新 `enemy.tscn` 的 Sprite2D：

  ```tscn
  [ext_resource type="Texture2D" uid="uid://skeleton_sheet" path="res://assets/sprites/monsters/Skeleton_Walk.png" id="2_skeleton"]
  
  [node name="Sprite2D" type="Sprite2D" parent="."]
  texture = ExtResource("2_skeleton")
  hframes = 8
  vframes = 1
  ```

  > 不同的 SpriteSheet 帧数不同。Godot 编辑器中打开 Sprite2D 属性面板，手动设置 hframes 和 vframes。

- [ ] **Step 2: 给敌人添加碰撞区域（用于玩家攻击检测）**

  在 `enemy.tscn` 中添加一个 Area2D 作为 hurtbox（受伤区域）：

  ```tscn
  [sub_resource type="RectangleShape2D" id="RectShape_hurtbox"]
  size = Vector2(32, 32)
  
  [node name="Hurtbox" type="Area2D" parent="."]
  [node name="CollisionShape2D" parent="Hurtbox"]
  shape = SubResource("RectShape_hurtbox")
  ```

  节点树变成：
  ```
  Enemy (CharacterBody2D)
  ├── CollisionShape2D (物理碰撞)
  ├── Sprite2D (视觉)
  └── Hurtbox (Area2D) ← 新的，用于检测攻击
      └── CollisionShape2D
  ```

- [ ] **Step 3: F5 验证**

  确认怪物外观正确，仍能追踪玩家。

#### W3 Day 3（周日下午）：多种怪物 + 最终验证

- [ ] **Step 1: 创建第二个敌人类型（史莱姆）**

  复制 `enemy.tscn` → 改名 `slime.tscn`，修改参数（更慢、更低血、更小）：

  ```gdscript
  # 直接在场景中修改 @export 变量
  # speed=120, hp=15, damage=5, detection_range=200
  ```

  也可以在 Godot 编辑器中右键 enemy.tscn → **New Inherited Scene**，减少重复工作。

- [ ] **Step 2: 在地图上放置更多敌人**

  混合放置骷髅（速度 200, HP 30）和史莱姆（速度 120, HP 15）。

- [ ] **Step 3: W3 整套跑测**

  - [x] F5 运行无报错
  - [x] 每种怪物都在地图上
  - [x] 怪物会朝玩家移动
  - [ ] 怪物碰撞不重叠（必要时加 `collision_mask` 或 `RigidBody2D`）
  - [ ] 提交 Git

  ```bash
  cd /home/wjz/Projects/2dgame
  git add scenes/enemies/
  git commit -m "feat(milestone-2): add enemy base with follow AI"
  ```

#### W3 常见坑

| 问题 | 原因 | 解决 |
|------|------|------|
| 怪物不动 | `player` 为 null | 确认 player 加到了 `"player"` Group |
| 怪物穿墙 | 没加碰撞 | 怪物也需要 CollisionShape2D + StaticBody2D 墙壁 |
| 怪物重叠在一起 | 没处理碰撞 | 可在 `move_and_slide()` 后检查碰撞，或加 `RigidBody2D` |
| SpriteSheet 显示不对 | hframes/vframes 设错 | 数一下图片的行列数，再设 |

---

### W4：玩家攻击碰撞 + 怪物受伤（第 4 周末）

#### W4 目标

玩家左键砍击能命中怪物，怪物掉血。为 M2 核心机制。

#### W4 Day 1（周六上午）：Hitbox 检测

- [ ] **Step 1: 在 player.tscn 中添加攻击 Hitbox**

  Hitbox 是一个 Area2D，当攻击动画播放时启用，检测范围内的敌人。

  ```tscn
  # 添加到 player.tscn
  [sub_resource type="RectangleShape2D" id="RectangleShape2D_hitbox"]
  size = Vector2(48, 48)
  
  [node name="Hitbox" type="Area2D" parent="."]
  monitoring = false  # 默认关闭，攻击时开启
  
  [node name="CollisionShape2D" parent="Hitbox"]
  position = Vector2(0, -32)   # 在角色前方
  shape = SubResource("RectangleShape2D_hitbox")
  ```

  节点树变成：
  ```
  player (CharacterBody2D)
  ├── Sprite2D
  ├── CollisionShape2D
  ├── Camera2D
  ├── AnimationPlayer
  ├── AnimationTree
  └── Hitbox (Area2D) ← 新的攻击检测区域
      └── CollisionShape2D
  ```

- [ ] **Step 2: 在 player.gd 中添加攻击时启用 Hitbox**

  ```gdscript
  # player.gd 新增变量
  @onready var hitbox: Area2D = $Hitbox
  
  
  # 在 attack() 函数中，攻击开始时启用 hitbox
  func attack() -> void:
      if state == State.ATTACK:
          return
      state = State.ATTACK
      
      # ... 方向计算 ...
      
      # 启用 hitbox
      hitbox.monitoring = true
      
      update_animation()
      
      await get_tree().create_timer(attack_speed).timeout
      
      # 攻击结束关闭 hitbox
      hitbox.monitoring = false
      state = State.IDLE
  ```

- [ ] **Step 3: 配置碰撞层**

  打开 Project → Project Settings → **Layer Names** → **2D Physics**：

  | Layer | Name |
  |-------|------|
  | 1 | `player` |
  | 2 | `enemy` |
  | 3 | `hitbox` |
  | 4 | `hurtbox` |

  然后配置：
  - **Player** (CharacterBody2D): Mask = enemy（碰撞物理）
  - **Hitbox** (Area2D): Mask = hurtbox（检测受伤区域）
  - **Hurtbox** (Area2D): Mask = hitbox（被检测）
  - **Enemy** (CharacterBody2D): Mask = player

  > 这部分在编辑器中操作，每个节点的 Collision → Layer / Mask 中勾选。

- [ ] **Step 4: F5 验证**

  攻击时看 Hitbox 是否正常开启/关闭。目前还不能验证命中（需要下一天的信号处理），但 Hitbox 动画应该能看到。

#### W4 Day 2（周六下午/周日上午）：信号连接 + 受伤函数

- [ ] **Step 1: 给 Enemy 添加 `take_damage()` 函数**

  ```gdscript
  # scenes/enemies/enemy.gd - 新增
  
  signal died
  
  @export var max_hp: int = 30
  
  
  func _ready() -> void:
      hp = max_hp
      # ...
  
  
  func take_damage(amount: int) -> void:
      hp -= amount
      print("Enemy took ", amount, " damage! HP left: ", hp)
      
      # 受伤闪白效果
      modulate = Color.WHITE
      await get_tree().create_timer(0.1).timeout
      modulate = Color(1, 1, 1, 1)  # 恢复正常
      
      if hp <= 0:
          die()
  
  
  func die() -> void:
      died.emit()
      queue_free()
  ```

- [ ] **Step 2: 创建 Hitbox 的信号连接**

  Hitbox 检测到敌人后，发射 `area_entered` 信号。在 player.gd 中连接：

  ```gdscript
  # player.gd _ready() 中
  func _ready() -> void:
      animation_tree.set_active(true)
      hitbox.area_entered.connect(_on_hitbox_area_entered)
  
  
  func _on_hitbox_area_entered(area: Area2D) -> void:
      # 只有攻击状态时才造成伤害
      if state != State.ATTACK:
          return
      
      var enemy = area.get_parent()
      if enemy.has_method("take_damage"):
          # 基础伤害 = 10（后续从装备系统获取）
          enemy.take_damage(10)
  ```

- [ ] **Step 3: 配置敌人 Hurtbox 的碰撞层**

  选中 enemy → Hurtbox → Collision → 
  - Layer: 勾选 `hurtbox` (4)
  - Mask: 不需要勾（被检测方不需要 mask）

  > 规则：**Hitbox** 的 Mask 勾选 **hurtbox** 层，Hurtbox 的 Layer 设为 **hurtbox** 层。

- [ ] **Step 4: F5 验证**

  走到怪物面前左键攻击 → 控制台应该输出 `"Enemy took 10 damage! HP left: 20"`。

#### W4 Day 3（周日下午）：怪物攻击玩家

- [ ] **Step 1: 给敌人添加攻击功能**

  敌人接近玩家一定距离后自动攻击：

  ```gdscript
  # enemy.gd 新增
  @export var attack_range: float = 40.0
  @export var attack_cooldown: float = 1.5
  @export var attack_damage: int = 10
  
  var can_attack: bool = true
  
  
  func _physics_process(_delta: float) -> void:
      if player == null:
          return
      
      var dist: float = global_position.distance_to(player.global_position)
      if dist > detection_range:
          return
      
      if dist > attack_range:
          # 追踪玩家
          var dir: Vector2 = (player.global_position - global_position).normalized()
          velocity = dir * speed
          move_and_slide()
      else:
          # 在攻击范围内，停止移动并攻击
          velocity = Vector2.ZERO
          if can_attack:
              try_attack_player()
  
  
  func try_attack_player() -> void:
      can_attack = false
      player.take_damage(attack_damage)  # 稍后给 player 添加 take_damage
      await get_tree().create_timer(attack_cooldown).timeout
      can_attack = true
  ```

- [ ] **Step 2: 给 Player 添加 `take_damage()`**

  ```gdscript
  # player.gd 新增
  
  @export var max_hp: int = 100
  var current_hp: int
  
  
  func _ready() -> void:
      # ... 已有代码 ...
      current_hp = max_hp
  
  
  func take_damage(amount: int) -> void:
      current_hp -= amount
      print("Player took ", amount, " damage! HP: ", current_hp)
      
      # 受伤闪烁
      modulate = Color.RED
      await get_tree().create_timer(0.1).timeout
      modulate = Color.WHITE
      
      if current_hp <= 0:
          state = State.DEAD
          print("Player died!")
  ```

- [ ] **Step 3: 限制敌人数量（可选）**

  如果 3 只怪物同时围上来太猛，可以先只放 1-2 只测试。降低 `attack_damage` 或调高玩家 `max_hp`。

- [ ] **Step 4: F5 验证**

  怪物追到玩家 → 自动攻击 → 控制台显示玩家掉血。

- [ ] **Step 5: 提交 Git**

  ```bash
  git add -A
  git commit -m "feat(milestone-2): player hitbox, enemy hurtbox, combat damage"
  ```

#### W4 常见坑

| 问题 | 原因 | 解决 |
|------|------|------|
| `area_entered` 没触发 | 碰撞层配置不对 | Hitbox Layer/Hurtbox Mask 必须匹配 |
| 攻击打中多次 | `monitoring` 一直为 true | 确认攻击结束关闭 `monitoring = false` |
| 怪物不攻击 | `attack_range` 太小或 `can_attack` 变量 | 打印 `dist` 看实际距离 |
| 玩家不掉血 | `player.take_damage` 没定义 | 先给 player.gd 添加 take_damage |
| 受伤闪白不显示 | modulate 被动画覆盖 | 用 `$Sprite2D.modulate` 替代 `modulate` |

---

### W5：HP 系统 + 血条 UI + 怪物死亡（第 5 周末）

#### W5 目标

给玩家和怪物添加可视化的血条，完善死亡效果。

#### W5 Day 1（周六上午）：玩家血条 UI

- [ ] **Step 1: 创建 UI CanvasLayer**

  新建场景 `scenes/ui/player_hud.tscn`：

  ```tscn
  [gd_scene format=4 uid="uid://player_hud"]
  
  [node name="PlayerHUD" type="CanvasLayer"]
  layer = 1
  
  [node name="HealthBarBG" type="TextureRect" parent="."]
  anchor_left = 0.5
  anchor_top = 1.0
  anchor_right = 0.5
  anchor_bottom = 1.0
  offset_left = -100.0
  offset_top = -40.0
  offset_right = 100.0
  offset_bottom = -20.0
  color = Color(0.2, 0.2, 0.2, 0.8)
  
  [node name="HealthBar" type="ProgressBar" parent="."]
  anchor_left = 0.5
  anchor_top = 1.0
  anchor_right = 0.5
  anchor_bottom = 1.0
  offset_left = -100.0
  offset_top = -40.0
  offset_right = 100.0
  offset_bottom = -20.0
  max_value = 100.0
  value = 100.0
  show_percentage = false
  modulate = Color(0, 1, 0, 1)  # 绿色血条
  ```

  > 这里用的锚点定位（anchor_* = 0.5 表示居中）。也可以用 **Control** 节点更方便。

- [ ] **Step 2: 添加血量变化时更新血条**

  在 `player.gd` 中获取 HUD 引用：

  ```gdscript
  # player.gd 新增
  @onready var health_bar: ProgressBar = get_tree().get_first_node_in_group("player_hud").get_node("HealthBar")
  ```

  > 或更简单的方式：将 HUD 作为 player 的子节点，用 `$PlayerHUD/HealthBar`。

  更好的方案：**用信号解耦** —— player 受伤时发出信号，HUD 监听。

  ```gdscript
  # player.gd 新增
  signal hp_changed(current_hp, max_hp)
  
  
  func take_damage(amount: int) -> void:
      current_hp -= amount
      hp_changed.emit(current_hp, max_hp)
      # ...
  ```

  ```gdscript
  # player_hud.gd - 新建
  extends CanvasLayer
  
  @onready var health_bar: ProgressBar = $HealthBar
  
  
  func _ready() -> void:
      var player = get_tree().get_first_node_in_group("player")
      player.hp_changed.connect(_on_player_hp_changed)
  
  
  func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
      health_bar.max_value = max_hp
      health_bar.value = current_hp
      
      # 血量低时变红
      var ratio: float = float(current_hp) / float(max_hp)
      if ratio < 0.3:
          health_bar.modulate = Color.RED
      elif ratio < 0.6:
          health_bar.modulate = Color.YELLOW
      else:
          health_bar.modulate = Color.GREEN
  ```

  将 `player_hud.tscn` 实例化到 `test_map.tscn`：

  ```tscn
  [ext_resource type="PackedScene" uid="uid://player_hud" path="res://scenes/ui/player_hud.tscn" id="15_hud"]
  
  [node name="PlayerHUD" parent="." instance=ExtResource("15_hud")]
  ```

- [ ] **Step 3: F5 验证**

  被怪物打 → 血条减少。血量低于 30% 时变红。

#### W5 Day 2（周六下午/周日上午）：怪物血条

- [ ] **Step 1: 用 AddChild 在怪物头顶动态创建血条**

  修改 `enemy.gd`：每只怪物头顶显示一个小血条。

  ```gdscript
  # enemy.gd 新增
  
  @onready var health_bar: ProgressBar = $HealthBar
  
  
  func _ready() -> void:
      hp = max_hp
      player = get_tree().get_first_node_in_group("player")
      health_bar.max_value = max_hp
      health_bar.value = hp
      health_bar.hide()  # 满血时隐藏
  
  
  func take_damage(amount: int) -> void:
      hp -= amount
      health_bar.max_value = max_hp
      health_bar.value = hp
      health_bar.show()
      
      # 受伤闪白
      $Sprite2D.modulate = Color.WHITE
      await get_tree().create_timer(0.1).timeout
      $Sprite2D.modulate = Color(1, 1, 1, 1)
      
      if hp <= 0:
          die()
  ```

  在 `enemy.tscn` 中给怪物添加血条：

  ```tscn
  [sub_resource type="StyleBoxFlat" id="StyleBox_hp_bg"]
  bg_color = Color(0.2, 0.2, 0.2, 0.6)
  
  [sub_resource type="StyleBoxFlat" id="StyleBox_hp_fill"]
  bg_color = Color(0, 1, 0, 1)
  
  [node name="HealthBar" type="ProgressBar" parent="."]
  position = Vector2(-20, -40)
  size = Vector2(40, 5)
  max_value = 30.0
  value = 30.0
  show_percentage = false
  
  [node name="ProgressBar" parent="."]  # Godot 默认子节点
  theme_override/styles/background = SubResource("StyleBox_hp_bg")
  theme_override/styles/fill = SubResource("StyleBox_hp_fill")
  ```

  为了使血条始终面向屏幕，不要旋转，在 `_process` 中始终朝上（对于 2D 俯视角可以不处理，因为玩家视角固定）。

- [ ] **Step 2: F5 验证**

  攻击怪物 → 血条减少（从绿色变红色可以后面实现）。

#### W5 Day 3（周日下午）：怪物死亡效果 + 完善

- [ ] **Step 1: 怪物死亡消失效果**

  简单的死亡动画：变红 → 缩小 → 消失。

  ```gdscript
  # enemy.gd 修改 die()
  
  func die() -> void:
      died.emit()
      set_physics_process(false)  # 停止移动
      $CollisionShape2D.disabled = true  # 禁用碰撞
      
      # 死亡动画：缩小 + 消失
      var tween: Tween = create_tween()
      tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
      tween.tween_callback(queue_free)
  ```

- [ ] **Step 2: 玩家死亡后重置（选做）**

  ```gdscript
  # player.gd 修改死亡处理
  func die() -> void:
      state = State.DEAD
      set_physics_process(false)
      print("Game Over! Restarting...")
      await get_tree().create_timer(2.0).timeout
      get_tree().reload_current_scene()
  ```

- [ ] **Step 3: 完整跑测 + 提交**

  - [ ] F5 运行，无报错
  - [ ] 3 种怪物在地图上
  - [ ] 玩家可以砍死怪物
  - [ ] 怪物会攻击玩家
  - [ ] 玩家血条正常工作
  - [ ] 怪物血条显示/隐藏
  - [ ] 怪物死亡动画
  - [ ] 玩家死亡可重新开始

  ```bash
  git add -A
  git commit -m "feat(milestone-2): health bars, enemy death, player death"
  ```

#### W5 常见坑

| 问题 | 原因 | 解决 |
|------|------|------|
| 血条不更新 | 信号没连接 | 检查 `hp_changed.connect()` |
| 血条在怪物头顶偏移 | Position 不对 | ProgressBar position 相对怪物，用 `($Sprite2D, Vector2(0, -40))` |
| 怪物死亡后 CollisionShape2D 错误 | 父节点释放了但子节点还引用 | 确认 `queue_free()` 前禁用碰撞 |
| UI 血条跟着玩家世界坐标 | CanvasLayer 位置不对 | 确保 UI 在 CanvasLayer 下，不在游戏世界节点下 |

---

## 里程碑 3：爆装备（第 6-10 周末）

### 目标

**一句话：** 完整的「掉落 → 捡起 → 背包 → 装备 → 变强」循环。

### 验收标准

- [ ] 怪物死亡后随机掉落装备（5 级品质：绿/蓝/紫/金/暗金）
- [ ] 地面上能看到掉落物（不同品质不同颜色光效）
- [ ] 玩家靠近 + 按 E 捡起物品进入背包
- [ ] 按 B 打开背包 UI（Grid 布局显示物品图标+品质）
- [ ] 点击装备 → Player 攻击力/防御力变化
- [ ] 右击卸下装备 → 属性恢复
- [ ] 捡到更好品质的装备时有反馈

### 视频教程关键词

| 周末 | 搜索关键词 |
|------|-----------|
| W6 | `godot 4 resource tutorial`, `godot 4 @export var` |
| W7 | `godot 4 loot drop system`, `godot 4 random` |
| W8 | `godot 4 item pickup area2d`, `godot 4 glow effect` |
| W9 | `godot 4 inventory grid`, `godot 4 gridcontainer` |
| W10 | `godot 4 equipment system`, `godot 4 stats` |

### 新概念

| 概念 | 说明 |
|------|------|
| `Resource` 脚本 | 在 Godot 中用类定义数据模板，创建 `.tres` 文件 |
| DropTable 概率表 | 用权重（weight）系统实现掉落概率 |
| 节点动态生成 | `preload()` + `instantiate()` 动态创建掉落物 |
| Color 动画循环 | 用 `sin()` 或 Tween 做发光脉动效果 |
| `GridContainer` 布局 | UI 网格容器，自动排列子节点 |
| 信号链 | 掉落 → 捡起 → 背包添加 → UI 更新 → 属性重算 |

---

### W6：ItemData Resource（第 6 周末）

#### W6 目标

定义装备数据模板——「铁剑」、「布甲」这类物品的数据结构。

#### W6 Day 1（周六上午）：创建 ItemData Resource 脚本

- [ ] **Step 1: 创建 Resource 脚本**

  ```gdscript
  # scripts/items/item_data.gd
  extends Resource
  
  enum ItemType { WEAPON, ARMOR, ACCESSORY, CONSUMABLE }
  enum Quality { UNCOMMON, RARE, EPIC, LEGENDARY, UNIQUE }
  
  @export_category("基础属性")
  @export var item_name: String = "Unnamed Item"
  @export var item_type: ItemType = ItemType.WEAPON
  @export var quality: Quality = Quality.UNCOMMON
  @export var icon: Texture2D  # 背包里显示的图标
  
  @export_category("战斗属性")
  @export var attack_bonus: int = 0
  @export var defense_bonus: int = 0
  @export var hp_bonus: int = 0
  
  @export_category("描述")
  @export_multiline var description: String = ""
  
  # 品质颜色表
  static func get_quality_color(quality: Quality) -> Color:
      match quality:
          Quality.UNCOMMON:   return Color("#2ecc71")  # 绿
          Quality.RARE:       return Color("#3498db")  # 蓝
          Quality.EPIC:       return Color("#9b59b6")  # 紫
          Quality.LEGENDARY:  return Color("#f1c40f")  # 金
          Quality.UNIQUE:     return Color("#e67e22")  # 暗金
  
  
  func get_quality_name() -> String:
      match quality:
          Quality.UNCOMMON:   return "Uncommon"
          Quality.RARE:       return "Rare"
          Quality.EPIC:       return "Epic"
          Quality.LEGENDARY:  return "Legendary"
          Quality.UNIQUE:     return "Unique"
  
  
  func get_quality_multiplier() -> float:
      match quality:
          Quality.UNCOMMON:   return 1.0
          Quality.RARE:       return 1.5
          Quality.EPIC:       return 2.0
          Quality.LEGENDARY:  return 3.0
          Quality.UNIQUE:     return 5.0
  ```

- [ ] **Step 2: 创建物品模板文件（.tres）**

  在 `assets/items/` 目录下创建物品模板：

  ```tscn
  # assets/items/iron_sword.tres
  [gd_resource type="Resource" format=4]
  
  [ext_resource type="Script" path="res://scripts/items/item_data.gd" id="1"]
  [ext_resource type="Texture2D" path="res://assets/sprites/icons/sword_iron.png" id="2"]
  
  [resource]
  script = ExtResource("1")
  item_name = "铁剑"
  item_type = 0  # WEAPON
  quality = 0    # UNCOMMON
  icon = ExtResource("2")
  attack_bonus = 5
  description = "一把普通的铁剑。"
  ```

  ```tscn
  # assets/items/leather_armor.tres  
  [gd_resource type="Resource" format=4]
  
  [ext_resource type="Script" path="res://scripts/items/item_data.gd" id="1"]
  [ext_resource type="Texture2D" path="res://assets/sprites/icons/armor_leather.png" id="2"]
  
  [resource]
  script = ExtResource("1")
  item_name = "皮甲"
  item_type = 1  # ARMOR
  quality = 0    # UNCOMMON
  icon = ExtResource("2")
  defense_bonus = 3
  description = "轻便的皮质护甲。"
  ```

  > 在编辑器中更方便：在 FileSystem 面板 → 右键 → **New Resource** → 选 `ItemData` → 然后修改属性。

- [ ] **Step 3: F5 验证**

  代码能编译通过。目前还没视觉效果，但 Resource 文件已可用。

#### W6 Day 2（周六下午/周日上午）：完善物品库

- [ ] **Step 1: 创建更多物品模板（5-10 个）**

  每个品质至少一个：
  - 绿装：铁剑（ATK+5）、皮甲（DEF+3）、木盾（DEF+2）
  - 蓝装：钢剑（ATK+10）、锁子甲（DEF+8）
  - 紫装：暗影之刃（ATK+20）、龙鳞甲（DEF+15）
  - 金装：王者之剑（ATK+35）、天使之袍（DEF+25, HP+50）
  - 暗金：毁灭之刃（ATK+60）、不朽战甲（DEF+40, HP+100）

#### W6 Day 3（周日下午）：代码重构——整理文件结构

- [ ] **Step 1: 创建 `scripts/` 文件夹整理脚本**

  当前脚本分散在场景文件夹中，可以开始整理：

  ```
  scripts/
  ├── items/
  │   ├── item_data.gd          # ItemData Resource（W6）
  │   ├── drop_table.gd         # 掉落概率表（W7）
  │   └── item_pickup.gd        # 地面物品拾取（W8）
  ├── ui/
  │   ├── player_hud.gd         # 玩家 HUD
  │   ├── inventory.gd          # 背包逻辑（W9）
  │   └── equipment_slot.gd     # 装备槽（W10）
  └── player/
      └── player.gd             # 已存在 → 可以搬到这里
  ```

- [ ] **Step 2: 提交**

  ```bash
  git add -A
  git commit -m "feat(milestone-3): ItemData resource and item templates"
  ```

#### W6 常见坑

| 问题 | 原因 | 解决 |
|------|------|------|
| `.tres` 文件打开是空的 | 没设置 Resource 脚本 | 创建时选 `ItemData` script，或在属性面板选 Script |
| `@export` 变量不显示在面板 | 没继承 `Resource` | `extends Resource` 必须写在第一行 |
| 图标不显示 | 路径不对 | 用 `res://` 绝对路径，确认图片在 FileSystem 中存在 |
| enum 值搞混 | `WEAPON=0` 但存的 `1` | `.tres` 中存储的是 int，用 enum 名设置，不要手写数字 |

---

### W7：掉落系统（第 7 周末）

#### W7 目标

怪物死亡时，根据概率表随机掉落一件装备。

#### W7 Day 1（周六上午）：DropTable 系统

- [ ] **Step 1: 创建 DropTable Resource**

  ```gdscript
  # scripts/items/drop_table.gd
  extends Resource
  
  class_name DropTable
  
  @export var items: Array[DropEntry] = []
  
  
  # 从掉落表中随机抽取一件
  func roll() -> ItemData:
      if items.is_empty():
          return null
      
      var total_weight: float = 0.0
      for entry in items:
          total_weight += entry.weight
      
      var roll_value: float = randf_range(0.0, total_weight)
      var cumulative: float = 0.0
      
      for entry in items:
          cumulative += entry.weight
          if roll_value <= cumulative:
              return entry.item
      
      return items[-1].item
  
  
  # 子 Resource：掉落的物品 + 权重
  func get_quality_multiplier(quality: int) -> float:
      match quality:
          0:  return 1.0   # UNCOMMON
          1:  return 1.5   # RARE
          2:  return 2.0   # EPIC
          3:  return 3.0   # LEGENDARY
          4:  return 5.0   # UNIQUE
          _:  return 1.0
  ```

  ```gdscript
  # scripts/items/drop_entry.gd  (新增)
  extends Resource
  
  class_name DropEntry
  
  @export var item_template: ItemData
  @export var weight: float = 10.0
  @export var min_quality: int = 0
  @export var max_quality: int = 4
  ```

- [ ] **Step 2: 创建品质随机函数**

  ```gdscript
  # 放在 drop_table.gd 中或单独的工具脚本
  
  # 根据品质概率表随机抽取品质
  static func roll_quality() -> int:
      var roll: float = randf()
      # 绿 50% / 蓝 30% / 紫 12% / 金 6% / 暗金 2%
      if roll < 0.50:  return 0  # UNCOMMON
      elif roll < 0.80: return 1  # RARE
      elif roll < 0.92: return 2  # EPIC
      elif roll < 0.98: return 3  # LEGENDARY
      else:             return 4  # UNIQUE
  ```

- [ ] **Step 3: 创建骷髅的 DropTable 配置**

  ```tscn
  # assets/drop_tables/skeleton_drops.tres
  [gd_resource type="Resource" format=4]
  
  [ext_resource type="Script" path="res://scripts/items/drop_table.gd" id="1"]
  [ext_resource type="Resource" path="res://assets/items/iron_sword.tres" id="2"]
  [ext_resource type="Resource" path="res://assets/items/leather_armor.tres" id="3"]
  
  [resource]
  script = ExtResource("1")
  items = [{
  "item_template": ExtResource("2"),
  "weight": 10.0,
  "min_quality": 0,
  "max_quality": 4
  }, {
  "item_template": ExtResource("3"),
  "weight": 5.0,
  "min_quality": 0,
  "max_quality": 3
  }]
  ```

#### W7 Day 2（周六下午/周日上午）：怪物死亡调用掉落

- [ ] **Step 1: 修改 enemy.gd，死亡时生成掉落**

  ```gdscript
  # enemy.gd 新增
  
  @export var drop_table: DropTable
  @onready var item_scene: PackedScene = preload("res://scenes/items/item_pickup.tscn")
  
  
  func die() -> void:
      died.emit()
      set_physics_process(false)
      $CollisionShape2D.disabled = true
      
      # 生成掉落物
      if drop_table != null and item_scene != null:
          var dropped_item: ItemData = drop_table.roll()
          if dropped_item != null:
              # 根据品质倍率调整属性
              var multiplier: float = dropped_item.get_quality_multiplier()
              var item_instance = item_scene.instantiate()
              item_instance.item_data = dropped_item
              item_instance.global_position = global_position
              get_parent().add_child(item_instance)
      
      # 死亡动画
      var tween: Tween = create_tween()
      tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
      tween.tween_callback(queue_free)
  ```

- [ ] **Step 2: 创建 `item_pickup.tscn` 场景（占位）**

  ```tscn
  # scenes/items/item_pickup.tscn
  [gd_scene format=4 uid="uid://item_pickup"]
  
  [node name="ItemPickup" type="Node2D"]
  
  [node name="Sprite2D" type="Sprite2D" parent="."]
  texture = ExtResource("placeholder_icon")
  scale = Vector2(0.5, 0.5)
  
  [node name="Area2D" type="Area2D" parent="."]
  
  [node name="CollisionShape2D" parent="Area2D"]
  shape = SubResource("RectShape2D")
  ```

  详细完善在 W8。

- [ ] **Step 3: F5 验证**

  砍死怪物 → 控制台输出掉落物品。目前地面还看不到（W8 完善）。

#### W7 Day 3（周日下午）：掉落平衡调整

- [ ] **Step 1: 调整各个怪物的 DropTable**

  骷髅（初始怪）：常见绿装，低概率蓝装
  史莱姆（弱怪）：低血量，掉落率更低
  （后续新怪物）：高几率掉落好装备

- [ ] **Step 2: 提交**

  ```bash
  git add -A
  git commit -m "feat(milestone-3): drop table system and enemy loot drops"
  ```

#### W7 常见坑

| 问题 | 原因 | 解决 |
|------|------|------|
| `randf()` 每次结果一样 | 没随机种子 | Godot 4 默认已处理，或在 `_ready()` 中 `randomize()` |
| DropTable 返回 null | items 为空 | 确认创建了 DropEntry，weight > 0 |
| 品质倍率没生效 | 没调用 `get_quality_multiplier` | roll 后检查品质并计算属性 |
| 掉落物飞出去 | `global_position` 错的 | 确认用 `global_position` 而不是 `position` |

---

### W8：地面物品（第 8 周末）

#### W8 目标

怪物掉落的物品出现在地面上，有发光效果，按 E 能捡起来。

#### W8 Day 1（周六上午）：完善地面物品场景

- [ ] **Step 1: 完善 `item_pickup.tscn`**

  ```tscn
  [gd_scene format=4 uid="uid://item_pickup"]
  
  [sub_resource type="RectangleShape2D" id="RectShape_pickup"]
  size = Vector2(32, 32)
  
  [node name="ItemPickup" type="Node2D"]
  
  [node name="Sprite2D" type="Sprite2D" parent="."]
  scale = Vector2(0.5, 0.5)
  
  [node name="Glow" type="Sprite2D" parent="."]  # 发光层
  modulate = Color(1, 1, 1, 0.3)
  scale = Vector2(0.8, 0.8)
  
  [node name="Area2D" type="Area2D" parent="."]
  [node name="CollisionShape2D" parent="Area2D"]
  shape = SubResource("RectShape_pickup")
  ```

- [ ] **Step 2: 创建 `item_pickup.gd` 脚本**

  ```gdscript
  # scripts/items/item_pickup.gd
  extends Node2D
  
  @export var item_data: ItemData : set = _set_item_data
  
  @onready var sprite: Sprite2D = $Sprite2D
  @onready var glow: Sprite2D = $Glow
  @onready var pickup_area: Area2D = $Area2D
  
  var player_nearby: bool = false
  
  
  func _ready() -> void:
      if item_data:
          update_visual()
      
      pickup_area.body_entered.connect(_on_body_entered)
      pickup_area.body_exited.connect(_on_body_exited)
  
  
  func _process(delta: float) -> void:
      # 发光脉动效果
      var pulse: float = sin(Time.get_ticks_msec() * 0.003) * 0.5 + 0.5
      glow.modulate.a = 0.2 + pulse * 0.3
      
      # 检测 E 键拾取
      if player_nearby and Input.is_action_just_pressed("interact"):
          pickup()
  
  
  func _set_item_data(value: ItemData) -> void:
      item_data = value
      update_visual()
  
  
  func update_visual() -> void:
      if not is_inside_tree():
          return
      if item_data and item_data.icon:
          sprite.texture = item_data.icon
          # 根据品质设置发光颜色
          glow.modulate = ItemData.get_quality_color(item_data.quality)
  
  
  func _on_body_entered(body: Node) -> void:
      if body.is_in_group("player"):
          player_nearby = true
          # 显示"按 E 捡起"提示（选做）
  
  
  func _on_body_exited(body: Node) -> void:
      if body.is_in_group("player"):
          player_nearby = false
  
  
  func pickup() -> void:
      if item_data == null:
          return
      
      # 发送信号给背包系统（W9 实现）
      var inventory = get_tree().get_first_node_in_group("inventory")
      if inventory and inventory.has_method("add_item"):
          var added: bool = inventory.add_item(item_data)
          if added:
              queue_free()
          else:
              print("背包已满！")
      else:
          queue_free()
  ```

- [ ] **Step 3: 添加输入映射 "interact"**

  在 Project → Input Map 中添加：
  - Action: `interact`
  - Key: **E**

#### W8 Day 2（周六下午/周日上午）：完善发光效果

- [ ] **Step 1: 品质颜色发光**

  品质越高，发光越强：

  ```gdscript
  # item_pickup.gd update_visual() 强化
  
  func update_visual() -> void:
      if not is_inside_tree():
          return
      if item_data:
          sprite.texture = item_data.icon
          var color: Color = ItemData.get_quality_color(item_data.quality)
          glow.modulate = color
          
          # 高级品质额外放大
          match item_data.quality:
              ItemData.Quality.LEGENDARY:
                  glow.scale = Vector2(1.2, 1.2)
                  sprite.scale = Vector2(0.7, 0.7)
              ItemData.Quality.UNIQUE:
                  glow.scale = Vector2(1.5, 1.5)
                  sprite.scale = Vector2(0.8, 0.8)
                  glow.self_modulate = Color(1, 1, 1, 0.6)
  ```

#### W8 Day 3（周日下午）："按 E 捡起" 提示

- [ ] **Step 1: 添加交互提示 UI**

  ```tscn
  # scenes/ui/pickup_label.tscn
  [gd_scene format=4 uid="uid://pickup_label"]
  
  [node name="PickupLabel" type="CanvasLayer"]
  
  [node name="Label" type="Label" parent="."]
  anchor_left = 0.5
  anchor_top = 0.5
  offset_left = -80.0
  offset_top = 50.0
  text = "[E] 捡起"
  theme_override/font_sizes/font_size = 16
  theme_override/colors/font_color = Color(1, 1, 1, 1)
  ```

  ```gdscript
  # scripts/ui/pickup_label.gd
  extends CanvasLayer
  
  @onready var label: Label = $Label
  
  func show_prompt(item_name: String) -> void:
      label.text = "[E] 捡起 " + item_name
      show()
      
  func hide_prompt() -> void:
      hide()
  ```

- [ ] **Step 2: 提交**

  ```bash
  git add -A
  git commit -m "feat(milestone-3): ground items with glow and E pickup"
  ```

#### W8 常见坑

| 问题 | 原因 | 解决 |
|------|------|------|
| E 键没反应 | Input Map 没配置 | Project → Input Map → 添加 `interact` → 绑定 E |
| 发光不显示 | Glow 层被遮挡 | 确认 Glow 在 Sprite2D 后面绘制 |
| `body_entered` 一直触发 | Area2D 参数不对 | 确认启用 `monitoring` = true |
| 物品生成在天上 | `global_position` 不对 | 在 `enemy.die()` 中设置 `item_instance.global_position = enemy.global_position` |
| 脉动闪烁太快 | sin 频率不对 | `Time.get_ticks_msec() * 0.003` — 数字越小越慢 |

---

### W9：背包 UI（第 9 周末）

#### W9 目标

按 B 打开背包，看到物品 Grid，能查看物品。

#### W9 Day 1（周六上午）：背包数据层

- [ ] **Step 1: 创建 Inventory 脚本**

  ```gdscript
  # scripts/ui/inventory.gd
  extends Node
  
  signal item_added(item_data: ItemData, slot_index: int)
  signal item_removed(slot_index: int)
  
  const INVENTORY_SIZE: int = 20
  
  var items: Array[ItemData] = []
  
  
  func _ready() -> void:
      items.resize(INVENTORY_SIZE)
      add_to_group("inventory")
  
  
  func add_item(item: ItemData) -> bool:
      # 找第一个空位
      for i in range(INVENTORY_SIZE):
          if items[i] == null:
              items[i] = item
              item_added.emit(item, i)
              return true
      return false  # 背包满了
  
  
  func remove_item(slot_index: int) -> void:
      if slot_index >= 0 and slot_index < INVENTORY_SIZE:
          items[slot_index] = null
          item_removed.emit(slot_index)
  
  
  func get_item(slot_index: int) -> ItemData:
      if slot_index >= 0 and slot_index < INVENTORY_SIZE:
          return items[slot_index]
      return null
  ```

- [ ] **Step 2: 将 Inventory 加入场景树**

  在 `test_map.tscn` 中添加：

  ```tscn
  [node name="Inventory" type="Node" parent="." script="res://scripts/ui/inventory.gd"]
  ```

  或者作为 Autoload（全局单例）：Project → Autoload → 选 inventory.gd。

#### W9 Day 2（周六下午/周日上午）：背包 UI 界面

- [ ] **Step 1: 创建背包场景**

  ```tscn
  # scenes/ui/inventory_panel.tscn
  [gd_scene format=4 uid="uid://inventory_panel"]
  
  [node name="InventoryPanel" type="CanvasLayer"]
  layer = 10  # 在最上层
  visible = false  # 默认隐藏
  
  [node name="Background" type="ColorRect" parent="."]
  anchor_left = 0.0
  anchor_top = 0.0
  anchor_right = 1.0
  anchor_bottom = 1.0
  color = Color(0, 0, 0, 0.5)
  
  [node name="Panel" type="Panel" parent="."]
  anchor_left = 0.3
  anchor_top = 0.2
  anchor_right = 0.7
  anchor_bottom = 0.8
  color = Color(0.15, 0.15, 0.15, 0.95)
  
  [node name="Title" type="Label" parent="Panel"]
  anchor_left = 0.0
  anchor_top = 0.0
  anchor_right = 1.0
  offset_left = 10.0
  offset_top = 10.0
  offset_right = -10.0
  offset_bottom = 30.0
  text = "背包 (B: 关闭)"
  theme_override/font_sizes/font_size = 18
  theme_override/colors/font_color = Color(1, 1, 1, 1)
  
  [node name="ItemGrid" type="GridContainer" parent="Panel"]
  anchor_left = 0.0
  anchor_top = 0.0
  anchor_right = 1.0
  anchor_bottom = 1.0
  offset_left = 10.0
  offset_top = 40.0
  offset_right = -10.0
  offset_bottom = -10.0
  columns = 5
  ```

- [ ] **Step 2: 创建背包 ItemSlot 预制件**

  ```tscn
  # scenes/ui/item_slot.tscn
  [gd_scene format=4 uid="uid://item_slot"]
  
  [node name="ItemSlot" type="PanelContainer"]
  custom_minimum_size = Vector2(48, 48)
  theme_override/styles/panel = SubResource("StyleBox_slot")
  
  [node name="Icon" type="TextureRect" parent="."]
  stretch_mode = 0  # Keep Centered
  
  [node name="QualityOverlay" type="ColorRect" parent="."]
  modulate = Color(1, 1, 1, 0.2)
  ```

- [ ] **Step 3: Inventory UI 脚本**

  ```gdscript
  # scripts/ui/inventory_panel.gd
  extends CanvasLayer
  
  @onready var item_grid: GridContainer = $Panel/ItemGrid
  @onready var inventory: Node = get_tree().get_first_node_in_group("inventory")
  
  var slot_scene: PackedScene = preload("res://scenes/ui/item_slot.tscn")
  var slots: Array = []  # 所有 slot 控件
  
  
  func _ready() -> void:
      # 创建 20 个 slot
      for i in range(20):
          var slot = slot_scene.instantiate()
          slot.slot_index = i
          item_grid.add_child(slot)
          slots.append(slot)
      
      # 监听背包变化
      if inventory:
          inventory.item_added.connect(_on_item_added)
          inventory.item_removed.connect(_on_item_removed)
      
      # 绑定 B 键开关
      # 添加到 player 的输入处理中
  
  
  func _on_item_added(item_data: ItemData, slot_index: int) -> void:
      var slot = slots[slot_index]
      slot.get_node("Icon").texture = item_data.icon
      slot.get_node("QualityOverlay").color = ItemData.get_quality_color(item_data.quality)
  
  
  func _on_item_removed(slot_index: int) -> void:
      var slot = slots[slot_index]
      slot.get_node("Icon").texture = null
      slot.get_node("QualityOverlay").color = Color.TRANSPARENT
  
  
  func toggle() -> void:
      visible = not visible
  ```

- [ ] **Step 4: 绑定 B 键开关**

  在 `player.gd` 中添加：

  ```gdscript
  # player.gd 新增
  @onready var inventory_panel: CanvasLayer = get_tree().get_first_node_in_group("inventory_panel")
  
  func _unhandled_input(event: InputEvent) -> void:
      # ... 已有攻击代码 ...
      
      if event is InputEventKey and event.keycode == KEY_B and event.pressed:
          if inventory_panel:
              inventory_panel.toggle()
  ```

  > 也可以在 `test_map.tscn` 中添加一个输入处理脚本，保持 player.gd 的职责单一。

#### W9 Day 3（周日下午）：完整测试

- [ ] **Step 1: 捡起物品 → 打开背包查看**

  杀怪 → 掉落发光物品 → 走过去按 E → 按 B 打开背包 → 看到物品

- [ ] **Step 2: 背包满时提示**

  背包 20 格满后，捡起新物品应该显示 "背包已满"。

- [ ] **Step 3: 提交**

  ```bash
  git add -A
  git commit -m "feat(milestone-3): inventory UI grid with item display"
  ```

#### W9 常见坑

| 问题 | 原因 | 解决 |
|------|------|------|
| B 键打开背包后，游戏仍在运行 | UI 没暂停 | 打开背包时 `get_tree().paused = true` |
| Grid 布局乱 | columns 不对 | 确认 GridContainer.columns = 5，或根据屏幕调整 |
| slot 不显示物品 | 信号没连接 | 检查 `inventory.item_added.connect()` |
| 背包打开后还吃输入 | _unhandled_input 没拦截 | 背包打开时 return，不吃 `_unhandled_input` |

---

### W10：装备系统（第 10 周末）

#### W10 目标

点击背包里的物品能装备上，玩家的攻击力/防御力变化。

#### W10 Day 1（周六上午）：装备槽 UI

- [ ] **Step 1: 修改 inventory_panel 添加装备槽区域**

  ```tscn
  # 在 inventory_panel.tscn 中添加
  
  [node name="EquipmentPanel" type="VBoxContainer" parent="Panel"]
  anchor_left = 0.0
  anchor_top = 0.0
  offset_left = 10.0
  offset_top = 40.0
  
  [node name="WeaponSlot" type="PanelContainer" parent="EquipmentPanel"]
  custom_minimum_size = Vector2(64, 64)
  
  [node name="Label" parent="WeaponSlot"]
  text = "武器"
  
  [node name="ArmorSlot" type="PanelContainer" parent="EquipmentPanel"]
  custom_minimum_size = Vector2(64, 64)
  
  [node name="Label" parent="ArmorSlot"]
  text = "护甲"
  
  [node name="AccessorySlot" type="PanelContainer" parent="EquipmentPanel"]
  custom_minimum_size = Vector2(64, 64)
  
  [node name="Label" parent="AccessorySlot"]
  text = "饰品"
  ```

  布局设计（伪代码）：
  ```
  ┌──────────────────────────┐
  │  背包 (B: 关闭)          │
  │                          │
  │  [武器槽] [饰品槽]       │
  │  [护甲槽]                │
  │                          │
  │  ┌──┬──┬──┬──┬──┐       │
  │  │  │  │  │  │  │       │
  │  ├──┼──┼──┼──┼──┤       │
  │  │  │  │  │  │  │       │
  │  ├──┼──┼──┼──┼──┤       │
  │  │  │  │  │  │  │       │
  │  ├──┼──┼──┼──┼──┤       │
  │  │  │  │  │  │  │       │
  ├──┴──┴──┴──┴──┴──┤       │
  │ 物品信息面板              │
  └──────────────────────────┘
  ```

#### W10 Day 2（周六下午/周日上午）：装备与卸下逻辑

- [ ] **Step 1: 给 Player 添加装备槽变量**

  ```gdscript
  # player.gd 新增
  
  signal stats_changed(atk: int, def: int, hp: int)
  
  var equipped_weapon: ItemData = null
  var equipped_armor: ItemData = null
  var equipped_accessory: ItemData = null
  
  
  func equip_item(item: ItemData) -> bool:
      match item.item_type:
          ItemData.ItemType.WEAPON:
              # 如果已有武器，先放回背包
              if equipped_weapon:
                  return_to_inventory(equipped_weapon)
              equipped_weapon = item
          ItemData.ItemType.ARMOR:
              if equipped_armor:
                  return_to_inventory(equipped_armor)
              equipped_armor = item
          ItemData.ItemType.ACCESSORY:
              if equipped_accessory:
                  return_to_inventory(equipped_accessory)
              equipped_accessory = item
          _:
              return false
      
      recalc_stats()
      return true
  
  
  func unequip_item(item: ItemData) -> void:
      match item.item_type:
          ItemData.ItemType.WEAPON:
              if equipped_weapon == item:
                  return_to_inventory(equipped_weapon)
                  equipped_weapon = null
          ItemData.ItemType.ARMOR:
              if equipped_armor == item:
                  return_to_inventory(equipped_armor)
                  equipped_armor = null
          ItemData.ItemType.ACCESSORY:
              if equipped_accessory == item:
                  return_to_inventory(equipped_accessory)
                  equipped_accessory = null
      
      recalc_stats()
  
  
  func recalc_stats() -> void:
      var atk: int = 10   # 基础攻击力
      var def: int = 5    # 基础防御力
      var hp: int = max_hp
      
      if equipped_weapon:
          atk += equipped_weapon.attack_bonus
      if equipped_armor:
          def += equipped_armor.defense_bonus
      if equipped_accessory:
          atk += equipped_accessory.attack_bonus
          def += equipped_accessory.defense_bonus
          hp += equipped_accessory.hp_bonus
      
      print("Stats - ATK:", atk, "DEF:", def, "HP:", hp)
      stats_changed.emit(atk, def, hp)
  
  
  func return_to_inventory(item: ItemData) -> void:
      var inv = get_tree().get_first_node_in_group("inventory")
      if inv:
          inv.add_item(item)
  ```

- [ ] **Step 2: 背包 slot 点击装备**

  在 `item_slot.gd` 中添加点击事件：

  ```gdscript
  # scenes/ui/item_slot.gd
  extends PanelContainer
  
  var slot_index: int = -1
  
  
  func _gui_input(event: InputEvent) -> void:
      if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
          var inventory = get_tree().get_first_node_in_group("inventory")
          var player = get_tree().get_first_node_in_group("player")
          var item = inventory.get_item(slot_index)
          
          if item and player.has_method("equip_item"):
              if player.equip_item(item):
                  inventory.remove_item(slot_index)
  ```

- [ ] **Step 3: 装备后 UI 更新**

  装备后，装备槽显示当前装备的图标。

#### W10 Day 3（周日下午）：完整验证

- [ ] **Step 1: 跑通完整循环**

  砍怪 → 掉落 → 捡起 → B 打开背包 → 左键点击物品装备 → 关闭背包 → 砍怪（攻击力提升）

- [ ] **Step 2: 卸下装备**

  在装备槽右键/双击卸下，回到背包。

- [ ] **Step 3: 提交**

  ```bash
  git add -A
  git commit -m "feat(milestone-3): equipment system with stat recalculation"
  ```

#### W10 常见坑

| 问题 | 原因 | 解决 |
|------|------|------|
| 装备后攻击力没变 | `recalc_stats()` 没调用 | 在攻击函数中用 `stats_changed` 获取攻击力 |
| 装备消失 | 没正确处理替换 | 装备已有物品时，先放回背包再装备新的 |
| 点击背包格子没反应 | `_gui_input` 没触发 | 确认 PanelContainer 的 `mouse_filter` = MOUSE_FILTER_STOP |
| 装备 UI 不更新 | 信号没连接 | 装备/卸下时 emit 信号更新 UI |

---

## 里程碑 4：游戏感打磨（第 11-16 周末）

### 目标

**一句话：** 更像一个真正的游戏，而不只是一个技术 demo。

### 验收标准

- [ ] 有商店 NPC，可以卖垃圾装备换金币
- [ ] 有火球技能（有冷却、投掷物、打中敌人会爆炸）
- [ ] 击杀怪物获得经验，升级后攻击/防御/血量提升
- [ ] 有 Boss 战（至少 2 个阶段，有特殊攻击模式）
- [ ] 有背景音乐 + 音效（砍怪声、捡宝声、升级声）
- [ ] **能连续玩 30 分钟不无聊**

### 视频教程关键词

| 周末 | 搜索关键词 |
|------|-----------|
| W11-12 | `godot 4 npc dialogue`, `godot 4 shop ui`, `godot 4 economy system` |
| W13-14 | `godot 4 fireball projectile`, `godot 4 rigidbody2d`, `godot 4 cooldown timer` |
| W15 | `godot 4 experience system`, `godot 4 level up`, `godot 4 exp curve` |
| W16 | `godot 4 boss fight`, `godot 4 boss state machine`, `godot 4 audiostreamplayer` |

### 新概念

| 概念 | 说明 |
|------|------|
| NPC 对话与交易系统 | 用 Area2D 检测玩家接近，弹出对话菜单 |
| 投掷物物理 | `RigidBody2D` + 线性速度 + 碰撞爆炸 |
| 技能冷却 (Cooldown) | `Timer` 节点 + CD UI |
| 经验曲线公式 | 用数学函数控制升级所需经验 |
| 多阶段 Boss AI | 最复杂的状态机——血量阶段切换攻击模式 |
| 音频集成 | `AudioStreamPlayer` + 音效触发时机 |
| 粒子效果 | `GPUParticles2D` 火焰、爆炸等 |

---

### W11-12：商店 NPC（第 11-12 周末）

#### W11-12 目标

一个 NPC 商人，玩家靠近后按 E 打开商店，可以卖装备换金币。

#### W11-12 Day 1（第 11 周六上午）：NPC 基础

- [ ] **Step 1: 创建 NPC 场景**

  ```tscn
  # scenes/npcs/merchant.tscn
  [gd_scene format=4 uid="uid://merchant"]
  
  [sub_resource type="RectangleShape2D" id="RectShape_npc"]
  size = Vector2(32, 32)
  
  [node name="Merchant" type="StaticBody2D"]
  
  [node name="Sprite2D" type="Sprite2D" parent="."]
  texture = ExtResource("merchant_sprite")
  
  [node name="CollisionShape2D" type="CollisionShape2D" parent="."]
  shape = SubResource("RectShape_npc")
  
  [node name="InteractionArea" type="Area2D" parent="."]
  [node name="CollisionShape2D" parent="InteractionArea"]
  shape = SubResource("RectShape_npc")
  scale = Vector2(2, 2)  # 更大的交互范围
  ```

- [ ] **Step 2: NPC 对话脚本**

  ```gdscript
  # scripts/npcs/merchant.gd
  extends StaticBody2D
  
  @onready var interaction_area: Area2D = $InteractionArea
  
  var player_nearby: bool = false
  
  
  func _ready() -> void:
      interaction_area.body_entered.connect(_on_body_entered)
      interaction_area.body_exited.connect(_on_body_exited)
  
  
  func _process(_delta: float) -> void:
      if player_nearby and Input.is_action_just_pressed("interact"):
          open_shop()
  
  
  func _on_body_entered(body: Node) -> void:
      if body.is_in_group("player"):
          player_nearby = true
          # 显示 "[E] 交易"
  
  
  func _on_body_exited(body: Node) -> void:
      if body.is_in_group("player"):
          player_nearby = false
          close_shop()
  
  
  func open_shop() -> void:
      var shop_ui = get_tree().get_first_node_in_group("shop_ui")
      if shop_ui:
          shop_ui.show()
      get_tree().paused = true
  
  
  func close_shop() -> void:
      var shop_ui = get_tree().get_first_node_in_group("shop_ui")
      if shop_ui:
          shop_ui.hide()
      get_tree().paused = false
  ```

- [ ] **Step 3: 在地图上放置 NPC**

  ```tscn
  # 在 test_map.tscn 中添加
  [ext_resource type="PackedScene" uid="uid://merchant" path="res://scenes/npcs/merchant.tscn" id="16_merchant"]
  
  [node name="Merchant" parent="." instance=ExtResource("16_merchant")]
  position = Vector2(640, 480)
  ```

#### W11-12 Day 2：商店 UI

- [ ] **Step 1: 创建商店 UI**

  ```tscn
  # scenes/ui/shop_panel.tscn
  [gd_scene format=4 uid="uid://shop_panel"]
  
  [node name="ShopPanel" type="CanvasLayer"]
  layer = 10
  visible = false
  
  [node name="Background" type="ColorRect" parent="."]
  anchor_left = 0.0
  anchor_top = 0.0
  anchor_right = 1.0
  anchor_bottom = 1.0
  color = Color(0, 0, 0, 0.5)
  
  [node name="Panel" type="Panel" parent="."]
  anchor_left = 0.2
  anchor_top = 0.2
  anchor_right = 0.8
  anchor_bottom = 0.8
  color = Color(0.15, 0.15, 0.15, 0.95)
  
  [node name="Title" type="Label" parent="Panel"]
  offset_left = 20.0
  offset_top = 20.0
  text = "商人 - 按 E 卖出选中物品"
  
  [node name="InventoryGrid" type="GridContainer" parent="Panel"]
  offset_left = 20.0
  offset_top = 60.0
  columns = 5
  
  [node name="GoldLabel" type="Label" parent="Panel"]
  anchor_right = 1.0
  offset_right = -20.0
  offset_top = 20.0
  text = "金币: 0"
  horizontal_alignment = 2  # RIGHT
  ```

- [ ] **Step 2: 金币系统**

  ```gdscript
  # player.gd 新增
  @export var gold: int = 0
  ```

  商店卖出逻辑：点击背包中物品 → 获得金币（物品品质越高越贵）→ 物品从背包移除。

  ```gdscript
  # shop_panel.gd
  func sell_item(slot_index: int) -> void:
      var inventory = get_tree().get_first_node_in_group("inventory")
      var player = get_tree().get_first_node_in_group("player")
      var item = inventory.get_item(slot_index)
      
      if item == null:
          return
      
      # 根据品质定价
      var price: int = _get_item_price(item)
      player.gold += price
      inventory.remove_item(slot_index)
      print("售出 ", item.item_name, " +", price, "金币")
  
  
  func _get_item_price(item: ItemData) -> int:
      match item.quality:
          ItemData.Quality.UNCOMMON:  return 10
          ItemData.Quality.RARE:      return 25
          ItemData.Quality.EPIC:      return 60
          ItemData.Quality.LEGENDARY: return 150
          ItemData.Quality.UNIQUE:    return 400
          _:                          return 5
  ```

#### W11-12 常见坑

| 问题 | 原因 | 解决 |
|------|------|------|
| 打开商店后游戏暂停，但 UI 输入也停了 | pause_mode 不对 | 商店 UI 节点设置 `process_mode = ALWAYS` |
| NPC 对话瞬间开/关 | `body_entered/body_exited` 反复触发 | 加一个 cooldown 或状态锁 |
| 卖出后金币数字不更新 | UI 没刷新 | `gold_changed` 信号更新 Label |

---

### W13-14：技能系统（第 13-14 周末）

#### W13-14 目标

火球术——按 Q 发射火球，飞行过程中碰到怪物爆炸。

#### W13-14 Day 1（第 13 周六上午）：火球投掷物

- [ ] **Step 1: 创建火球场景**

  ```tscn
  # scenes/abilities/fireball.tscn
  [gd_scene format=4 uid="uid://fireball"]
  
  [sub_resource type="CircleShape2D" id="CircleShape_fireball"]
  radius = 8.0
  
  [node name="Fireball" type="RigidBody2D"]
  gravity_scale = 0.0  # 不受重力影响
  linear_damp = 0.0    # 不减速
  collision_mask = 4   # enemy 层
  
  [node name="Sprite2D" type="Sprite2D" parent="."]
  modulate = Color(1, 0.3, 0, 1)  # 橙色
  scale = Vector2(0.5, 0.5)
  
  [node name="CollisionShape2D" parent="."]
  shape = SubResource("CircleShape_fireball")
  
  [node name="Hitbox" type="Area2D" parent="."]
  monitoring = true
  
  [node name="CollisionShape2D" parent="Hitbox"]
  shape = SubResource("CircleShape_fireball")
  ```

  ```gdscript
  # scripts/abilities/fireball.gd
  extends RigidBody2D
  
  var speed: float = 500.0
  var damage: int = 25
  var direction: Vector2 = Vector2.RIGHT
  
  
  func _ready() -> void:
      linear_velocity = direction * speed
      $Hitbox.area_entered.connect(_on_hit_area)
      
      # 自动销毁（5 秒后）
      await get_tree().create_timer(5.0).timeout
      explode()
  
  
  func _on_hit_area(area: Area2D) -> void:
      var enemy = area.get_parent()
      if enemy.has_method("take_damage"):
          enemy.take_damage(damage)
          explode()
  
  
  func explode() -> void:
      # 爆炸特效（后续加粒子系统）
      queue_free()
  ```

- [ ] **Step 2: 玩家发射火球**

  ```gdscript
  # player.gd 新增
  
  var fireball_scene: PackedScene = preload("res://scenes/abilities/fireball.tscn")
  
  var fireball_cooldown: bool = false
  
  
  func _unhandled_input(event: InputEvent) -> void:
      # ... 已有攻击代码 ...
      
      if event is InputEventKey and event.keycode == KEY_Q and event.pressed:
          if not fireball_cooldown:
              cast_fireball()
  
  
  func cast_fireball() -> void:
      if fireball_cooldown:
          return
      
      fireball_cooldown = true
      
      var fireball = fireball_scene.instantiate()
      fireball.direction = (get_global_mouse_position() - global_position).normalized()
      fireball.global_position = global_position
      get_parent().add_child(fireball)
      
      # 冷却 3 秒
      await get_tree().create_timer(3.0).timeout
      fireball_cooldown = false
  ```

#### W13-14 Day 2（第 14 周六上午）：技能冷却 UI

- [ ] **Step 1: 添加技能冷却 UI**

  ```tscn
  # scenes/ui/skill_bar.tscn
  [gd_scene format=4 uid="uid://skill_bar"]
  
  [node name="SkillBar" type="CanvasLayer"]
  
  [node name="FireballSlot" type="PanelContainer" parent="."]
  anchor_left = 0.5
  anchor_top = 1.0
  anchor_right = 0.5
  anchor_bottom = 1.0
  offset_left = -30.0
  offset_top = -100.0
  offset_right = 30.0
  offset_bottom = -70.0
  
  [node name="Icon" type="TextureRect" parent="FireballSlot"]
  texture = ExtResource("fireball_icon")
  
  [node name="CooldownOverlay" type="ColorRect" parent="FireballSlot"]
  color = Color(0, 0, 0, 0.6)
  visible = false
  
  [node name="CooldownLabel" type="Label" parent="FireballSlot"]
  anchor_left = 0.5
  anchor_top = 0.5
  text = "3"
  ```

  ```gdscript
  # scripts/ui/skill_bar.gd
  extends CanvasLayer
  
  @onready var cooldown_overlay: ColorRect = $FireballSlot/CooldownOverlay
  @onready var cooldown_label: Label = $FireballSlot/CooldownLabel
  
  
  func start_cooldown(duration: float) -> void:
      cooldown_overlay.show()
      var remaining: float = duration
      while remaining > 0:
          cooldown_label.text = str(ceil(remaining))
          await get_tree().create_timer(0.5).timeout
          remaining -= 0.5
      cooldown_overlay.hide()
      cooldown_label.text = ""
  ```

#### W13-14 Day 3（第 14 周日下午）：技能伤害和碰撞完善

- [ ] **Step 1: 装饰火球效果（粒子系统）**

  在 fireball 上加 GPUParticles2D：

  ```tscn
  [node name="FireParticles" type="GPUParticles2D" parent="."]
  amount = 8
  lifetime = 0.5
  emitting = true
  one_shot = false
  local_coords = true
  process_material = SubResource("ParticleProcessMaterial_fire")
  ```

  粒子材质预设可以从 Godot 的 ParticleLibrary 中复制，或搜 `godot 4 fire particle`。

- [ ] **Step 2: 提交**

  ```bash
  git add -A
  git commit -m "feat(milestone-4): fireball skill with cooldown UI"
  ```

#### W13-14 常见坑

| 问题 | 原因 | 解决 |
|------|------|------|
| 火球不动 | `linear_velocity` 没设置 | 确认 `direction` 是归一化向量（`normalized()`） |
| 火球穿过怪物而不爆炸 | Layer/Mask 不对 | Fireball 的 mask 要勾选 `enemy` 层 |
| 火球打到玩家自己 | 默认碰撞 | 设置 `collision_mask` 只包含 `enemy`，不包含 `player` |
| Q 键不触发 | Input 优先级冲突 | 检查 `_unhandled_input` 是否被其他节点拦截 |
| CD UI 不同步 | 时间计算方式不同 | 用 `Timer` 节点替代 `await + create_timer` 更精确 |

---

### W15：升级系统（第 15 周末）

#### W15 目标

砍怪获得经验 → 经验条满 → 升级 → 攻击/防御/血量提升。

#### W15 Day 1（周六上午）：经验系统

- [ ] **Step 1: Player 添加经验相关变量**

  ```gdscript
  # player.gd 新增
  
  signal leveled_up(new_level: int)
  
  @export var level: int = 1
  @export var exp: int = 0
  @export var exp_to_next: int = 100
  
  var base_atk: int = 10
  var base_def: int = 5
  var base_hp: int = 100
  var current_hp: int
  var max_hp: int = 100
  
  
  func gain_exp(amount: int) -> void:
      exp += amount
      print("获得 ", amount, " 经验 (", exp, "/", exp_to_next, ")")
      
      while exp >= exp_to_next:
          level_up()
  
  
  func level_up() -> void:
      exp -= exp_to_next
      level += 1
      exp_to_next = calculate_exp_for_level(level)
      
      # 属性增长
      max_hp += 10
      base_atk += 2
      base_def += 1
      
      # 升级时回满血
      current_hp = max_hp
      
      print("升级! 等级 ", level)
      leveled_up.emit(level)
      recalc_stats()
  
  
  static func calculate_exp_for_level(lvl: int) -> int:
      # 简单曲线：100 + (level-1) * 50
      return 100 + (lvl - 1) * 50
  ```

- [ ] **Step 2: 怪物死亡时给玩家经验**

  ```gdscript
  # enemy.gd die() 中
  func die() -> void:
      # ...
      var player = get_tree().get_first_node_in_group("player")
      if player and player.has_method("gain_exp"):
          player.gain_exp(exp_reward)
      # ...
  ```

  在 enemy 上添加 `@export var exp_reward: int = 15`。

#### W15 Day 2（周六下午/周日上午）：经验条 UI

- [ ] **Step 1: 在 HUD 中添加经验条**

  ```tscn
  # 在 player_hud.tscn 中添加
  
  [node name="ExpBar" type="ProgressBar" parent="."]
  anchor_left = 0.5
  anchor_top = 1.0
  anchor_right = 0.5
  anchor_bottom = 1.0
  offset_left = -100.0
  offset_top = -60.0
  offset_right = 100.0
  offset_bottom = -45.0
  max_value = 100.0
  value = 0.0
  modulate = Color(0, 0.5, 1, 1)  # 蓝色经验条
  show_percentage = false
  ```

  ```gdscript
  # player_hud.gd 更新
  func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
      # ... 已有血条逻辑 ...
  
  func _on_player_exp_changed(current_exp: int, exp_to_next: int) -> void:
      health_bar.max_value = exp_to_next  # 复用变量名，或用独立 exp_bar
      health_bar.value = current_exp
  ```

  > 实际应创建独立的 `exp_bar` 变量，不要和血条混用。

#### W15 Day 3（周日下午）：升级视觉效果

- [ ] **Step 1: 升级时的视觉反馈**

  升级时光效 + 音效：

  ```gdscript
  # player.gd 升级函数末尾
  
  func level_up() -> void:
      # ... 属性增长 ...
      
      # 升级闪光
      modulate = Color(1, 1, 0.5, 1)
      await get_tree().create_timer(0.3).timeout
      modulate = Color.WHITE
      
      print("升级! 等级 ", level)
      leveled_up.emit(level)
  ```

- [ ] **Step 2: 平衡测试**

  测试砍多少只怪能升一级。如果太快，调高 `exp_to_next` 或降低 `exp_reward`。如果太慢，反之。

  > 初始怪 exp_reward=15，第一次升级需要 100 exp，约 7 只怪。10 级后需要 100 + 9×50 = 550 exp，约 37 只怪。

- [ ] **Step 3: 提交**

  ```bash
  git add -A
  git commit -m "feat(milestone-4): level-up system with exp bar and stat growth"
  ```

#### W15 常见坑

| 问题 | 原因 | 解决 |
|------|------|------|
| 经验条不涨 | `gain_exp` 没调用 | 检查怪物 `die()` 中是否调用了 `player.gain_exp()` |
| 升一级后属性没变 | `recalc_stats()` 没调用 | `level_up()` 末尾加上 `recalc_stats()` |
| 升级太快/太慢 | 经验曲线不合适 | 调 `exp_reward` 或 `calculate_exp_for_level` 公式 |
| 经验条 UI 逻辑错误 | 变量引用错了 | 创建独立的 `exp_bar`，不要复用 health_bar |

---

### W16：Boss 战 + 音效 + 打磨（第 16 周末）

#### W16 目标

有一个 Boss 房间，Boss 有 2 个阶段，加入音效和背景音乐，做最终打磨。

#### W16 Day 1（周六上午）：Boss 场景

- [ ] **Step 1: 创建 Boss 敌人**

  继承 Enemy 场景，覆盖关键属性：

  ```gdscript
  # scenes/enemies/boss_skeleton.gd
  extends "res://scenes/enemies/enemy.gd"
  
  @export var phase: int = 1
  
  
  func _ready() -> void:
      # Boss 属性远强于普通怪
      max_hp = 500
      hp = max_hp
      speed = 150
      damage = 25
      exp_reward = 200
      detection_range = 600
      
      health_bar.max_value = max_hp
      health_bar.value = hp
      health_bar.show()  # Boss 一直显示血条
      health_bar.scale = Vector2(2, 1)  # 血条更宽
      
      super._ready()
  
  
  func take_damage(amount: int) -> void:
      super.take_damage(amount)
      
      # 检查阶段切换
      var hp_ratio: float = float(hp) / float(max_hp)
      if hp_ratio <= 0.5 and phase == 1:
          enter_phase2()
  
  
  func enter_phase2() -> void:
      phase = 2
      speed = 250  # 狂暴加速
      damage = 40  # 伤害翻倍
      
      print("Boss 进入第二阶段！")
      # 视觉反馈：变红
      modulate = Color(1, 0.3, 0.3, 1)
  ```

  > **Boss 第二阶段可选扩展：**
  > - 阶段 2 时召唤小怪
  > - 阶段 2 时发射火球弹幕
  > - 阶段 2 时有地面 AOE 预警圈

- [ ] **Step 2: 优化 Boss 攻击方式**

  Boss 应该距离较远时也发射投射物：

  ```gdscript
  # boss_skeleton.gd
  func try_attack_player() -> void:
      can_attack = false
      
      # 半血前近战攻击，半血后远程攻击
      var dist: float = global_position.distance_to(player.global_position)
      if phase == 1 and dist < attack_range:
          # 近战
          player.take_damage(damage)
      elif phase == 2:
          # 发射火球
          shoot_fireball()
      
      await get_tree().create_timer(attack_cooldown).timeout
      can_attack = true
  
  
  func shoot_fireball() -> void:
      var fireball = preload("res://scenes/abilities/fireball.tscn").instantiate()
      fireball.damage = damage
      fireball.direction = (player.global_position - global_position).normalized()
      fireball.global_position = global_position
      get_parent().add_child(fireball)
  ```

#### W16 Day 2（周六下午/周日上午）：音效系统

- [ ] **Step 1: 添加背景音乐**

  ```gdscript
  # 在 test_map.tscn 中添加 BGM 节点
  
  [node name="BGM" type="AudioStreamPlayer2D" parent="."]
  stream = ExtResource("bgm_dungeon")
  autoplay = true
  volume_db = -10.0
  ```
  
  下载免费背景音乐（如 [OpenGameArt - Dungeon Music](https://opengameart.org) 或 [Pixabay Music](https://pixabay.com/music/)），放入 `assets/audio/bgm/`。

- [ ] **Step 2: 添加音效**

  音效列表：

  | 事件 | 音效 | 位置 |
  |------|------|------|
  | 玩家攻击 | `sword_swing.wav` | player.gd `attack()` |
  | 怪物受伤 | `hit_enemy.wav` | enemy.gd `take_damage()` |
  | 怪物死亡 | `enemy_die.wav` | enemy.gd `die()` |
  | 捡起物品 | `pickup.wav` | item_pickup.gd `pickup()` |
  | 升级 | `level_up.wav` | player.gd `level_up()` |
  | 购买/出售 | `coin.wav` | shop_panel.gd |

  ```gdscript
  # 音效工具脚本（选做）
  # scripts/utils/sound_manager.gd
  extends Node
  
  @onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
  
  
  func play_sound(sound: AudioStream) -> void:
      audio_player.stream = sound
      audio_player.play()
  ```

  最简方式——在每个脚本中直接使用 `$AudioStreamPlayer2D`：

  ```gdscript
  # player.gd attack() 中添加
  $AudioStreamPlayer2D.play()  # 需要提前在场景中添加 AudioStreamPlayer2D 节点并设置 stream
  ```

#### W16 Day 3（周日下午）：最终打磨 + 完整跑测

- [ ] **Step 1: 游戏开场屏幕**

  ```tscn
  # scenes/ui/title_screen.tscn
  [gd_scene format=4 uid="uid://title_screen"]
  
  [node name="TitleScreen" type="CanvasLayer"]
  
  [node name="Title" type="Label" parent="."]
  anchor_left = 0.5
  anchor_top = 0.3
  text = "Loot Hunter"
  theme_override/font_sizes/font_size = 48
  
  [node name="Subtitle" type="Label" parent="."]
  anchor_left = 0.5
  anchor_top = 0.4
  text = "按 Enter 开始"
  theme_override/font_sizes/font_size = 18
  
  [node name="PressEnter" type="Label" parent="."]
  anchor_left = 0.5
  anchor_top = 0.6
  text = "WASD 移动 | 鼠标左键攻击 | Q 火球 | E 交互 | B 背包"
  theme_override/font_sizes/font_size = 14
  ```

  标题屏幕脚本：

  ```gdscript
  # scripts/ui/title_screen.gd
  extends CanvasLayer
  
  func _ready() -> void:
      get_tree().paused = true
  
  
  func _process(_delta: float) -> void:
      if Input.is_action_just_pressed("ui_accept"):  # Enter/Space
          get_tree().paused = false
          queue_free()
  ```

  在 `Project → Main Scene` 指向标题屏幕，标题屏幕中加载 `test_map.tscn`。

- [ ] **Step 2: 最终 30 分钟测试**

  - 从标题进入游戏
  - 砍怪、爆装、捡起、装备
  - 打到 Boss、切换阶段
  - 升级、成长
  - 回到商店卖垃圾
  - 连续玩 30 分钟，记录任何无聊的地方或 bug

- [ ] **Step 3: 最终提交**

  ```bash
  git add -A
  git commit -m "feat(milestone-4): boss fight, audio, title screen, final polish"
  ```

#### W16 常见坑

| 问题 | 原因 | 解决 |
|------|------|------|
| Boss 不切换阶段 | HP 比例判断没触发 | 打印 `hp_ratio` 和 `phase` 检查逻辑 |
| 音效不播放 | 格式不对 | Godot 4 支持 `.ogg` 和 `.wav`，`.mp3` 需要插件 |
| 音效同时播放冲突 | 多个 AudioStreamPlayer | 同一节点同时只能播一个音效，用多个 Player 或 `AudioStreamPlayer2D` |
| 标题屏幕后游戏卡住 | `paused = true` 没恢复 | 确认标题结束后 `get_tree().paused = false` |
| 开场提示文字被玩家看到 | CanvasLayer layer 顺序 | 标题屏幕 layer=100，游戏的 layer=1 |

---

## 每周开发节奏

### 标准周末安排

```
周六（3-4 小时）：
  ├── 1. 看教程（30-60 分钟）
  │      不要一次看太多。看一个完整的、跟本周任务匹配的教程
  ├── 2. 跟着做（1-2 小时）
  │      边看边写，不要跳步。
  └── 3. 自己改（30 分钟）
        把教程的代码改成自己的版本，试试不同参数

周日（2-3 小时）：
  ├── 1. 回顾上周代码（15 分钟）
  │      打开上周写的代码——还能看懂吗？
  ├── 2. 继续做（1-2 小时）
  │      完成本周剩下的任务
  └── 3. 运行测试（15 分钟）
        F5 运行一遍，确认能跑通
        不能跑通 → 修复后再结束
```

### 核心原则

> **每次只学一个系统。** 不要同时改"移动 + 战斗 + 掉落"。做完一个，运行一次。确认跑通，再做下一个。

### 周日收尾检查清单

- [ ] F5 运行游戏，能正常启动
- [ ] 本周新增的功能能工作（哪怕很丑）
- [ ] 上周的功能没有被破坏
- [ ] 有 bug 的地方记下来了
- [ ] 代码提交了（`git add -A && git commit -m "wip: 本周做了什么"`）
- [ ] 下次要做什么有个大致计划

---

## 避坑指南汇总

| 坑 | 症状 | 原因 & 解决 |
|----|------|------------|
| **没有主场景** | 按 F5 报错 `no main scene` | Project → Project Settings → Application → Run → Main Scene |
| **角色穿墙** | 走到边缘穿出去 | Player 是 CharacterBody2D，墙是 StaticBody2D，两种物理体类型匹配才能碰撞 |
| **角色不动** | 按 WASD 没反应 | 确认 player.tscn 根节点附加了 player.gd 脚本 |
| **信号不触发** | `connect()` 写的回调没调用 | 用 Godot 编辑器 Node → Signals 面板连接，不要手写字符串路径 |
| **`@export` 改了无效** | 运行还是旧值 | 改完 @export 变量后 **Ctrl+S 保存场景** |
| **UI 不显示** | 背包/血条看不见 | UI 节点必须在 **CanvasLayer** 下，不在 Node2D 下 |
| **Camera2D 不跟随** | 角色走出屏幕 | 勾选 Camera2D 的 **Current** 属性 |
| **SpriteSheet 显示错误** | 整张图或只显示第一帧 | 正确设置 **hframes** 和 **vframes** |
| **Image width 0 报错** | 控制台报错 | `assets/environment/` 下有损坏图片 → 逐个 Reimport |
| **碰撞层不工作** | `area_entered` 没触发 | Layer / Mask 配置必须匹配：Hitbox Mask = Hurtbox Layer |
| **攻击命中多次** | 一次攻击触发多次伤害 | `monitoring` 只在攻击期间开启，关闭时不影响 |
| **怪物不攻击** | 走到面前也不打 | `attack_range` 太小，打印 `dist` 看实际距离 |
| **E 键没反应** | 交互键无效 | Project → Input Map 添加 `interact` 并绑定 E |
| **火球不动** | 发射后停在原地 | `linear_velocity` 需要设置方向和速度 |
| **火球穿过怪物** | 碰撞不触发 | Fireball 的 `collision_mask` 要勾选 `enemy` 层 |
| **升级太快/太慢** | 游戏节奏不对 | 调 `exp_reward`（怪物给的经验）或 `calculate_exp_for_level` 公式 |
| **音效不播放** | 砍怪没声音 | 检查格式（.ogg/.wav），AudioStreamPlayer2D 的 Stream 是否设置 |
| **Boss 不换阶段** | 打剩 50% 血没狂暴 | 打印 `hp_ratio` 和 `phase` 值检查 |
| **NVIDIA 不生效（Wayland）** | 游戏卡顿 | `prime-run godot --editor` 启动，或用 `envycontrol -s nvidia` |

---

> **文档版本：** v2.0
> **上次更新：** 2026-05-22
> **合并自：** `2026-05-16-milestone-1-movable-player.md`（保留未删）
> **引擎：** Godot 4.6.2 + GDScript
> **渲染器：** gl_compatibility (OpenGL)
