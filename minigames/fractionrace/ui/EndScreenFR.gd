extends Control

var path_to_stars = "res://assets/maze/Other/"
var default_start_position = "[center][rainbow]"
var default_start_time_info = "[center][wave freq=10.0]"
var default_time_info = "Congratulations!! You completed the lap\nin "
var extra_info = " seconds! And answering correctly " + str(Global.current_race_question) + " questions!"
var gold_color = "[color=#FFD700]"
var silver_color = "[color=#C0C0C0]"
var bronze_color = "[color=#CD7F32]"
var red_color = "[color=#FF0000]"
var color_to_set
var image

func _enter_tree():
	# Cada vez que entre la escena al arbol del proyecto de nuevo,
	# tenemos que comprobar que la musica tocada sea la correcta.
	MusicController.set_music()
	# Obtenemos la posicion y preparamos la forma en la que se dira:
	var pos_string = ""
	if Global.final_position == 1:
		pos_string = "You Ranked First!!"
		color_to_set = gold_color
		image = path_to_stars + "starGold.png"
	elif Global.final_position == 2:
		pos_string = "You Ranked Second!!"
		color_to_set = silver_color
		image = path_to_stars + "starSilver.png"
	elif Global.final_position == 3:
		pos_string = "You Ranked Third!!"
		color_to_set = bronze_color
		image = path_to_stars + "starBronze.png"
	elif Global.final_position == 4:
		pos_string = "You Ranked Fourth!!"
		color_to_set = red_color
		image = path_to_stars + "rock.png"
	else:
		pos_string = "ERROR!!"
		color_to_set = red_color
		image = path_to_stars + "rock.png"
		
	
	# Obtenemos un nodo donde se mostrara el mensaje de fin de juego al 
	# jugador
	var position_lab = $CanvasLayer/MarginContainer/VBoxContainer/Position
	
	# Formateamos el mensaje para indicar al jugador la posicion en la
	# que completo el minijuego.
	
	position_lab.bbcode_text = default_start_position
	position_lab.bbcode_text += "[img]" + image + "[/img]"
	position_lab.bbcode_text += pos_string
	position_lab.bbcode_text += "[img]" + image + "[/img]" + "[/rainbow][/center]"
	
	# Obtenemos el nodo donde se mostrara el mensaje de fin de juego al 
	# jugador
	var info_lab = $CanvasLayer/MarginContainer/VBoxContainer/TimeInfo
	
	# Formateamos el mensaje para indicar al jugador el tiempo empleado
	# para completar el minijuego, asi como las preguntas respondidas.
	
	info_lab.bbcode_text = default_start_time_info
	info_lab.bbcode_text += color_to_set
	info_lab.bbcode_text += default_time_info
	info_lab.bbcode_text += str(Global.total_race_time)
	info_lab.bbcode_text += " seconds, answering correctly to "
	info_lab.bbcode_text += str(Global.current_race_question)
	info_lab.bbcode_text += " questions![/color][/wave][/center]"
	
	# Si el jugador ha sido de los primeros lo celebramos con aplausos.
	if Global.final_position == 1 or Global.final_position == 2:
		$Applause.play()
	
	Global.end_session()

	# Reseteamos las variables que participan en el minijuego de la carrera
	# como contadores.
	Global.total_race_time = 0
	Global.current_race_question = 0
	Global.final_position = -1
	

func _on_Continue_button_up():
	# Si se presiona continuar, cambiamos de escena
	# Esto se realiza aqui para facilitar el hecho de que continuar
	# implique moverse a distintas escenas segun hayan mas niveles, se
	# este en modo historia, etc.
	var _ret = get_tree().change_scene("res://minigames/fractionrace/ui/StartScreenFR.tscn")
