extends Node2D
# Variable para introducir la escena del
# meteorito que se empleara para crear
# instancias
export(PackedScene) var meteor_scene
# Variable que limita el maximo numero que puede
# aparecer en el juego.
export(float) var max_number = 1000.00
# Variable que limita el minimo numero que puede
# aparecer en el juego.
export(float) var min_number = 0.001
# Variable que permite establecer la reduccion
# en tiempo tras respuestas correctas. Con ello,
# ayuda a delimitar la dificultad.
export(float) var step_apparition_meteors = 0.5
# Variable que indica cada cuantas instancias incorrectas
# como maximo se debe crear una instancia correcta.
export(int) var max_span_correct_answer = 5
# Variable que indica la maxima longitud de un numero
export(int) var max_number_length = 6

# Constante que indica el exponente cubico.
const CUBIC_EXP = 3
# Constante que indica el exponente cuadratico
const SQ_EXP = 2
# Constante que indica el exponente lineal
const LINEAR_EXP = 1
# Constante que indica el tiempo para
# cambiar a la escena final.
const CHANGING_SCENE_TIME = 5
# Numero de vidas extra del jugador
var lives = 3
# Numero de instancias incorrectas seguidas que se
# han generado actualmente.
var cur_span_correct_answer = 0
# Variable para permitir el movimiento del jugador.
var can_move = true

# Textura necesaria para indicar la perdida de vidas del jugador.
onready var empty_heart = load("res://assets/meteors/platformPack_item005.png")

# Diccionario con las magnitudes consideradas junto a cadenad
# que representan cada unidad usada en el juego. Como ultimo
# elemento de la lista valor tendremos el exponente de 10 sobre
# el que se realizan las conversiones de una unidad a otra.
var units = {"mass": ["mg", "cg", "dg", "g", "dag", "hg", "kg", LINEAR_EXP], # Mass
				"length": ["mm", "cm", "dm", "m", "dam", "hm", "km", LINEAR_EXP], # Length
				"area": ["mm", "cm", "dm", "m", "dam", "hm", "km", SQ_EXP], # Area
				"vol": ["mm", "cm", "dm", "m", "dam", "hm", "km", CUBIC_EXP], # Vol in meters
				"voll": ["ml", "cl", "dl", "l", "dal", "hl", "kl", LINEAR_EXP]} # Vol in liters
# Magnitudes consideradas.
var magnitudes = ["mass", "length", "area", "vol", "voll"]
# Equivalencias entre unidades.
var equivalents = {
	"m[sup][b]3[/b][/sup]": "kl",
	"dm[sup][b]3[/b][/sup]": "l",
	"cm[sup][b]3[/b][/sup]": "ml",
	"kl": "m[sup][b]3[/b][/sup]",
	"l": "dm[sup][b]3[/b][/sup]",
	"ml": "cm[sup][b]3[/b][/sup]",
}
# Numero actual.
var cur_value
# Unidad correcta actual.
var cur_unit
# Unidades equivalentes a la actual.
var cur_equivalent_units = {}

# Funcion necesaria para anyadir los superindices
# a las unidades que lo necesiten
func add_superindex(text, superindex):
	return str(text) + "[sup][b]" + str(superindex) + "[/b][/sup]"

func _ready():
	# En primer lugar, establecemos la musica del minijuego
	MusicController.set_music()
	# Nos aseguramos de generar una nueva semilla para
	# los sucesos aleatorios cada vez.
	randomize()
	# Establecemos correctamente las unidades que tendremos
	# en cuenta.
	for j in range(len(units["area"]) - 1):
		units["area"][j] = add_superindex(units["area"][j], SQ_EXP)
	
	for j in range(len(units["vol"]) - 1):
		units["vol"][j] = add_superindex(units["vol"][j], CUBIC_EXP)

	# Conectamos las senyales
	var _ret = $CanvasLayer/Player.connect("correct_answer", self , "correct_answer")
	_ret = $CanvasLayer/Player.connect("wrong_answer", self , "wrong_answer")
	
	# Establecemos la pregunta a realizar.
	set_question()
	Global.start_session("decimalsystemmeteors")


func _on_MeteorTimer_timeout():
	# Idea plenamente obtenida de:
	# https://www.youtube.com/watch?v=TKpTvpeHh3U
	# Establecemos un punto aleatorio de spawn de la instancia.
	$MeteorPath/PathFollow2D.set_unit_offset(randf())
	
	# Instanciamos el meteorito y lo anyadimos en la escena
	# correctamente
	var meteor = meteor_scene.instance()
	$CanvasLayer.add_child(meteor)
	
	# Establecemos la posicion inicial del meteorito
	meteor.position = $MeteorPath/PathFollow2D.position
	
	# Con una rotacion determinada por el punto de spawn y
	# perpendicular a el.
	var meteor_dir = $MeteorPath/PathFollow2D.rotation + PI / 2
	# Modificamos la direccion ligeramente para dar mas dinamismo
	meteor_dir += rand_range(-PI / 5, PI / 5)
	#meteor.rotation = meteor_dir
	
	# Establecemos una velocidad de meteorito dentro del minimo y el maximo
	# establecidos.
	var velocity = Vector2(rand_range(meteor.lower_speed_limit, meteor.upper_speed_limit), 0)
	# La velocidad tambien debe ser rotada para que se mueva correctamente.
	meteor.linear_velocity = velocity.rotated(meteor_dir)
	
	# Una vez creado el meteorito, procedemos a incluir en el
	# una posible respuesta a la pregunta actual generada
	# aleatoriamente.
	var random_magn
	var random_unit
	# En un principio, el meteorito aun no tiene una opcion
	# correcta ni incorrecta.
	var correct_meteor = null
	# En un principio, consideramos que el meteorito creado
	# sera de una respuesta incorrecta, con lo que incrementamos
	# el contador correspondiente.
	cur_span_correct_answer += 1
	# Mientras el meteorito aun no tenga una opcion correcta o incorrecta
	# o mientras se llegue al limite de preguntas incorrectas
	# consecutivas, seguiremos intentando crear nuevas opciones de
	# respuestas para finalizar la correcta creacion del meteorito
	while correct_meteor == null or cur_span_correct_answer >= max_span_correct_answer:
		# Escogemos una magnitud aleatoria para la opcion que mostrara el meteorito
		random_magn = magnitudes[randi()%len(magnitudes)]
		# Escogemos una unidad aleatoria para la opcion que mostrara el meteorito
		random_unit = units[random_magn][randi() % (len(units[random_magn]) - 1)]
		# Establecemos si la opcion mostrada por el meteorito es correcta o no.
		correct_meteor = random_unit == cur_unit or random_unit in cur_equivalent_units.keys()
		# Si es correcta, reseteamos el contador de aparicion de opciones incorrectas
		# consecutivas.
		if correct_meteor:
			cur_span_correct_answer = 0
	
	# Una vez ya se ha establecido correctamente una opcion a mostrar en el
	# meteorito.
	meteor.set_text(str(cur_value) + random_unit)
	
	# Anyadimos el meteorito al grupo correspondiente,
	# para que la colision con el mismo se pueda tratar apropiadamente.
	if random_unit == cur_unit or random_unit in cur_equivalent_units.keys():
		meteor.add_to_group("correct")
	else:
		meteor.add_to_group("wrong")


func set_question():
	# Escogemos un numero al azar. Sera el numero que aparezca
	# en la pregunta.
	# Numeros iniciales, se sobreescribiran.
	var question_number = 0
	var answer_number = 1000000
	
	# Mientras el numero a preguntar y el numero de la
	# respuesta no cumplan los limites numericos y de cadena
	# establecidos, calculamos nuevos datos.
	var recalculate = true
	while recalculate:
		# Calculamos un numero aleatorio para la pregunta.
		# Es necesario que sea un numero entero para facilitar
		# el juego a los ninos.
		question_number = stepify(rand_range(min_number, max_number), 1)
		#var ceil_exponent = ceil(log(question_number)/log(10))
		#var index = ceil_exponent+3
		
		
		# Seleccionamos una magnitud a poner en la pregunta.
		var sel_mag = magnitudes[randi()%len(magnitudes)]
		# Seleccionamos la unidad de la pregunta.
		var index_unit = randi() % (len(units[sel_mag]) - 1)
		var sel_unit = units[sel_mag][index_unit]
		
		#question_number = question_number / pow(10, index_unit*units[sel_mag][-1])
		
		# Preparamos la respuesta.
		# La unidad de respuesta tiene que se distinta a la
		# unidad de la pregunta.
		var answer_unit = index_unit
		while answer_unit == index_unit:
			answer_unit = randi() % (len(units[sel_mag]) - 1)
		
		# Comprobamos la distancia entre ambas unidades.
		var distance = answer_unit - index_unit
		# Convertimos el numero de la pregunta a las unidades
		# de la respuesta.
		answer_number = question_number / pow(10, distance * units[sel_mag][-1])
		# Establecemos el texto de la question.
		$CanvasLayer2/HUDDSM.set_question(str(question_number) + sel_unit)
		# Comprobamos si hay que recalcular la respuesta y su pregunta.
		# Esto se necesitara si el numero de la respuesta se sale
		# de los limites de los numeros impuestos o si el numero de la respuesta
		# o pregunta es mas largo de lo permitido.
		recalculate = answer_number < min_number
		recalculate = recalculate or answer_number > max_number
		recalculate = recalculate or len(str(question_number)) > max_number_length
		recalculate = recalculate or len(str(answer_number)) > max_number_length
		# Si todo ha ido bien y no es necesario recalcular,
		if not recalculate:
			# Establecemos como valor actual el numero
			# de respuesta calculado.
			cur_value = answer_number
			# Establecemos como unidad actual la del numero
			# de respuesta calculado.
			cur_unit = units[sel_mag][answer_unit]
			# Establecemos igualmente las equivalencias aceptadas.
			if equivalents.get(cur_unit) != null:
				cur_equivalent_units[equivalents.get(cur_unit)] = true
			else:
				cur_equivalent_units.clear()

	Global.start_question_timer()

func correct_answer():
	var q_id = "dsm_" + str(Global.meteor_score)
	Global.record_answer(q_id, true, 0)
	# Si se ha colisionado con una opcion correcta.
	# Aumentamos la puntuacion del jugador y lo
	# mostramos por pantalla.
	Global.meteor_score += 1
	$CanvasLayer2/HUDDSM.update_score(Global.meteor_score)
	
	# Establecemos una nueva pregunta
	set_question()
	
	# De igual forma, limpiamos la escena de meteoritos, para
	# generar nuevas opciones acorde con la nueva pregunta.
	get_tree().call_group("meteors", "queue_free")
	
	# Asimismo, disminuimos el intervalo de tiempo
	# entre apariciones de nuevos meteoritos para aumentar la
	# dificultad.
	if $MeteorTimer.wait_time - step_apparition_meteors > 0:
		$MeteorTimer.wait_time -= step_apparition_meteors

func wrong_answer():
	# Si se trata de una colision con una opcion incorrecta
	# y aun tiene alguna vida extra.
	if lives > 0:
		# Indicamos graficamente la perdida de una vida extra,
		# segun corresponda.
		match lives:
			1:
				$CanvasLayer2/HUDDSM/Life1.texture = empty_heart
			2:
				$CanvasLayer2/HUDDSM/Life2.texture = empty_heart
			3:
				$CanvasLayer2/HUDDSM/Life3.texture = empty_heart
		# Decrementamos las vidas extras disponibles.
		lives -= 1
	# Si por el contrario ya no se cuentan con vidas extras.
	else:
		# Impedimos el movimiento del jugador.
		can_move = false
		# Impedimos que pueda colisionar con otra cosa.
		$CanvasLayer/Player/CollisionShape2D.set_deferred("disabled", true)
		# Hacemos aparecer el mensaje de fin de juego.
		$CanvasLayer2/HUDDSM/AnimationPlayer.play("Appear")
		# Ejecutamos el sonido final y paramos la aparicion
		# de meteoritos
		$FinalSound.play()
		$MeteorTimer.stop()
		# Esperamos el tiempo indicado para cambiar de escena y tras
		# eso cambiamos de escena.
		yield (get_tree().create_timer(CHANGING_SCENE_TIME), "timeout")
		var _ret = get_tree().change_scene("res://minigames/decimalsystemmeteors/ui/EndScreenDSM.tscn")


func _on_Timer_timeout():
	# Cada segundo, aumentaremos el contador del tiempo
	# y lo mostraremos.
	Global.total_meteors_time += 1
	$CanvasLayer2/HUDDSM.update_time(Global.total_meteors_time)
