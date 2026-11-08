extends CharacterBody2D

@export var move_speed : float = 100.0
@export var ground_layer : TileMapLayer
@export var encounter_rate : float = 0.1 # 10% chance
@export var monsters : Array[EnemyData]
@export var party_members : Array[CharacterData]

var distanc_traveled : float = 0.0
var party_status : Array = []

const ENCOUNTER_THRESHOLD : float = 50.0 # Check every 50 pixels

func _ready():
	# Loop through the starter cards and build out active party
	for member in party_members:
		# Create a dictionary to track real time stats
		var status = {
			"data": member, 
			"max_health": member.max_health,
			"current_health": member.max_health
		}
		
		party_status.append(status)
		

func _physics_process(delta: float) -> void:
	# we use the custom actions defined
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * move_speed
	
	move_and_slide() # actually moves the character
	
	# 1. Track distance
	if velocity.length() > 0:
		distanc_traveled += velocity.length() * delta
	
		if distanc_traveled > ENCOUNTER_THRESHOLD:
			distanc_traveled = 0.0
			check_for_encounter()
			
func check_for_encounter():
	# 2. Get tile we are standing on
	var map_pos = ground_layer.local_to_map(global_position)
	var tile_data = ground_layer.get_cell_tile_data(map_pos)
	
	# 3. Check our 'invisible paint'
	# Add "tile_data" and to make sure a tile actually exists
	if tile_data and tile_data.get_custom_data("is_encounter_zone"):
		print("Stepped on Monster stones!")
		
		# 4. Roll the dice
		if randf() < encounter_rate:
			print("BATTLE STARTED")
			# Pick a random monster
			var random_monster = monsters.pick_random()
			print("A wild " + random_monster.name + " appeared!")
			SignalBus.encounter_started.emit(random_monster)
