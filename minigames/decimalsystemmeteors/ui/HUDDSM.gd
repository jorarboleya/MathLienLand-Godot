extends Control

func _ready():
	# Forzamos un texto neutro al cargar la escena, para que aunque
	# Level0DSM.set_question() falle o tarde, el jugador nunca vea
	# el placeholder "XXX cm³" del editor.
	var question = $Panel/HBoxContainer/QuestionMargin/Question
	question.bbcode_text = "[center]Loading...[/center]"

func _on_BackBtn_button_up():
	# Si el usuario desea volver a la pantalla de inicio del
	# juego, reseteamos las variables que controlan la aparicion
	# de preguntas y cambiamos de escena.
	Global.meteor_score = 0
	Global.total_meteors_time = 0
	var _ret = get_tree().change_scene("res://minigames/decimalsystemmeteors/ui/StartScreenDSM.tscn")

func _on_PauseBtn_button_up():
	# Si el usuario desea pausar la escena, mostramos un panel
	# auxiliar que permita al usuario reanudar el juego y
	# pausamos el juego.
	if not $PausedScreen.visible:
		get_tree().paused = true
		$PausedScreen.visible = true


func _on_ResumeBtn_button_up():
	# Si el usuario desea continuar con el juego, dejamos de
	# mostrar el panel de pausa y reanudamos el juego.
	if $PausedScreen.visible:
		get_tree().paused = false
		$PausedScreen.visible = false

func set_question(text):
	# Establecemos una nueva pregunta con el texto pasado
	# como argumento.
	var question = $Panel/HBoxContainer/QuestionMargin/Question
	# La pregunta siempre sera la misma, cambiara el numero preguntado
	question.bbcode_text = "[center]What is equivalent to:\n[color=blue]"
	question.bbcode_text += text
	question.bbcode_text += "[/color]?[/center]"

func update_score(score):
	# Actualizamos la puntuacion del jugador
	$Score/Label.text = str(score)

func update_time(time):
	# Actualizamos el tiempo empleado en
	# el minijuego
	$Time/Label.text = str(time)
