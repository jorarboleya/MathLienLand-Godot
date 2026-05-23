# ----------------- Codigo Base obtenido de: -----------------
# 		https://github.com/CVelasco2/Math-Endless-Runner
extends Control

#Enumeracion de los tipos de operaciones
enum Operators {
	ADD, 
	SUBTRACT, 
	MULTIPLY
}

#Se crean las variables necesarias
var operand1
var operand2
var operator
var correct
var answer
var random = RandomNumberGenerator.new()

# Adaptive difficulty parameters (set by Level0MER before the first question)
var adaptive_max_operand = 99
var adaptive_allowed_operators = [Operators.ADD, Operators.SUBTRACT, Operators.MULTIPLY]
var adaptive_difficulty = 5

#Se crean variables que almacenen los nodos de la escena
onready var go = $MarginContainer/Panel/GoButton
onready var exit = $MarginContainer/Panel/ExitButton
onready var check = $MarginContainer/Panel/CheckButton

onready var operand_one = $MarginContainer/Panel/Operand
onready var operand_two = $MarginContainer/Panel/Operand2
onready var label_operator = $MarginContainer/Panel/Operator
onready var message = $MarginContainer/Panel/Message

signal continuegame
signal gameover

onready var answer_line = $MarginContainer/Panel/Answer

# Called when the node enters the scene tree for the first time.
func _ready():
	#Inicializamos el randomizador 
	random.randomize()
	
	#Se llama a la funcion que realiza la pregunta
	question()

#Se establece el comportamiento si se presiona el boton Enter
func _physics_process(_delta):
	if Input.is_action_just_released("ui_accept") and visible:
		if check.visible: 
			self._on_check_button_pressed()
			return
		if go.visible:
			self._on_go_button_pressed()
			return

#Se crea una nueva operacion
func question():
	if not answer_line.editable:
		reset_question()

	# Use AI-generated questions only when they match the current adaptive level.
	var ai_question = _get_adaptive_ai_question()
	if ai_question != null:
		_apply_ai_question(ai_question)
		return

	operand1 = operand()
	operator = get_operator()
	match operator:
		#Suma de numeros enteros
		Operators.ADD:
			operator = "+"
			operand2 = operand()
			correct = operand1 + operand2
		#Resta de numeros enteros
		Operators.SUBTRACT:
			operator = "-"
			operand2 = operand()
			if operand1 < operand2:
				var aux = operand1
				operand1 = operand2
				operand2 = aux
			correct = operand1 - operand2
		#Multiplicación de numeros enteros
		Operators.MULTIPLY:
			operator = "x"
			operand2 = multiplicationOperand()
			correct = operand1 * operand2
	operand_one.text = str(operand1)
	operand_two.text = str(operand2)
	label_operator.text = operator
	answer_line.clear()

#Se genera un operando aleatorio
func operand():
	return random.randi_range(10, adaptive_max_operand)

#Se genera un operando aleatorio para multiplicacion
func multiplicationOperand():
	return random.randi_range(0, 9)

#Se genera un operador
func get_operator():
	return adaptive_allowed_operators[random.randi_range(0, adaptive_allowed_operators.size() - 1)]

func _get_adaptive_ai_question():
	if Global.er_questions.size() == 0:
		return null
	for _i in range(Global.er_questions.size()):
		var idx = Global.er_question_index % Global.er_questions.size()
		Global.er_question_index += 1
		var q = Global.er_questions[idx]
		if _is_ai_question_allowed(q):
			return q
	return null

func _apply_ai_question(q):
	operand1 = int(str(q["operand1"]))
	operand2 = int(str(q["operand2"]))
	operator = str(q["operator"])
	correct = int(str(q["answer"]))
	operand_one.text = str(operand1)
	operand_two.text = str(operand2)
	# Display "*" as "x" for readability
	label_operator.text = "x" if operator == "*" else operator
	answer_line.clear()

func _is_ai_question_allowed(q):
	if not q.has("operand1") or not q.has("operand2") or not q.has("operator") or not q.has("answer"):
		return false
	var op = _operator_enum_from_string(str(q["operator"]))
	if op == null or not adaptive_allowed_operators.has(op):
		return false
	var a = int(str(q["operand1"]))
	var b = int(str(q["operand2"]))
	var ans = int(str(q["answer"]))
	if a < 10 or a > adaptive_max_operand:
		return false
	match op:
		Operators.ADD:
			return b >= 10 and b <= adaptive_max_operand and a + b == ans
		Operators.SUBTRACT:
			return b >= 10 and b <= adaptive_max_operand and a >= b and a - b == ans
		Operators.MULTIPLY:
			return b >= 0 and b <= 9 and a * b == ans
	return false

func _operator_enum_from_string(op):
	match op:
		"+":
			return Operators.ADD
		"-":
			return Operators.SUBTRACT
		"*", "x", "X":
			return Operators.MULTIPLY
	return null

#Se resetea el juego al pulsar el boton Exit
func _on_exit_button_pressed():
	#EndlessRunnerManager.resetGame()
	queue_free()
	emit_signal("gameover")

#Se continua el juego si se pulsa sobre el boton Go
func _on_go_button_pressed():
	#EndlessRunnerManager.continueGame()
	#queue_free()
	#pass
	question()
	go.visible = false
	check.visible=true
	emit_signal("continuegame")

#Se comprueba la respuesta si se presiona sobre el boton Check
func _on_check_button_pressed():
	#Se obtiene la respuesta introducida
	answer = answer_line.text
	
	#Se comprueba que la respuesta no esta vacia
	if answer == "":
		return
	
	#Se comprueba que la respuesta es un numero
	for character in answer:
		if character in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]:
			pass
		else:
			message.text = "I'm sorry, the answer\nmust be a number"
			answer_line.clear()
			return
	
	#Se comprueba si la respuesta es incorrecta
	if answer != str(correct):
		message.text = "I'm sorry, the answer\nis"
		answer_line.text = str(correct)
		answer_line.editable = false
		# Ayudamos visualmente al jugador mostrando un fondo rojo
		# para resaltar el fallo.
		var new_stylebox_readonly = answer_line.get_stylebox("read_only").duplicate()
		new_stylebox_readonly.bg_color =  Color(0.992188, 0.264428, 0.011627)
		answer_line.add_stylebox_override("read_only", new_stylebox_readonly)
		
		#check.disabled = true
		check.visible = false
		return
	
	#La respuesta es correcta
	message.text = "The answer is correct!"
	#Signals.emit_signal("questioncorrect")
	$Correct.play()
	answer_line.editable = false
	# Ayudamos visualmente al jugador mostrando un fondo verde
	# para resaltar el acierto.
	var new_stylebox_readonly = answer_line.get_stylebox("read_only").duplicate()
	new_stylebox_readonly.bg_color =  Color(0.12549, 0.87451, 0)
	answer_line.add_stylebox_override("read_only", new_stylebox_readonly)

	#check.disabled = true
	check.visible = false
	#go.disabled = false
	go.visible = true

# Se resetea el pop up de la operacion para que
# pueda contestarse correctamente la pregunta.
func reset_question():
	# Hacemos la caja de respuesta transparente
	var new_stylebox_readonly = answer_line.get_stylebox("read_only").duplicate()
	new_stylebox_readonly.bg_color =  Color(0.6, 0.6, 0.6, 0)
	answer_line.add_stylebox_override("read_only", new_stylebox_readonly)
	# Mostramos el texto inicial
	message.text = "ANSWER CORRECTLY \nTO CONTINUE!"
	# Permitimos las respuestas de nuevo
	answer_line.editable = true
