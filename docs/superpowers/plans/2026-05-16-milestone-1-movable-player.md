# 里程碑 1：能动的方块 — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **当前进度：** 第 1-2 周末完成 ✅ — 实际远超原始计划，标记为以完成，保留剩余任务

**Goal:** 创建一个 Godot 4 项目，实现角色在地图上 WASD 移动、相机跟随、不穿墙。

**Architecture:** 使用 Godot 4 的 2D 节点系统。Player 是 CharacterBody2D（内置物理移动），World 是 Node2D 容器，地图用 TileMap，相机用 Camera2D 跟随玩家。所有脚本用 GDScript。

**Tech Stack:** Godot 4.6.2, GDScript

---

## 当前文件结构（实际）

```
2dgame/
├── project.godot                    # 项目配置（gl_compatibility 渲染器）
├── scenes/
│   ├── player/
│   │   ├── player.tscn              # 玩家场景（CharacterBody2D 根节点）
│   │   └── player.gd                # 玩家全部逻辑（81 行）
│   └── maps/
│       └── test_map.tscn            # 主场景（TileMap + Player 实例）
├── assets/
│   ├── sprites/
│   │   ├── Warrior_Blue.png         # 角色 SpriteSheet（6x8=48帧）
│   │   └── player_placeholder.png   # 临时蓝色占位方块（已弃用）
│   └── environment/
│       ├── tilesheets/              # 地图瓦片素材（6 张）
│       └── animated_tiles/          # 动画瓦片素材（7 张）
└── docs/superpowers/
    ├── specs/
    │   └── 2026-05-16-2d-loot-game-design.md
    └── plans/
        └── 2026-05-16-milestone-1-movable-player.md   # ← 本文件
```

---

### Task 1: 创建 Player 场景和移动脚本 ✅ 已完成（扩展实现）

**Files:**
- Create: `scenes/player/Player.tscn` ✅
- Create: `scenes/player/Player.gd` ✅

- [x] **Step 1: 创建 Player.gd 移动脚本**

**实际代码（81 行，远超原始计划）：**
- 基础 WASD 移动 ✅（使用 `right/left/down/up` 映射，speed=500）
- 状态机系统 ✅（IDLE / RUN / ATTACK / DEAD 四状态）
- 鼠标左键攻击 ✅（BlendSpace2D 四方向混合）
- 朝向翻转 ✅（flip_h 根据方向自动切换）

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
    move_direction.x = float(Input.is_action_pressed("right")) - float(Input.is_action_pressed("left"))
    move_direction.y = float(Input.is_action_pressed("down")) - float(Input.is_action_pressed("up"))
    velocity = move_direction.normalized() * speed
    move_and_slide()
    # 状态切换 + 动画更新...
```

> ⚠️ **已知 bug：** 第 41 行 `if state == State.IDLE or State.RUN:` 逻辑错误，应为 `if state == State.IDLE or state == State.RUN:`

- [x] **Step 2: 创建 Player.tscn 场景文件**

**实际节点树：**
```
player (CharacterBody2D)
├── Sprite2D (Warrior_Blue.png, hframes=6, vframes=8)
├── CollisionShape2D (CircleShape2D, radius=22)  ← 改为圆形
├── Camera2D (跟随玩家)                           ← 已添加
├── AnimationPlayer (动画库：idle/run/attack_*/RESET)
└── AnimationTree (状态机：Start→idle↔run↔attack)
```

> **与计划的差异：**
> - 碰撞形状：RectangleShape2D → CircleShape2D（用户自行修改）
> - 图片：placeholder → Warrior_Blue.png SpriteSheet
> - 额外添加了 AnimationPlayer + AnimationTree + Camera2D

- [x] **Step 3: 在 Godot 编辑器中验证 Player 场景**

**实际验证结果：**
- WASD 移动 ✅
- 相机跟随 ✅
- 角色动画（idle/run）✅
- 鼠标左键攻击（四方向）✅
- 朝向自动翻转 ✅

- [ ] **Step 4: 提交**（待执行）

```bash
git add scenes/player/player.gd scenes/player/player.tscn
git commit -m "feat(milestone-1): add Player scene with WASD movement"
```

---

### Task 2: 创建 World 场景和 TileMap 地图 ✅ 已完成（扩展实现）

**Files:**
- Create: `scenes/main/World.tscn` → 用户创建了 `scenes/maps/test_map.tscn` 替代
- Create: `scenes/main/World.gd` → 未创建（test_map 没加脚本）

- [x] **Step 1: 创建 World.gd** — 未创建，test_map.tscn 未附加脚本

- [x] **Step 2: 创建主场景文件**

**实际实现：**
- 主场景：`scenes/maps/test_map.tscn`（非原始计划的 World.tscn）
- 包含完整 TileSet，12 个 AtlasSource
- 配置了主场景：Project Settings → `run/main_scene` → test_map.tscn

- [x] **Step 3: 在 Godot 编辑器中配置 TileMap**

**实际配置：**
- 成功导入多张瓦片素材
- 配置了 Tile Size = 64x64
- 绘制了完整地图（多次调整后）
- 包含了动画瓦片（Water Foam 等）

> ⚠️ **遇到问题：** 配置 TileMap 时，tscn 文件中残留了超出图片范围的图块定义，导致 405 个报错。已通过脚本清理（删除 1279 行无效定义）。

- [x] **Step 4: 在 Godot 编辑器中设置主场景**

```gdscript
run/main_scene="uid://brbtvnw2l2hrf"   # 指向 test_map.tscn
```

- [x] **Step 5: 运行 World 场景**

- 按 **F5** 运行 ✅
- Player 出现在地图中央 ✅
- WASD 移动 ✅

- [ ] **Step 6: 提交**（待执行）

```bash
git add scenes/maps/test_map.tscn
git commit -m "feat(milestone-1): add main map scene with TileMap and Player instance"
```

---

### Task 3: 添加 Camera2D 跟随玩家 ✅ 已完成

**Files:**
- Modify: `scenes/player/Player.tscn`（添加 Camera2D 子节点）

- [x] **Step 1: 修改 Player.tscn 添加 Camera2D**

Camera2D 已作为 player 的子节点添加。

```tscn
[node name="Camera2D" type="Camera2D" parent="." unique_id=1533610592]
```

- [x] **Step 2: 在 Godot 编辑器中配置 Camera2D**

> **注意：** tscn 文件中 Camera2D 没有显式设置 `current = true`。如果在游戏中不跟随，需要在编辑器中勾选 Camera2D → Inspector → Current。

- [ ] **Step 3: 提交**（待执行）

```bash
git add scenes/player/player.tscn
git commit -m "feat(milestone-1): add Camera2D following player"
```

---

### Task 4: 添加墙壁碰撞（不穿墙） ❌ 未完成

**Files:**
- Modify: `scenes/main/World.tscn`（添加 StaticBody2D 墙壁）

- [ ] **Step 1: 修改 World.tscn 添加墙壁**

> 如果你用的是 test_map.tscn，需要在那里添加墙壁。
>
> 在 test_map.tscn 中添加 StaticBody2D 作为墙壁，防止玩家走出地图。

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

- [ ] **Step 2: 在 Godot 编辑器中验证墙壁**

1. 打开 `scenes/maps/test_map.tscn`
2. 确认 Walls 节点下有 4 面墙（Top/Bottom/Left/Right）
3. 按 **F5** 运行主场景
4. 用 WASD 移动玩家到边缘——应该被墙挡住，不能走出地图

**Expected:** 玩家走到地图边缘时被墙壁挡住，不能穿出去。

- [ ] **Step 3: 提交**

```bash
git add scenes/maps/test_map.tscn
git commit -m "feat(milestone-1): add wall collision to prevent player leaving map"
```

---

### Task 5: 里程碑 1 最终验证 ⏳ 部分通过

- [ ] **Step 1: 完整运行测试**

1. 按 **F5** 运行主场景
2. 验证清单：
   - [x] 玩家出现在地图中央（test_map 中玩家实例存在）
   - [x] WASD 可以控制移动
   - [x] 相机跟随玩家
   - [ ] 玩家不能走出地图（被墙壁挡住）— ❌ 未实现
   - [ ] 没有控制台报错 — ❌ 仍有 2 个 Image 错误

**剩余问题：**
1. `player.gd:41` 逻辑错误（`State.IDLE or State.RUN:` → `state == State.RUN`）
2. Image width 0 / Invalid image — 某个图片资源损坏，待排查
3. FIFO protocol warning — Wayland 警告，无害

- [ ] **Step 2: 提交最终版本**

```bash
git add -A
git commit -m "feat(milestone-1): milestone 1 complete - player moves on map with camera and walls"
```

---

## 里程碑 1 实际验收状态

| 验收项 | 状态 | 备注 |
|--------|------|------|
| 打开 Godot，按 F5 运行游戏 | ✅ | test_map.tscn 已设为主场景 |
| 看到一个角色在地图上 | ✅ | Warrior_Blue 精灵 + 动画 |
| 用 WASD 控制角色移动 | ✅ | speed=500 |
| 相机跟随角色 | ✅ | Camera2D 子节点 |
| 角色不能走出地图边界 | ❌ | 待添加墙壁 |
| 没有报错 | ❌ | 2 个 Image 错误待排查 |
| **额外：角色攻击动画** | ✅ | 鼠标左键 + BlendSpace2D |
| **额外：状态机切换** | ✅ | IDLE/RUN/ATTACK/DEAD |
| **额外：朝向翻转** | ✅ | flip_h |
| **额外：TileMap 多层地图** | ✅ | 12 个 AtlasSource |

---

## 附加说明：用户自行扩展的功能

以下功能是用户在实施过程中**自行添加**的，不在原始计划中：

### 1. SpriteSheet 与动画系统
- 使用了 `Warrior_Blue.png`（6x8 帧 SpriteSheet）
- 配置了 `hframes=6, vframes=8` 分割
- `AnimationPlayer` 管理动画库（idle/run/attack）

### 2. AnimationTree 状态机
- 根节点：`AnimationNodeStateMachine`
- 状态间可切换：Start → idle ↔ run ↔ attack (通过 attack) → idle
- `AnimationNodeStateMachinePlayback.travel()` 控制切换

### 3. BlendSpace2D 四方向攻击
- `attack` 状态使用 `BlendTree`，内部包含 `BlendSpace2D`
- 四个方向点：(-1,0)=左, (1,0)=右, (0,-1)=上, (0,1)=下
- `attack_dir` 通过鼠标位置计算并写入 `blend_position`

### 4. 状态机保护
- `_physics_process` 中 `if not state == State.ATTACK` 防止攻击时移动
- `attack()` 中 `if state == State.ATTACK: return` 防止重复攻击

---

## 常见问题排查

| 问题 | 原因 | 解决 |
|------|------|------|
| 按 F5 报错 "no main scene" | 没设置主场景 | Project → Project Settings → Application → Run → Main Scene → 选 test_map.tscn |
| 角色不动 | 脚本没附加 | 确认 player.tscn 的根节点有 script 属性指向 player.gd |
| 角色穿墙 | 墙壁不是 StaticBody2D | 确认墙壁是 StaticBody2D 类型，有 CollisionShape2D |
| Camera2D 不跟随 | 没勾选 Current | 选中 Camera2D，Inspector 中勾选 `Current` |
| WASD 没反应 | 输入映射不对 | 当前用 `right/left/down/up`（无 ui_前缀），在 project.godot 中已配置 |
| 攻击不触发 | _unhandled_input 问题 | 检查节点路径，确保 AnimationTree 已激活 |
| Image width 0 报错 | 图片资源损坏 | 在 FileSystem 中逐个 Reimport assets/environment/ 下的图片 |
| 405 个 TileMap 报错 | 残留无效图块定义 | 已修复（删除了 1279 行） |
| NVIDIA 不生效 | Wayland 限制 | `prime-run godot --editor` 或 `envycontrol -s nvidia` |
