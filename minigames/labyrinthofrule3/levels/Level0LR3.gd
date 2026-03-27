extends Node2D

# Escenas que representan a los 3 tipos de enemigos que 
# presenta el juego. En nuestro caso son fantasmas, slimes 
# y aranyas.
export(PackedScene) var Enemy_1
export(PackedScene) var Enemy_2
export(PackedScene) var Enemy_3

# Escena que contiene la logica de los coleccionables
export(PackedScene) var Pickup

# Capa del mapa que indica la posicion de los items.
onready var items = $Items

# Array para guardar las posiciones de las cuatro posiciones
# de puertas a cerrar en caso de fallo. Tantas como posibles
# respuestas haya.
var door_frames = []
# Numero de opciones de respuesta
var num_answers = 4
# Nombres de las 4 opciones. Son empleadas como claves en 
# distintos diccionarios.
var answers = ["answerA", "answerB", "answerC", "answerD"]
# Diccionario cuyas claves son los nombres de las opciones posibles
# de respuestas y cuyos valores consisten en arrays cuyo primer elemento
# es el nombre de la baldosa con la que se cerrara el camino que permite
# responder con una determinada respuesta y cuyo segundo elemento es la posicion
# que ocupa la celda que representa el marco de puerta que sera sustituida por
# dicha puerta.
var door_ids = {"answerA": ["doorA", 0], "answerB": ["doorB", 1], "answerC": ["doorC", 2], "answerD": ["doorD", 3]}

func _ready():
	# Cuando la escena este lista por primera vez en el arbol del proyecto
	# Primeramente generamos una semilla para los procesos aleatorios.
	randomize()
	# Seguidamente ocultamos los items pues solamente son indicadores
	$Items.hide()
	# Establecemos los limites de la camara.
	set_camera_limits()
	# Nombres dados a los marcadores de las posiciones
	# de las puertas.
	var door_frames_names = ['doorframeA',
	"doorframeB", "doorframeC", "doorframeD"]
	
	#for cell in $Walls.get_used_cells():
		# Obtenemos su id
	#	var id = $Walls.get_cellv(cell)
		# Obtenemos el nombre de la "baldosa"
	#	var type = $Walls.tile_set.tile_get_name(id)
	
	# Por cada marcador nos hemos asegurado de solamente poner una
	# celda con dicha "baldosa", asi que nos vale con cojer la primera
	# celda obtenida con ese nombre.
	# Por cada "marco de puerta" obtenemos el id de la celda y con el id, la
	# celda en si misma. Esta celda se añade al array de "marcos de puertas"
	# en orden.
	for tile_name in door_frames_names:
		var door_frame_id = $Walls.tile_set.find_tile_by_name(tile_name)
		#var cells_by_id = $Walls.get_used_cells_by_id(door_frame_id)
		door_frames.append($Walls.get_used_cells_by_id(door_frame_id).front())
	
	# Comprobamos que hayan tantas posiciones de puertas como respuestas posibles.
	if door_frames.size() < num_answers:
		print("No se han establecido correctamente las posiciones de las puertas")
		get_tree().quit()
	
	# Procedemos a generar todos los items.
	spawn_items()
	
	# Conectamos las senyales con las funciones que las procesaran.
	
	var _ret
	_ret = $Player.connect("labyrinth_dead", self , "start_over")
	_ret = $Player.connect("labyrinth_answerA", self , "_on_Player_answered_a")
	_ret = $Player.connect("labyrinth_answerB", self , "_on_Player_answered_b")
	_ret = $Player.connect("labyrinth_answerC", self , "_on_Player_answered_c")
	_ret = $Player.connect("labyrinth_answerD", self , "_on_Player_answered_d")
	
	# Only start a new session on the first question (not on reloads for each question)
	if Global.current_labyrinth_question == 0:
		Global.start_session("labyrinthofrule3")
	# Wait for questions to be fetched from the server if not ready yet
	if not Global.questions_loaded:
		yield(Global, "all_questions_loaded")
	# Establecemos la pregunta y sus opciones en la interfaz de usuario.
	set_question_hud()

	
func _enter_tree():
	# Cada vez que la escena entra al arbol del proyecto, ponemos el tiempo
	# que lleva el jugador y nos aseguramos que la musica sea la correcta.
	$CanvasLayer/HUD/Time.text = str(Global.total_labyrinth_time)
	MusicController.set_music()


func set_camera_limits():
	# Obtenemos las dimensiones del laberinto en 
	# celdas
	var maze_dims = $Ground.get_used_rect()
	# Obtenemos las dimensiones de las celdas en 
	# pixeles
	var cell_dims = $Ground.cell_size
	# Ponemos los limites en pixeles partiendo de las
	# dimensiones obtenidas.
	$Player/Camera2D.limit_bottom = maze_dims.end.y * cell_dims.y
	$Player/Camera2D.limit_left = maze_dims.position.x * cell_dims.x
	$Player/Camera2D.limit_right = maze_dims.end.x * cell_dims.x
	$Player/Camera2D.limit_top = maze_dims.position.y * cell_dims.y

func spawn_items():
	# Para cada celda del laberinto
	for cell in items.get_used_cells():
		# Obtenemos su id
		var id = items.get_cellv(cell)
		# Obtenemos el nombre de la "baldosa"
		var type = items.tile_set.tile_get_name(id)
		# Obtenemos la posicion central de la celda mediante
		# su punto inicial (map_to_world) y la mitad del tamanio
		# de una celda.
		var pos = items.map_to_world(cell) + items.cell_size / 2
		# Ahora procedemos a ver que tipo de item es:
		match type:
			"enemies_spawner1":
				# Si es el primer tipo de enemigo, 
				# instanciamos la escena correspondiente, 
				# asignamos la posicion indicada y el tamanyo
				# de celda del mapa. Finalmente anyadimos la instancia
				# a la escena.
				var ghost = Enemy_1.instance()
				ghost.position = pos
				ghost.tile_dim = items.cell_size
				add_child(ghost)
			"enemies_spawner2":
				# Si es el segundo tipo de enemigo, 
				# realizamos lo mismo que con el primero
				# pero instanciando el correspondiente tipo
				var slime = Enemy_2.instance()
				slime.position = pos
				slime.tile_dim = items.cell_size
				add_child(slime)
			"enemies_spawner3":
				# Si es el tercer tipo de enemigo, 
				# realizamos lo mismo que con el primero
				# pero instanciando el correspondiente tipo
				var spider = Enemy_3.instance()
				spider.position = pos
				spider.tile_dim = items.cell_size
				add_child(spider)
			"answerA", "answerB", "answerC", "answerD":
				# Si es un objeto que se pueda recojer, 
				# instanciamos la escena correspondiente
				# e inicializamos dicha instancia para 
				# posteriormente anyadirla a la escena.
				var answer_flag = Pickup.instance()
				answer_flag.init(type, pos)
				add_child(answer_flag)
			"player_spawner":
				# Finalmente, si es el punto de inicio del jugador,
				# le asignamos la posicion y el tamanyo de celda
				# correspondiente.
				$Player.position = pos
				$Player.tile_dim = items.cell_size

func start_over():
	$WrongSound.play()
	$Player.set_process(false)
	$Player.move_allowed = false
	$Player.hide()
	yield (get_tree().create_timer(1.5), 'timeout')
	$Player.position = $StartingPoint.position
	$Player/AnimationPlayer.play_backwards("die")
	$Player.show()
	yield ($Player/AnimationPlayer, 'animation_finished')
	$Player.move_allowed = true
	$Player.set_process(true)
	$Player/CollisionShape2D.set_deferred("disabled", false)
	

# A continuacion se implementarion las 4 funciones que procesan las
# senyales de opciones escogidas. Todas ellas llaman a la funcion 
# check_answer con la clave apropiada para corroborar si la opcion
# elegida ha sido la correcta o no.

func _on_Player_answered_a():
	check_answer(answers[0])
	
func _on_Player_answered_b():
	check_answer(answers[1])
	
func _on_Player_answered_c():
	check_answer(answers[2])
	
func _on_Player_answered_d():
	check_answer(answers[3])

func check_answer(answer):
	# Funcion para comprobar si la opcion elegida ha sido la
	# correcta. 
	# Comprobamos que la clave indicada sea valida.
	if not answer in answers:
		return
	
	# Comprobamos si la opcion elegida es correcta.
	var correct = Global.labyrinth_questions[Global.current_labyrinth_question][answer][1]
	var q_id = "lr3_" + str(Global.current_labyrinth_question)
	Global.record_answer(q_id, correct, 0)
	
	# Si es correcta, procedemos a ejecutar el sonido 
	# de opcion correcta, esperamos a que termine e iniciamos
	# el procedimiento de cambio de pregunta.
	if correct:
		$CorrectSound.play()
		yield ($CorrectSound, "finished")
		next_question()
	else:
		# Si no fue correcta la opcion, colocamos la puerta correspondiente,
		# bloqueando la opcion correspondiente y procedemos a ejecutar 
		# la funcion de "fallo"
		var door_id = $Walls.tile_set.find_tile_by_name(door_ids[answer][0])
		$Walls.set_cellv(door_frames[door_ids[answer][1]], door_id)
		start_over()
	

func next_question():
	# Para proceder a la siguiente pregunta, en primer lugar pausamos el juego
	get_tree().paused = true
	# Mostramos la explicacion solo si existe una imagen asociada
	# (las preguntas generadas por IA no tienen imagen de explicacion)
	var explanation_list = Global.labyrinth_questions[Global.current_labyrinth_question].get("explanation", [])
	var explanation_path = explanation_list[0] if explanation_list.size() > 0 else ""
	if explanation_path != "":
		var explain = $CanvasLayer/Explanation/MarginContainer/VBoxContainer/TextureRect
		explain.texture = load(explanation_path)
		$CanvasLayer/Explanation.visible = true
		yield ($CanvasLayer/Explanation/MarginContainer/VBoxContainer/CloseExplanationBtn, "button_up")
		$CanvasLayer/Explanation.visible = false
	# Reanudamos el juego
	get_tree().paused = false
	# Avanzamos en las preguntas
	Global.current_labyrinth_question += 1
	# Comprobamos si era la ultima pregunta disponible o no.
	if Global.current_labyrinth_question >= Global.num_labyrinth_questions:
		# Si era la ultima pregunta disponible, reseteamos la pregunta actual
		# para el siguiente juego.
		Global.current_labyrinth_question = 0
		# Cambiamos a la escena final.
		var _ret = get_tree().change_scene("res://minigames/labyrinthofrule3/ui/EndScreenLR3.tscn")
	else:
		# Si no es la ultima pregunta, significa que qun hay preguntas.
		# Mostramos la siguiente pregunta al usuario
		set_question_hud()
		# Recargamos la escena.
		var _ret = get_tree().reload_current_scene()

func set_question_hud():
	# Funcion que se encarga de mostrar la pregunta correspondiente
	# con sus opciones en pantalla
	$CanvasLayer/HUD/Panel/HBoxContainer/QuestionMargin/Question.text = Global.labyrinth_questions[Global.current_labyrinth_question]["question"]
	$CanvasLayer/HUD/A/Answer.text = Global.labyrinth_questions[Global.current_labyrinth_question]["answerA"][0]
	$CanvasLayer/HUD/B/Answer.text = Global.labyrinth_questions[Global.current_labyrinth_question]["answerB"][0]
	$CanvasLayer/HUD/C/Answer.text = Global.labyrinth_questions[Global.current_labyrinth_question]["answerC"][0]
	$CanvasLayer/HUD/D/Answer.text = Global.labyrinth_questions[Global.current_labyrinth_question]["answerD"][0]
	Global.start_question_timer()

# Funcion que realiza el conteo del tiempo que el usuario esta jugando 
# juego. Su funcion consiste en, cada segundo, aumentar el contador de
# segundos del script global y mostrar el total en pantalla.
func _on_Timer_timeout():
	Global.total_labyrinth_time += 1
	$CanvasLayer/HUD/Time.text = str(Global.total_labyrinth_time)
