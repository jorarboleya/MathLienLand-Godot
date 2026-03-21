# ----------------- Codigo Base obtenido de: -----------------
# 		https://github.com/CVelasco2/Math-Endless-Runner
extends Node2D

# Variables para obtener las escenas necesarias para instanciar.
export(PackedScene) var enemy_scene
export(PackedScene) var collectible_scene
# Decremento que se producira en el periodo del reloj
# instanciador de enemigos periodicamente
export(float) var time_btwn_enemies_decrement = 0.5
# Tiempo minimo entre aparicion de enemigos
export(float) var minimum_time_btwn_enemies = 0.1
# Recompensa dada con cada pregunta acertada.
export(float) var reward_time_bonus = 1.0

onready var coin_starting_pos = $GameLayer/CoinsSpawningPoint.position
onready var enemies_starting_pos = $GameLayer/EnemiesSpawningPoint.position

# Variable que controla si el jugador puede moverse.
var can_move = true

func _ready():
	# Establecemos la musica del minijuego
	MusicController.set_music()
	# Obtenemos una nueva semilla para los procesos
	# aleatorios.
	randomize()
	
	# Iniciamos los temporizadores
	$GameLayer/Timer.start()
	$GameLayer/CoinsTimer.start()
	$GameLayer/EnemiesTimer.start()
	$GameLayer/DifficultyTimer.start()
	# Conectamos las senyales.
	var _ret = $GameLayer/Player.connect("reward", self , "rewardPlayer")
	_ret = $GameLayer/Player.connect("killplayer", self , "newOperation")
	_ret = $GameLayer/Operation.connect("continuegame", self , "continue_game")
	_ret = $GameLayer/Operation.connect("gameover", self , "game_over")
	
	# Inicializamos las variables globales.
	Global.total_runner_time = 0
	Global.runner_score = 0
	Global.ncorrect_runner = 0

	Global.start_session("endlessrunner")

func _on_Timer_timeout():
	# Se suma un segundo al tiempo del minijuego
	Global.total_runner_time += 1
	$HUDLayer/HUDMER.set_time(Global.total_runner_time)


func _on_EnemiesTimer_timeout():
	#Se crea y se añade un nuevo enemigo a la escena
	var new_enemy = enemy_scene.instance()
	new_enemy.position = enemies_starting_pos
	$GameLayer.add_child(new_enemy)

func _on_CoinsTimer_timeout():
	#Se crea y se añade una nueva moneda a la escena
	var new_coin = collectible_scene.instance()
	new_coin.position = coin_starting_pos
	$GameLayer.add_child(new_coin)

func rewardPlayer():
	# Funcion que se ejecutara cada vez que el jugador
	# recolecte una moneda. Ejecutara el sonido correspondiente
	# e incrementara la puntuacion del jugador.
	$GameLayer/PickUpSound.play()
	Global.runner_score += 1
	$HUDLayer/HUDMER.set_score(Global.runner_score)

func newOperation():
	#Se llama para crear una nueva operación
	# Impedimos que el jugador pueda moverse,
	# ocultamos al jugador, y mostramos la operacion
	# correctamente.	
	can_move = false
	$GameLayer/PlayerHurt.play()
	$GameLayer/Player.visible = false
	$GameLayer/Operation.visible = true
	$GameLayer/Operation/MarginContainer/Panel/Answer.grab_focus()
	# Limpiamos la escena del minijuego
	$GameLayer/CoinsTimer.stop()
	$GameLayer/EnemiesTimer.stop()
	$GameLayer/DifficultyTimer.stop()
	get_tree().call_group("collidable", "queue_free")

	Global.start_question_timer()
	
	
func continue_game():
	Global.record_answer("mer_" + str(Global.ncorrect_runner), true, 0)
	# Esta funcion se llama tras la correcta contestacion
	# a la operacion formulada. Se encarda de reanudar el juego,
	# reiniciando los temporizadores de spawn, mostrando al jugador
	# y aplicando la bonificacion pertinente.
	Global.ncorrect_runner += 1
	can_move = true
	$GameLayer/Player.visible = true
	$GameLayer/Operation.visible = false
	# Limpiamos la escena del minijuego
	$GameLayer/CoinsTimer.start()
	$GameLayer/EnemiesTimer.start()
	$GameLayer/DifficultyTimer.start()
	$GameLayer/EnemiesTimer.wait_time += reward_time_bonus
	
	
func game_over():
	Global.record_answer("mer_" + str(Global.ncorrect_runner), false, 0)
	# Si se ha concluido el minijuego, pasamos  a la escena final.
	var _ret = get_tree().change_scene("res://minigames/endlessrunner/ui/EndScreenMER.tscn")


func _on_DifficultyTimer_timeout():
	# Esta funcion decrementara periodicamente el intervalo
	# entre aparicion de enemigos de tal forma que se aumente la dificultad.
	var actual_enemy_wait_time = $GameLayer/EnemiesTimer.wait_time
	if actual_enemy_wait_time - time_btwn_enemies_decrement > minimum_time_btwn_enemies:
		$GameLayer/EnemiesTimer.wait_time -= time_btwn_enemies_decrement
	else:
		$GameLayer/EnemiesTimer.wait_time = minimum_time_btwn_enemies
		$GameLayer/DifficultyTimer.stop()
