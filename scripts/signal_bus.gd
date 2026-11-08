extends Node

#This signal sents specific monster data (Resource) to the game
# We tell Godot to ignore the warning because the Player emits this not the bus
@warning_ignore("unused_signal")
signal encounter_started(enemy_data)
