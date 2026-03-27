extends Node2D

# Variable que indica cuantas colinas
# se generaran cada vez
export(int) var num_hills = 6
# Numero de puntos para definir cada colida
export(int) var hill_slices = 10
# Altura maxima de una colina.
export(int) var hill_height_range = 150
# Maximo preguntas que se haran en el juego
export(int) var max_questions = 15
# Escena que representa al objeto coleccionable
export(PackedScene) var collectible
#Textura de las colinas
var hills_texture = preload("res://assets/hills/grass.png")
# Numeros de los cuales sus criterios de
# divisibilidad se repasaran.
var criteria_numbers = [2, 3, 4, 5, 6, 9, 10, 11]
# Maximo elemento multiplicador
var max_multiplicator = 500
# Maximo elemento gcd que podemos generar
# en principio.
var max_gcd = 25
# Diccionaro empleado para mostrar y tratar las preguntas.
var current_question = {"type": 0, "text": "", "correct_answer": - 1,
						"options": {"A": "", "B": "", "C": "", "D": ""}}
# El tam de la pantalla
var screensize
# Los puntos que iran constituyendo las colinas
var hills = Array()
# Puntuacion del jugador
var score = 0
# Variable que permite o inhibe el movimiento
var can_move = true
# Tiempo empleado en el juego por el jugador
var time = 0
# Variable para indicar si hay que reestablecer
# el temporizador de game over
var restart_timer = false

func _ready():
	Global.start_session("dividinghills")
	# En primer lugar, cuando la escena entre al 
	# arbol de dependencias tendremos que resetar 
	# todos los contadores.
	# Contador de preguntas acertadas
	Global.ncorrect_hills = 0
	# Contador total preguntas respondidas
	Global.total_hills_questions = 0
	# Tiempo de juego
	Global.total_hills_time = 0
	# Establecemos musica.
	MusicController.set_music()
	# Generamos una nueva semilla para los procesos 
	# aleatoreos.
	randomize()
	# Conectamos las senyales de contestacion
	var _ret
	_ret = $CanvasLayer/HUDDH.connect("hills_answerA", self , "_on_Player_answered_a")
	_ret = $CanvasLayer/HUDDH.connect("hills_answerB", self , "_on_Player_answered_b")
	_ret = $CanvasLayer/HUDDH.connect("hills_answerC", self , "_on_Player_answered_c")
	_ret = $CanvasLayer/HUDDH.connect("hills_answerD", self , "_on_Player_answered_d")
	# Y la senyal de game over
	_ret = $Player.connect("game_over", self , "game_over")
	# Generamos las primeras colinas
	hills = Array()
	screensize = get_viewport().get_visible_rect().size
	
	# Anyadimos una altura extra al starting point desde
	# -hill_height_range hasta hill_height_range.
	var extra_starting_height = - hill_height_range + randi() % (hill_height_range * 2)
	var start_height = screensize.y * 3 / 4 + extra_starting_height
	# Equiparamos el decorado al offset de la camara y a la 
	# altura inicial de las colinas.
	$ParallaxBackground/Decorations.position.x = 0
	$ParallaxBackground/Decorations.position.y = start_height + 200
	$ParallaxBackground/Decorations.motion_offset.y = start_height
	$ParallaxBackground/Decorations2.position.x = 0
	$ParallaxBackground/Decorations2.position.y = start_height + 200
	$ParallaxBackground/Decorations2.motion_offset.y = start_height
	
	# Introducimos el primer punto de las colinas y generamos
	# el siguiente conjunto de las mismas.
	hills.append(Vector2(0, start_height))
	generate_hills()
	# Establecemos la primera pregunta.
	set_question()
	
func _process(_delta):
	# Obtenemos las coordinadas del ultimo punto
	# perteneciente al contorno de las colinas.
	var target_x = hills[-1].x
	var target_y = hills[-1].y
	# Si el jugador se ha acercado lo suficiente al
	# ultimo punto generado, generamos mas colinas
	# y el dicho punto colocamos un objeto
	# coleccionable. Finalmente, conectamos
	# su recolectado con la funcion correspondiente.
	if target_x < $Player.position.x + screensize.x * 4:
		generate_hills()
		var pickup = collectible.instance()
		pickup.position = Vector2(target_x, target_y - 32)
		add_child(pickup)
		var _ret
		_ret = pickup.connect("chest_collected", self , "pop_up_question")
	
func generate_hills():
	# Idea general de creacion procedural del terreno obtenida 
	# y adaptada del tutorial obtenido de 
	# https://www.youtube.com/watch?v=QLZa1mjW-YU, cuyo codigo fuente
	# puede encontrarse en github:
	# https://github.com/kidscancode/godot3_procgen_demos/blob/master/part05/Godot3_2Dterrain2/Terrain.gd
	# Cuanto puede ocupar como maximo una colina y su alrededor.
	# Modificacion relevante: hills_width, realizada con el objetivo
	# de generar mas colinas cada vez.
	var hills_width = screensize.x * 4 / num_hills
	var hill_slice_width = hills_width / hill_slices
	# El nuevo punto empezara tras el ultimo
	var starting_point = hills[-1]
	# Creamos el poligono que definira el rellenado
	# de textura y la forma de colision.
	var polygon = PoolVector2Array()
	# Por cada columna a generar 
	for new_hill in range(0, num_hills):
		# Obtenemos al azar una altura de colina
		var hill_height = randi()%hill_height_range
		starting_point.y -= hill_height
		# Por cada punto de dicha colina, lo vamos
		# creando y anyadiendo a los puntos de colinas
		# y al poligono anterior.
		for hill_slice in range(hill_slice_width):
			var hill_point = Vector2()
			hill_point.x = starting_point.x + hill_slice * hill_slices + hills_width * new_hill
			hill_point.y = starting_point.y + hill_height * cos(2 * PI / hill_slice_width * hill_slice)
			hills.append(hill_point)
			polygon.append(hill_point)
		starting_point.y += hill_height
	var shape = CollisionPolygon2D.new()
	#var shape = $StaticBody2D/CollisionPolygon2D
	var hill_grass = Polygon2D.new()
	#var hill_grass = $Polygon2D
	# Anyadimos la forma de colision a las colinas
	$StaticBody2D.add_child(shape)
	# Anyadimos puntos de cerrado del poligono
	polygon.append(Vector2(hills[-1].x, screensize.y * 5))
	polygon.append(Vector2(starting_point.x, screensize.y * 5))
	shape.polygon = polygon
	hill_grass.polygon = polygon
	hill_grass.texture = hills_texture
	add_child(hill_grass)

func set_question():
	var node_a = $CanvasLayer/HUDDH/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/A
	var node_b = $CanvasLayer/HUDDH/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/B
	var node_c = $CanvasLayer/HUDDH/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/C
	var node_d = $CanvasLayer/HUDDH/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/D

	# Use AI-generated questions if available; otherwise generate procedurally
	if Global.dh_questions.size() > 0:
		var idx = Global.dh_question_index % Global.dh_questions.size()
		Global.dh_question_index += 1
		_load_ai_dh_question(Global.dh_questions[idx])
	else:
		var selector = randi() % 2
		if selector == 0:
			set_divisibility_criteria_question()
		else:
			set_gcd_question()

	if current_question["type"] == 0:
		node_c.visible = false
		node_d.visible = false
	else:
		node_c.visible = true
		node_d.visible = true
		node_c.text = current_question["options"]["C"]
		node_d.text = current_question["options"]["D"]
	node_a.text = current_question["options"]["A"]
	node_b.text = current_question["options"]["B"]
	var question = $CanvasLayer/HUDDH/MarginContainer/Panel/MarginContainer/VBoxContainer/Question
	question.text = current_question["text"]

# Translates an AI-generated question dict into the current_question format
func _load_ai_dh_question(q):
	current_question["type"] = int(q["type"])
	current_question["text"] = str(q["text"])
	current_question["options"]["A"] = str(q["options"]["A"])
	current_question["options"]["B"] = str(q["options"]["B"])
	if int(q["type"]) == 0:
		current_question["options"]["C"] = ""
		current_question["options"]["D"] = ""
		# answer "A" = No = 0, "B" = Yes = 1
		current_question["correct_answer"] = 0 if str(q["answer"]) == "A" else 1
	else:
		current_question["options"]["C"] = str(q["options"]["C"])
		current_question["options"]["D"] = str(q["options"]["D"])
		# correct_answer is the actual GCD integer
		current_question["correct_answer"] = int(str(q["options"][str(q["answer"])]))

func set_divisibility_criteria_question():
	# Seleccionamos aleatoriamente uno de los 
	# elementos cuyos criterios de divisibilidad
	# queremos poner a prueba.
	var nselector = randi()%criteria_numbers.size()
	var chosen_num = criteria_numbers[nselector]
	# Generamos un multiplo de dicho numero
	# Sumamos dos pues no queremos que salga
	# ni el 0 ni el 1 nunca.
	var question_num = chosen_num * (randi()%max_multiplicator + 2)
	# Aleatoreamente vemos si queremos que la 
	# pregunta deba responderse con verdadero 
	# o con falso.
	var aselector = randi() % 2
	if aselector == 0:
		# Si queremos que sea falso, sumamos uno
		# al multiplo obtenido de tal forma que
		# ya no sea divisible por chosen_num
		question_num += 1
	# Rellenamos datos de la pregunta segun lo anteriomente
	# calculado.
	current_question["type"] = 0
	current_question["text"] = "Is " + str(question_num) + " divisible by\n" + str(chosen_num) + "?"
	current_question["correct_answer"] = aselector
	current_question["options"]["A"] = "No"
	current_question["options"]["B"] = "Yes"
	current_question["options"]["C"] = ""
	current_question["options"]["D"] = ""

func set_gcd_question():
	# Obtenemos un numero aleatorio entre 
	# 10 y max_gdc + 10 - 1.
	var gcd = randi()%max_gcd + 10
	# Obtenemos dos numeros distintos y menores que
	# el gcd elegido.
	var a = 1
	var b = 1
	# No pueden ser iguales ni tampoco 
	# divisibles entre si.
	while a%b == 0 or b%a == 0:
		a = randi() % (gcd - 2) + 2
		b = a
		while b == a:
			b = randi() % (gcd - 2) + 2
	
	# Los multiplicamos por el gcd elegido
	# para obtener los dos numeros de la pregunta
	var first_number = a * gcd
	var second_number = b * gcd
	
	# Observamos si exiten factores entre los numeros
	# multiplicados por gcd para asegurarnos de obtener el gcd
	# correcto. Esto es pues a y b pueden tener factores
	# primos en comun.
	gcd = gcd * euclidean_gcd(a, b)
	
	# Establecemos como posibles respuestas a y b 
	# ademas de gcd pues no seran numeros conocidos
	# para el jugador
	var option_set = {gcd: true, a: true, b: true, }
	# Calculamos la ultima opcion aleatoreamente
	# entre 2 y 2*gcd, aproximadamente
	while option_set.keys().size() < 4:
		var new_option = randi() % (gcd * 2) + 2
		option_set[new_option] = true
	
	# Rellenamos datos de la pregunta segun lo anteriomente
	# calculado, asegurandonos que las opciones
	# se rellenen de forma aleatoria.
	current_question["type"] = 1
	current_question["text"] = "Select the gcd of " + str(first_number) + " and " + str(second_number) + ":"
	current_question["correct_answer"] = gcd
	var option_list = option_set.keys()
	option_list.shuffle()
	current_question["options"]["A"] = str(option_list[0])
	current_question["options"]["B"] = str(option_list[1])
	current_question["options"]["C"] = str(option_list[2])
	current_question["options"]["D"] = str(option_list[3])

func _on_Player_answered_a():
	# En primer lugar deshabilitamos 
	# las respuestas del jugador.
	disable_player_answer()
	# Comprobamos el tipo de pregunta y 
	# acorde con ello procedemos a traducir
	# la opcion que el jugador ha seleccionado
	# como respuesta a un numero para que pueda
	# ser comprobado.
	if current_question["type"] == 0:
		check_answer(0)
	else:
		check_answer(int(current_question["options"]["A"]))
	
func _on_Player_answered_b():
	# Se realiza lo mismo que en el caso de la
	# opcion A
	disable_player_answer()
	if current_question["type"] == 0:
		check_answer(1)
	else:
		check_answer(int(current_question["options"]["B"]))
	
func _on_Player_answered_c():
	# Para este caso la pregunta solo puede 
	# ser de tipo 1, con lo que pasamos el numero
	# de la opcion elegida.
	disable_player_answer()
	check_answer(int(current_question["options"]["C"]))

func _on_Player_answered_d():
	# Se realiza lo mismo que en el caso de la
	# opcion C
	disable_player_answer()
	check_answer(int(current_question["options"]["D"]))

func check_answer(answer):
	var q_id = "dh_" + str(Global.total_hills_questions)
	var is_correct = (answer == current_question["correct_answer"])
	Global.record_answer(q_id, is_correct, 0)
	# Aumentamos en 1 el numero de preguntas respondidas.
	Global.total_hills_questions += 1
	# Comprobamos si en este punto el temporizador
	# de game over esta activo para pararlo y volverlo
	# a activar tras la constentacion de la pregunta.
	# var restart_timer = false
	# if !$Player/GameOverTimer.is_stopped():
	#	restart_timer = true
	#	$Player/GameOverTimer.stop()

	var feed_text
	# Si la respuesta es correcta, aumentamos el numero de
	# preguntas acertadas, activamos el sonido de acierto
	# establecemos el texto de feedback, rellenamos el 
	# combustible del jugador y actualizamos
	# la puntiacion del mismo.
	if answer == current_question["correct_answer"]:
		Global.ncorrect_hills += 1
		$RightAnswerSound.play()
		feed_text = "Correct!! Well done!! \nYou got 1 additional coins"
		score += 1
		$Player.refuel()
		$CanvasLayer/HUDDH.set_score(score)
	else:
		# Si es incorrecta, activamos el sonido de error
		# y establecemos el texto de feedback.
		$WrongAnswerSound.play()
		feed_text = "Ups, wrong answer!\n If you pause the game,\n"
		feed_text += "the given divisibility\nrules may help you!"
	
	
	#var feed_panel = $CanvasLayer/HUDDH/MarginContainer/Panel2/MarginContainer/VBoxContainer/Feedback
	#feed_panel.text = feed_text
	# Establecemos la pantalla de feedback y la mostramos
	$CanvasLayer/HUDDH.show_feedback(feed_text)
	$CanvasLayer/HUDDH/MarginContainer/Panel2.visible = true
	# Establecemos la proxima pregunta
	set_question()
	# Permitimos la respuesta del jugador a la misma, aunque
	# todavia no puede porque no se muestra la pregunta aun.
	enable_player_answer()
	# Esperamos que el jugador presione continuar en la 
	# pantalla de feedback
	yield ($CanvasLayer/HUDDH, "continue_pressed")
	# Y ocultamos los paneles de preguntas, permitimos
	# el movimiento y, si procede, reaunadomos el timer de
	# game over
	$CanvasLayer/HUDDH/MarginContainer/Panel2.visible = false
	$CanvasLayer/HUDDH/MarginContainer/Panel.visible = false
	can_move = true
	if restart_timer:
		$Player/GameOverTimer.start()
	# Comprobamos el limite de preguntas a realizar, si
	# nos pasamos, salimos del juego
	if Global.total_hills_questions >= max_questions:
		game_over()

func disable_player_answer():
	# Deshabilitamos todos los botones de respuesta.
	$CanvasLayer/HUDDH/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/A.disabled = true
	$CanvasLayer/HUDDH/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/B.disabled = true
	$CanvasLayer/HUDDH/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/C.disabled = true
	$CanvasLayer/HUDDH/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/D.disabled = true

func enable_player_answer():
	# Habilitamos todos los botones de respuesta.
	$CanvasLayer/HUDDH/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/A.disabled = false
	$CanvasLayer/HUDDH/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/B.disabled = false
	$CanvasLayer/HUDDH/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/C.disabled = false
	$CanvasLayer/HUDDH/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/D.disabled = false

func euclidean_gcd(n1, n2):
	# Funcion que plasma el algoritmo euclideo
	# para calcular el gcd de dos numeros.
	var aux
	while n2 != 0:
		aux = n2
		n2 = n1%n2
		n1 = aux
	return n1

func pop_up_question():
	# Funcion que muestra la siguiente pregunta, 
	# impidiendo el movimiento del jugador y mostrando
	# el panel correspondiente.
	can_move = false
	# Comprobamos si en este punto el temporizador
	# de game over esta activo para pararlo y volverlo
	# a activar tras la constentacion de la pregunta.
	restart_timer = false
	if !$Player/GameOverTimer.is_stopped():
		restart_timer = true
		$Player/GameOverTimer.stop()
	$CanvasLayer/HUDDH/MarginContainer/Panel.visible = true

	Global.start_question_timer()

func game_over():
	# Cuando el temporizador de game over termina, 
	# cambiamos a la escena final
	var _ret = get_tree().change_scene("res://minigames/dividinghills/ui/EndScreenDH.tscn")
	
func update_fuel_HUD(value):
	# Actualiamos los niveles de combustible mostrados
	$CanvasLayer/HUDDH.set_fuel(value)

func _on_Timer_timeout():
	# Contamos el tiempo de juego y 
	# lo mostramos
	time += 1
	Global.total_hills_time += 1
	$CanvasLayer/HUDDH.set_time(time)
