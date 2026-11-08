extends Control

# 1. The Blueprint
@export var battle_unit_scene : PackedScene

#IMPORTANT: Check your scene tree: Names must match
# UI Nodes
@onready var text_label: Label = $MainLayout/PanelContainer/Label
@onready var attack_button: Button = $MainLayout/ActionButtons/AttackButton
@onready var run_button: Button = $MainLayout/ActionButtons/RunButton
@onready var enemy_container: VBoxContainer = $MainLayout/BattleArea/EnemyContainer
@onready var player_container: VBoxContainer = $MainLayout/BattleArea/PlayerContainer

# 2. The Lists
# We are going to use Arrays to track who is alive in the fight
var active_player_units : Array = []
var active_enemy_units : Array = []

var current_player_index : int = 0
var is_targeting_mode : bool = false


# 3. Initialize
func initialize(enemy_data_array: Array, player_status_array : Array):
	# 1. Set Text
	if enemy_data_array.size() > 0:
		text_label.text =  "A wild group of " + enemy_data_array[0].name + "s appears!"
	# 2. Spawn Enemies Loop
	for enemy_data in enemy_data_array:
		# Create the unit from the blueprint
		var unit = battle_unit_scene.instantiate()
		
		# Add it to the screen
		enemy_container.add_child(unit)
		
		# Setup data 
		unit.set_data(enemy_data)
		
		# Update actual health from the enemy data
		unit.current_health = enemy_data.health
		unit.max_health = enemy_data.health
		
		# Manually update the healthbar from the persistant status
		unit.health_bar.max_value = enemy_data.health
		unit.health_bar.value = enemy_data.health
		
		# Connect the click signal
		unit.on_selected.connect(_on_enemy_selected)
		
		# Add to our tracking list
		active_enemy_units.append(unit)
		
	# 3. Spawn party loop
	for status in player_status_array:
		# If this hero is dead, skip them
		if status["current_health"] <= 0:
			continue
			
		var unit = battle_unit_scene.instantiate()
		player_container.add_child(unit)
		# Checkpoint callback: Accessing the dictionary
		unit.set_data(status["data"])
		
		# Update health from player status
		unit.max_health = status["max_health"]
		unit.current_health = status["current_health"]
		
		# Manually update the healthbar from the persistant status
		unit.health_bar.max_value = status["max_health"]
		unit.health_bar.value = status["current_health"]
		
		# Data Link: Connect real time saving
		unit.linked_status = status
		
		# Add to tracking list
		active_player_units.append(unit)
		
	start_player_turn()

func start_player_turn():
	# 1. Check if we have cycled through everyone
	if current_player_index >= active_player_units.size():
		enemy_phase() # All heros have moved enemy turn
		return
		
	# 2. Reset UI
	attack_button.disabled = false
	run_button.disabled = false
	is_targeting_mode = false
	text_label.text = "What will " + active_player_units[current_player_index].data.name + " do?"


func _on_run_button_pressed() -> void:
	var run_rng = RandomNumberGenerator.new()
	var run_chance = run_rng.randi_range(0, 100)
	# 50% chance to run
	if run_chance >= 50: 
		# 1. Unpause the game
		get_tree().paused = false
	
		# 2. Destroy the battle scene instance
		queue_free()
	else:
		# Turn lost, moves to monster's turn
		attack_button.disabled = true
		run_button.disabled = true
		text_label.text = "The monster blocked your path!"
		await get_tree().create_timer(1.0).timeout
		enemy_phase()

func _on_attack_button_pressed() -> void:
	is_targeting_mode = true
	text_label.text = "Select a target..."
	attack_button.disabled = true # Prevent double clicking
	run_button.disabled = true
	
func _on_enemy_selected(enemy_unit):
	if is_targeting_mode:
		is_targeting_mode = false
		
		# 1. Who is attacking
		var attacker = active_player_units[current_player_index]
		
		# 2. Deal damage
		text_label.text = attacker.data.name + " attacks!"
		await get_tree().create_timer(0.5).timeout
		
		enemy_unit.take_damage(attacker.data.damage)
		
		# 3. Check for Death (Remove from list if dead)
		if enemy_unit.current_health <= 0:
			active_enemy_units.erase(enemy_unit)
		
		await get_tree().create_timer(1.0).timeout
		
		# 4. Check win condition
		if active_enemy_units.size() == 0:
			win_battle()
		else:
			# 5. Next hero turn
			current_player_index += 1
			start_player_turn()
	
func enemy_phase():
	text_label.text = "Enemy Turn!"
	await get_tree().create_timer(1.0).timeout
	
	for enemy in active_enemy_units:
		# 1. Stop if everyone is dead
		if active_player_units.size() == 0: break
		
		# 2. Pick a random target
		var target = active_player_units.pick_random()
		
		# 3. Attack
		text_label.text = enemy.data.name + " attacks " + target.data.name + "!"
		await get_tree().create_timer(0.5).timeout
		target.take_damage(enemy.data.damage)
		
		# 4. Check for Player Death
		if target.current_health <= 0:
			active_player_units.erase(target)
			
	# End enemy phase, back to player 1
	current_player_index = 0
	if active_player_units.size() > 0:
		start_player_turn()
	else:
		game_over()
	
func win_battle():
	text_label.text = "Victory!"
	await get_tree().create_timer(1.0).timeout
	
	get_tree().paused = false
	queue_free()

func game_over():
	text_label.text = "Defeated..."
	await get_tree().create_timer(2.0).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()
