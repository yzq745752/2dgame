# 里程碑 1：能动的方块 — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 创建一个 Godot 4 项目，实现角色在地图上 WASD 移动、相机跟随、不穿墙。

**Architecture:** 使用 Godot 4 的 2D 节点系统。Player 是 CharacterBody2D（内置物理移动），World 是 Node2D 容器，地图用 TileMap，相机用 Camera2D 跟随玩家。所有脚本用 GDScript。

**Tech Stack:** Godot 4.6.2, GDScript

---

## 文件结构

```
2dgame/
├── project.godot                    # 已存在，项目配置
├── scenes/
│   ├── player/
│   │   ├── Player.tscn              # 玩家场景（CharacterBody2D 根节点）
│   │   └── Player.gd                # 玩家移动逻辑
│   └── main/
│       ├── World.tscn               # 主世界场景（Node2D 根节点）
│       └── World.gd                 # 世界初始化（可选）
├── assets/
│   └── sprites/
│       └── player_placeholder.png   # 临时角色图片（或直接用 Godot icon）
└── scripts/                         # 后续里程碑使用
```

---

### Task 1: 创建 Player 场景和移动脚本

**Files:**
- Create: `scenes/player/Player.tscn`
- Create: `scenes/player/Player.gd`

- [ ] **Step 1: 创建 Player.gd 移动脚本**

这是玩家的核心逻辑。CharacterBody2D 是 Godot 4 推荐的 2D 角色节点类型，内置 `move_and_slide()` 处理碰撞。

```gdscript
# scenes/player/Player.gd
extends CharacterBody2D

## 移动速度（像素/秒）
@export var speed: float = 200.0

func _physics_process(delta: float) -> void:
	# 读取 WASD 输入，返回归一化的方向向量
	var direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	
	# 设置速度并移动
	velocity = direction * speed
	move_and_slide()
```

- [ ] **Step 2: 创建 Player.tscn 场景文件**

Godot 的 `.tscn` 是文本格式的场景文件。这个文件定义了 Player 的节点树：
- `CharacterBody2D` 根节点（物理角色）
- `Sprite2D` 子节点（视觉表现）
- `CollisionShape2D` 子节点（碰撞检测）

```tscn
[gd_scene load_steps=3 format=3 uid="uid://cplayer001"]

[ext_resource type="Script" path="res://scenes/player/Player.gd" id="1_player"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_player"]
size = Vector2(32, 32)

[node name="Player" type="CharacterBody2D"]
script = ExtResource("1_player")

[node name="Sprite2D" type="Sprite2D" parent="."]
position = Vector2(0, 0)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_player")
```

- [ ] **Step 3: 在 Godot 编辑器中验证 Player 场景**

1. 打开 Godot，Import 项目 `/home/wjz/Projects/2dgame/`
2. 在 FileSystem 面板中双击 `scenes/player/Player.tscn` 打开场景
3. 确认节点树结构：
   ```
   Player (CharacterBody2D)
   ├── Sprite2D
   └── CollisionShape2D
   ```
4. 选中 Sprite2D，在 Inspector 中找到 `Texture` 属性，点击 `[empty]` → `Quick Load` → 选择 Godot 自带的 `icon.svg`（或任何图片）
5. 选中 CollisionShape2D，在 Inspector 中确认 `Shape` 已设置为 `RectangleShape2D`，大小为 32x32
6. 按 **F6**（运行当前场景）测试
7. 用 **WASD** 键移动——角色应该在黑色背景上移动

**Expected:** 一个方块在黑色背景上移动。按 WASD 有反应。

- [ ] **Step 4: 提交**

```bash
git add scenes/player/Player.gd scenes/player/Player.tscn
git commit -m "feat(milestone-1): add Player scene with WASD movement"
```

---

### Task 2: 创建 World 场景和 TileMap 地图

**Files:**
- Create: `scenes/main/World.tscn`
- Create: `scenes/main/World.gd`

- [ ] **Step 1: 创建 World.gd（空脚本，用于后续扩展）**

```gdscript
# scenes/main/World.gd
extends Node2D

func _ready() -> void:
	print("World loaded")
```

- [ ] **Step 2: 创建 World.tscn 场景文件**

World 是主场景，包含 TileMap（地面）和 Player 实例。

```tscn
[gd_scene load_steps=3 format=3 uid="uid://cworld001"]

[ext_resource type="Script" path="res://scenes/main/World.gd" id="1_world"]
[ext_resource type="PackedScene" path="res://scenes/player/Player.tscn" id="2_player"]

[node name="World" type="Node2D"]
script = ExtResource("1_world")

[node name="TileMap" type="TileMap" parent="."]

[node name="Player" parent="." instance=ExtResource("2_player")]
position = Vector2(576, 324)
```

- [ ] **Step 3: 在 Godot 编辑器中配置 TileMap**

TileMap 是 Godot 的瓦片地图系统。需要在编辑器中手动配置：

1. 在 Godot 中打开 `scenes/main/World.tscn`
2. 选中 `TileMap` 节点
3. 在 Inspector 中找到 `Tile Set` 属性，点击 `[empty]` → `New TileSet`
4. 点击新创建的 TileSet，在底部面板会出现 TileSet 编辑器
5. 在 TileSet 编辑器中点击 `+` 添加源 → 选择一张地砖图片（或用 Godot 内置的默认瓷砖）
6. 如果暂时没有素材，先跳过——TileMap 可以先用纯色填充
7. 点击 Godot 顶部工具栏的 **TileMap** 按钮进入绘制模式
8. 在画面上绘制一个 20x15 格的地面区域（每个格子 64x64 像素）

**如果暂时没有素材的临时方案：**
- 在 TileMap 的 Inspector 中设置 `Cell > Size` 为 `64, 64`
- 在 TileSet 中添加一个纯色瓷砖（用 Godot 的默认图标或任何图片）
- 绘制一个矩形区域即可

- [ ] **Step 4: 在 Godot 编辑器中设置主场景**

1. 点击菜单 `Project` → `Project Settings`
2. 找到 `Application > Run > Main Scene`
3. 设置为 `res://scenes/main/World.tscn`
4. 关闭 Project Settings

- [ ] **Step 5: 运行 World 场景**

1. 按 **F5**（运行主场景）
2. 确认 Player 出现在地图中央（位置 576, 324）
3. 用 WASD 移动——角色应该能在画面上走动

**Expected:** 玩家出现在地图中央，可以 WASD 移动。背景有 TileMap 地面。

- [ ] **Step 6: 提交**

```bash
git add scenes/main/World.gd scenes/main/World.tscn
git commit -m "feat(milestone-1): add World scene with TileMap and Player instance"
```

---

### Task 3: 添加 Camera2D 跟随玩家

**Files:**
- Modify: `scenes/player/Player.tscn`（添加 Camera2D 子节点）

- [ ] **Step 1: 修改 Player.tscn 添加 Camera2D**

在 Player 场景中添加 Camera2D 作为子节点，这样相机自动跟随玩家移动。

```tscn
[gd_scene load_steps=3 format=3 uid="uid://cplayer001"]

[ext_resource type="Script" path="res://scenes/player/Player.gd" id="1_player"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_player"]
size = Vector2(32, 32)

[node name="Player" type="CharacterBody2D"]
script = ExtResource("1_player")

[node name="Sprite2D" type="Sprite2D" parent="."]
position = Vector2(0, 0)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_player")

[node name="Camera2D" type="Camera2D" parent="."]
position = Vector2(0, 0)
```

- [ ] **Step 2: 在 Godot 编辑器中配置 Camera2D**

1. 打开 `scenes/player/Player.tscn`
2. 确认 `Camera2D` 节点已出现在 Player 下
3. 选中 Camera2D，在 Inspector 中勾选 `Current`（设为当前活动相机）
4. 可选：调整 `Zoom` 属性（默认 1,1 即可）
5. 按 **F6** 运行 Player 场景测试

**Expected:** 相机跟随玩家移动。如果地图比窗口大，移动时能看到相机平滑跟随。

- [ ] **Step 3: 提交**

```bash
git add scenes/player/Player.tscn
git commit -m "feat(milestone-1): add Camera2D following player"
```

---

### Task 4: 添加墙壁碰撞（不穿墙）

**Files:**
- Modify: `scenes/main/World.tscn`（添加 StaticBody2D 墙壁）

- [ ] **Step 1: 修改 World.tscn 添加墙壁**

在 World 场景中添加 StaticBody2D 作为墙壁，防止玩家走出地图。

```tscn
[gd_scene load_steps=4 format=3 uid="uid://cworld001"]

[ext_resource type="Script" path="res://scenes/main/World.gd" id="1_world"]
[ext_resource type="PackedScene" path="res://scenes/player/Player.tscn" id="2_player"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall"]
size = Vector2(1280, 32)

[node name="World" type="Node2D"]
script = ExtResource("1_world")

[node name="TileMap" type="TileMap" parent="."]

[node name="Player" parent="." instance=ExtResource("2_player")]
position = Vector2(576, 324)

[node name="Walls" type="Node2D" parent="."]

[node name="TopWall" type="StaticBody2D" parent="Walls"]
position = Vector2(640, -16)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Walls/TopWall"]
shape = SubResource("RectangleShape2D_wall")

[node name="BottomWall" type="StaticBody2D" parent="Walls"]
position = Vector2(640, 976)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Walls/BottomWall"]
shape = SubResource("RectangleShape2D_wall")

[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall_side"]
size = Vector2(32, 960)

[node name="LeftWall" type="StaticBody2D" parent="Walls"]
position = Vector2(-16, 480)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Walls/LeftWall"]
shape = SubResource("RectangleShape2D_wall_side")

[node name="RightWall" type="StaticBody2D" parent="Walls"]
position = Vector2(1296, 480)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Walls/RightWall"]
shape = SubResource("RectangleShape2D_wall_side")
```

- [ ] **Step 2: 在 Godot 编辑器中验证墙壁**

1. 打开 `scenes/main/World.tscn`
2. 确认 Walls 节点下有 4 面墙（Top/Bottom/Left/Right）
3. 按 **F5** 运行主场景
4. 用 WASD 移动玩家到边缘——应该被墙挡住，不能走出地图

**Expected:** 玩家走到地图边缘时被墙壁挡住，不能穿出去。

- [ ] **Step 3: 提交**

```bash
git add scenes/main/World.tscn
git commit -m "feat(milestone-1): add wall collision to prevent player leaving map"
```

---

### Task 5: 里程碑 1 最终验证

- [ ] **Step 1: 完整运行测试**

1. 按 **F5** 运行主场景
2. 验证清单：
   - [ ] 玩家出现在地图中央
   - [ ] WASD 可以控制移动
   - [ ] 相机跟随玩家
   - [ ] 玩家不能走出地图（被墙壁挡住）
   - [ ] 没有控制台报错

- [ ] **Step 2: 提交最终版本**

```bash
git add -A
git commit -m "feat(milestone-1): milestone 1 complete - player moves on map with camera and walls"
```

---

## 里程碑 1 验收标准

完成后应该能：
1. 打开 Godot，按 F5 运行游戏
2. 看到一个角色在地图上
3. 用 WASD 控制角色移动
4. 相机跟随角色
5. 角色不能走出地图边界
6. 没有报错

**如果以上都满足，里程碑 1 完成！进入里程碑 2。**

---

## 常见问题排查

| 问题 | 原因 | 解决 |
|------|------|------|
| 按 F5 报错 "no main scene" | 没设置主场景 | Project → Project Settings → Application → Run → Main Scene → 选 World.tscn |
| 角色不动 | 脚本没附加 | 确认 Player.tscn 的根节点有 script 属性指向 Player.gd |
| 角色穿墙 | 墙壁不是 StaticBody2D | 确认墙壁是 StaticBody2D 类型，有 CollisionShape2D |
| Camera2D 不跟随 | 没勾选 Current | 选中 Camera2D，Inspector 中勾选 `Current` |
| WASD 没反应 | 输入映射不对 | project.godot 中已配置 ui_up/down/left/right 映射到 WASD |
