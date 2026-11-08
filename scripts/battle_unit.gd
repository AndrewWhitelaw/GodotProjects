extends Control

@onready var name_label: Label = $VBoxContainer/Label
@onready var texture_rect: TextureRect = $VBoxContainer/TextureRect
@onready var health_bar: ProgressBar = $VBoxContainer/ProgressBar

# Add a signal so the main script knows when we are clicked
signal on_selected(unit_instance)

# Add variables to track health locally
var current_health : int
var max_health : int
var data : Resource # Can hold EnemyData or CharacterData

# Add a variable to hold the link to the Player's dictionary
var linked_status : Dictionary = {}

func set_data(resource):
	data = resource
	name_label.text = resource.name
	texture_rect.texture = resource.texture
	
	# Note: We'll update health from the manager later


func _on_button_pressed() -> void:
	on_selected.emit(self)

func take_damage(amount):
	current_health -= amount
	health_bar.value = current_health
	
	# Save data: update player file immediately
	if not linked_status.is_empty():
		linked_status["current_health"] = current_health
	
	# Transparent blink animation
	var tween = create_tween()
	# 50% opacity
	tween.tween_property(texture_rect, "modulate", Color(1, 1, 1, 0.5), 0.1)
	# 100% opacity
	tween.tween_property(texture_rect, "modulate", Color(1, 1, 1, 1), 0.1)
	
	if current_health <= 0:
		# Wait for animation to finish before deleting
		await tween.finished
		queue_free()
	
