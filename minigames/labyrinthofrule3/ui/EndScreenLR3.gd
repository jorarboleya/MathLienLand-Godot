extends Control

func _enter_tree():
	# Cada vez que entre la escena al arbol del proyecto de nuevo,
	# tenemos que comprobar que la musica tocada sea la correcta.
	MusicController.set_music()
	# Obtenemos el nodo donde se mostrara el mensaje de fin de juego al 
	# jugador
	var node = $CanvasLayer/MarginContainer/VBoxContainer/Label
	
	# Formateamos el mensaje para indicar al jugador el tiempo empleado
	# para completar el minijuego.
	node.text = node.text.format({"seconds": str(Global.total_labyrinth_time)})
	# Reseteamos las variables que participan en el minijuego del laberinto
	# como contadores.
	Global.end_session()
	Global.total_labyrinth_time = 0
	Global.current_labyrinth_question = 0
	

func _on_Continue_button_up():
	# Si se presiona continuar, cambiamos de escena
	# Esto se realiza aqui para facilitar el hecho de que continuar
	# implique moverse a distintas escenas segun hayan mas niveles, se
	# este en modo historia, etc.
	var _ret = get_tree().change_scene("res://minigames/labyrinthofrule3/ui/StartScreenLR3.tscn")
