# ----------------- Codigo Base obtenido de: -----------------
# 			https://github.com/CVelasco2/Function-Memory
extends Control

#Se definen las variables necesarias
var deck = Array()
var cardBack = preload("res://assets/memory_cards/cardBack_blue2.png")
var card1
var card2

var score = 0
var seconds = 0
var moves = 0
var scoreLabel
var timerLabel
var movesLabel
var resetButton
var goal = 5

#Se establecen todos los valores iniciales del juego
func _ready():
	#Se rellena la baraja
	fillDeck()
	#Se barajan las cartas
	dealDeck()
	#Se inician los temporizadores
	setUpTimers()
	#Se inicia la barra de estado
	setUpHUD()

func _enter_tree():
	# Establecemos la musica del minijuego.
	MusicController.set_music()

func _exit_tree():
	# Si salimos del minijuego, lo reseteamos
	resetGame()

func setUpTimers():
	#Se conectan y se inicializan los temporizadores. Se añaden a la escena principal
	var _ret = $FlipTimer.connect("timeout", self , "turnOverCards")
	# $FlipTimer.set_one_shot(true)
	_ret = $MatchTimer.connect("timeout", self , "matchCardsAndScore")
	# $MatchTimer.set_one_shot(true)
	_ret = $SecondsTimer.connect("timeout", self , "countSeconds")
	$SecondsTimer.start()

func countSeconds():
	#Se añade un segundo
	seconds += 1
	$HUDFM.set_time(seconds)

#Se reinicia el juego
func resetGame():
	#Se liberan los recursos de la ya existente baraja
	for c in range(deck.size()):
		deck[c].queue_free()
	deck.clear()
	#Se establecen todos los valores de la barra de estado a 0
	score = 0
	seconds = 0
	moves = 0
	#Se reinician los temporizadores
	# No es necesario pues con conectar
	# las senyales la primera vez basta.
	#setUpTimers()
	#Se reinicia la barra de estado
	setUpHUD()
	#Se rellena la baraja
	fillDeck()
	#Se barajan las cartas
	dealDeck()

#Se establecen los valores de la barra de estado
func setUpHUD():
	#scoreLabel = Game.get_node('HUD/Panel/Sections/SectionScore/Score')
	#timerLabel = Game.get_node('HUD/Panel/Sections/SectionTimer/Seconds')
	#movesLabel = Game.get_node('HUD/Panel/Sections/SectionMoves/Moves')
	#scoreLabel.text = str(score)
	#timerLabel.text = str(seconds)
	#movesLabel.text = str(moves)
	$HUDFM.set_score(score)
	$HUDFM.set_time(seconds)
	$HUDFM.set_moves(moves)
	#Obtenemos el botón de reset
	#resetButton = Game.get_node('HUD/Panel/Sections/SectionButtons/ButtonReset')
	#Se conecta con la función correspondiente si es pulsado
	#resetButton.connect("pressed", resetGame)

func fillDeck():
	#s = primer valor de la carta (1: las graficas, 2: las funciones)
	var s = 1
	#v = segundo valor (las diferentes graficas/funciones que hay)
	var v = 1
	while s < 3:
		v = 1
		while v < 6:
			#Se van añadiendo todas las cartas
			deck.append(Card.new(s, v))
			v += 1
		s += 1

func dealDeck():
	#Se barajan las cartas
	deck.shuffle()
	var c = 0
	while c < deck.size():
		#Se añaden a la pantalla de juego
		var grid_node = $grid
		if grid_node:
			grid_node.add_child(deck[c])
		c += 1

func chooseCard(c):
	#Se elige la primera carta y se gira
	if card1 == null:
		card1 = c
		card1.flip()
		card1.set_disabled(true)
	#Se elige la segunda carta y se gira
	elif card2 == null:
		card2 = c
		card2.flip()
		card2.set_disabled(true)
		#Se añade un movimiento
		moves += 1
		$HUDFM.set_moves(moves)
		#Se comprueban si ambas cartas son pareja
		checkCards()

func checkCards():
	#Se comprueba si las cartas son pareja y se establecen los temporizadores corespondientes para girarlas de nuevo o inhabilitarlas
	if card1.value == card2.value:
		$MatchTimer.start(0.6)
	else:
		$FlipTimer.start(1.2)

func turnOverCards():
	#Gira ambas cartas
	card1.flip()
	card2.flip()
	#Se establecen a null los valores de las variables auxiliares
	card1.set_disabled(false)
	card2.set_disabled(false)
	card1 = null
	card2 = null

func matchCardsAndScore():
	$PairFound.play()
	#Se aumenta en 1 el valor de la puntuación
	score += 1
	$HUDFM.set_score(score)
	#Se cambia el color de las cartas para "inhabilitarlas"
	card1.set_modulate(Color(0.6, 0.6, 0.6, 0.5))
	card2.set_modulate(Color(0.6, 0.6, 0.6, 0.5))
	#Se establecen a null los valores de las variables auxiliares
	card1 = null
	card2 = null
	#Si se alcanza el objetivo, se instancia el pop up final y se gana el juego
	if score == goal:
		Global.start_session("functionmemory")
		# Establecemos las variables globales
		# para que los datos puedan pasarse a
		# la pantalla final del minijuego.
		Global.total_memory_time = seconds
		Global.memory_score = score
		Global.flipped_pairs_number = moves
		Global.end_session()
		var _ret = get_tree().change_scene("res://minigames/functionmemory/ui/EndScreenFM.tscn")
		#var winScreen = popUp.instantiate()
		#Game.add_child(winScreen)
		#winScreen.win()

func playFlipSound():
	$FlipCard.play()
