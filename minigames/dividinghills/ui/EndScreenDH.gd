extends Control
# Establecemos el principio y el final de 
# la cadena a mostrar, para establecer su formato.
var default_start_bbtext = "[center][wave freq=3 ampl=10][color=#FFD700]"
var default_end_bbtext = "[/color][/wave][/center]"

func _enter_tree():
	# Cada vez que entre la escena al arbol del proyecto de nuevo,
	# tenemos que comprobar que la musica tocada sea la correcta.
	MusicController.set_music()
	
	# Establecemos la informacion del juego asociada con el 
	# jugador que se desea mostrar.
	var info = "You answered correctly " + str(Global.ncorrect_hills)
	info += " out of a total of " + str(Global.total_hills_questions)
	info += "\nquestions in " + str(Global.total_hills_time) + " seconds!!"
	
	# Asignamos el texto que queremos mostrar al texto de la
	# label correspondiente.
	var label_to_set = $CanvasLayer/MarginContainer/VBoxContainer/PlayerInfo
	label_to_set.bbcode_text = default_start_bbtext + info + default_end_bbtext
	
	# Reseteamos las variables que participan en el minijuego correspondiente
	# como contadores.
	Global.end_session()
	Global.ncorrect_hills = 0
	Global.total_hills_questions = 0
	Global.total_hills_time = 0
	

func _on_Continue_button_up():
	# Si se presiona continuar, cambiamos de escena
	# Esto se realiza aqui para facilitar el hecho de que continuar
	# implique moverse a distintas escenas segun hayan mas niveles, se
	# este en modo historia, etc.
	var _ret = get_tree().change_scene("res://minigames/dividinghills/ui/StartScreenDH.tscn")
