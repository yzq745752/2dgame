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

	#Sprint flipping (only in idle/run)
	if state == State.IDLE or State.RUN:
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
	#verify the player is not already attacking, and set the player sstate
	if state == State.ATTACK:
		return
	state = State.ATTACK
	
	#find the attack direction and push to animationtree blendspace2D
	var mouse_pos: Vector2 = get_global_mouse_position()
	var attack_dir: Vector2 = (mouse_pos - global_position).normalized()
	$Sprite2D.flip_h = attack_dir.x < 0 and abs(attack_dir.x) >= abs(attack_dir.y)
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)
	update_animation()
	
	#Return the player atate after attack has finished
	await get_tree().create_timer(attack_speed).timeout
	state = State.IDLE
					   
