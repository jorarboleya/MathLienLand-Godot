extends Node2D
# Variable que indica si los participantes pueden 
# moverse
var move_active = false
# Posicion de llegada
var pos = 0
# Numero de participantes
var numcharacters = 4
# Nombres de las 4 opciones. Son empleadas como claves en 
# distintos diccionarios.
var answers = ["answerA", "answerB", "answerC", "answerD"]
# Aceleracion de los rivales
var acceleration_rivals = 6
# Aceleracion del jugador
var acceleration_player = 4.5
# Intervalo en segundos para intentar acelerar
# a los rivales
var seconds_till_next_acceleration_try_rivals = 10
# Tiempo para empezar el juego
var countdown = 3
# Titulos que acompanyan la cuenta atras
var countdown_titles = ["Get Ready!!", "Steady!", "Go!"]
# Contador de cuenta atras.
var counter = 0

func _ready():
	# Cuando la escena este lista debemos obtener una nueva semilla
	# para los procesos aleatorios
	randomize()
	# Tambien debemos establecer los limites de la camara
	set_camera_limits()
	# Conectamos las senyales de contestacion
	var _ret
	_ret = $CanvasLayer/HUDFR.connect("race_answerA", self , "_on_Player_answered_a")
	_ret = $CanvasLayer/HUDFR.connect("race_answerB", self , "_on_Player_answered_b")
	_ret = $CanvasLayer/HUDFR.connect("race_answerC", self , "_on_Player_answered_c")
	_ret = $CanvasLayer/HUDFR.connect("race_answerD", self , "_on_Player_answered_d")
	# Establecemos la primera pregunta
	set_question_hud()
	Global.start_session("fractionrace")

func _enter_tree():
	# Cada vez que la escena entre al arbol de dependencias, 
	# debemos poner la musica correspondiente
	MusicController.set_music()
	# De igual forma debemos poner visible el panel de cuenta atras.
	# Y establecer su inicio.
	$CanvasLayer/HUDFR/StartScreen.visible = true
	$CanvasLayer/HUDFR/StartScreen/CenterContainer/VBoxContainer/Label.text = str(countdown)
	

func _on_Goal_area_entered(area):
	# Cuando se entre en la meta, debemos ir contando el numero 
	# de participantes que han ido alcanzando la meta con anterioridad.
	pos += 1
	# Si el competidor que ha llegado es el jugador, apuntamos
	# su posicion y cambiamos de escena.
	if area.get_parent().get_parent().name == "Player":
		Global.final_position = pos
		var _ret = get_tree().change_scene("res://minigames/fractionrace/ui/EndScreenFR.tscn")
		

func set_camera_limits():
	# Obtenemos las dimensiones de la pista en 
	# celdas
	var track_dims = $Ground.get_used_rect()
	# Obtenemos las dimensiones de las celdas en 
	# pixeles
	var cell_dims = $Ground.cell_size
	# Ponemos los limites en pixeles partiendo de las
	# dimensiones obtenidas.
	var player_camera = $Player/PathFollow2D/Character/Camera2D
	player_camera.limit_bottom = track_dims.end.y * cell_dims.y
	player_camera.limit_left = track_dims.position.x * cell_dims.x
	player_camera.limit_right = track_dims.end.x * cell_dims.x
	player_camera.limit_top = track_dims.position.y * cell_dims.y


func _on_StartTimer_timeout():
	# Cada vez que este timer emite timeout ha pasado un segundo,
	# por tanto, aumentamos el counter del countdown y si este 
	# ha pasado ya los countdown segundos, reseteamos su valor,
	# dejamos de mostrar el pamel de cuenta atras, permitimos el 
	# movimiento de los jugadores, iniciamos el conteo del tiempo
	# jugado y activamos los sonidos.
	counter += 1
	if counter == countdown + 1:
		counter = 0
		$CanvasLayer/HUDFR/StartScreen.visible = false
		move_active = true
		$Time.start()
		$Engine.play()
	else:
		# Si aun quedan segundos de cuenta atras,
		# lo mostramos en el panel de countdowns y volvemos a iniciar
		# el timer de cuenta atras.
		$CanvasLayer/HUDFR/StartScreen/CenterContainer/VBoxContainer/Title.text = countdown_titles[counter - 1]
		$CanvasLayer/HUDFR/StartScreen/CenterContainer/VBoxContainer/Label.text = str(countdown - counter)
		$StartTimer.start()

func set_question_hud():
	# Funcion que se encarga de mostrar la pregunta correspondiente
	# con sus opciones en pantalla
	$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin/VBoxContainer/QuestionContainer/question.texture = load(Global.race_questions[Global.current_race_question]["question"])
	$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin/VBoxContainer/HBoxContainer/answerA/TextureRect.texture = load(Global.race_questions[Global.current_race_question]["answerA"][0])
	$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin/VBoxContainer/HBoxContainer/answerB/TextureRect.texture = load(Global.race_questions[Global.current_race_question]["answerB"][0])
	$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin/VBoxContainer/HBoxContainer/answerC/TextureRect.texture = load(Global.race_questions[Global.current_race_question]["answerC"][0])
	$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin/VBoxContainer/HBoxContainer/answerD/TextureRect.texture = load(Global.race_questions[Global.current_race_question]["answerD"][0])
	Global.start_question_timer()

# Funcion que realiza el conteo del tiempo que el usuario esta jugando 
# juego. Su funcion consiste en, cada segundo, aumentar el contador de
# segundos del script global y mostrar el total en pantalla.
# En este juego, ademas, se emplea para cada X segundos dar (o no)
# aleatoriamente un aceleron a los contrincantes del jugador.
func _on_Time_timeout():
	Global.total_race_time += 1
	$CanvasLayer/HUDFR/Time.text = str(Global.total_race_time)
	# Cada X segundos se intentara dar un aceleron a los
	# contrincantes.
	if Global.total_race_time%seconds_till_next_acceleration_try_rivals == 0:
		var number = randi() % 2
		if number == 1:
			$Rival1.acceleration = acceleration_rivals
		number = randi() % 2
		if number == 1:
			$Rival2.acceleration = acceleration_rivals
		number = randi() % 2
		if number == 1:
			$Rival3.acceleration = acceleration_rivals

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
	var correct = Global.race_questions[Global.current_race_question][answer][1]
	var q_id = "fr_" + str(Global.current_race_question)
	Global.record_answer(q_id, correct, 0)
	
	# Si es correcta, aceleramos el personaje, con su correspondiente 
	# sonido, y, mientras no se termina el aceleron no se permite
	# otra contestacion ni tampoco el cambio de pregunta.
	if correct:
		#$CorrectSound.play()
		#yield($CorrectSound, "finished")
		$Player.acceleration = acceleration_player
		$Accelerate.play()
		$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin/VBoxContainer/HBoxContainer/answerA.disabled = true
		$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin/VBoxContainer/HBoxContainer/answerB.disabled = true
		$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin/VBoxContainer/HBoxContainer/answerC.disabled = true
		$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin/VBoxContainer/HBoxContainer/answerD.disabled = true
		yield ($Accelerate, "finished")
		next_question()
		$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin/VBoxContainer/HBoxContainer/answerA.disabled = false
		$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin/VBoxContainer/HBoxContainer/answerB.disabled = false
		$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin/VBoxContainer/HBoxContainer/answerC.disabled = false
		$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin/VBoxContainer/HBoxContainer/answerD.disabled = false
	else:
		# Si no es correcta simplemente lo indicamos con un sonido.
		$Wrong.play()
	
func next_question():
	# Avanzamos en las preguntas
	Global.current_race_question += 1
	# Comprobamos si era la ultima pregunta disponible o no.
	if Global.current_race_question >= Global.num_race_questions:
		# Si era la ultima pregunta disponible, lo indicamos y esperamos
		# que se llegue a la meta para cambiar de escena.
		$CanvasLayer/HUDFR/Panel/HBoxContainer/QuestionMargin.visible = false
		$CanvasLayer/HUDFR/Panel/HBoxContainer/EndQuestions.visible = true
	else:
		# Si no es la ultima pregunta, significa que qun hay preguntas.
		# Mostramos la siguiente pregunta al usuario
		set_question_hud()
