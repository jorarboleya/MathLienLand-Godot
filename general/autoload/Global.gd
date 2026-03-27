extends Node

# Signal emitted when both question sets have been fetched (or fallen back)
signal all_questions_loaded

# True once all fetches have completed
var questions_loaded = false
var _labyrinth_loaded = false
var _race_loaded = false
var _dh_loaded = false
var _dsm_loaded = false
var _er_loaded = false

# Variable que contiene las preguntas posibles
var labyrinth_questions = []
# Variable que indica que cuestion debe ser propuesta
var current_labyrinth_question = 0
# Maximo de preguntas disponibles
var num_labyrinth_questions = 5
# Tiempo total que el usuario ha jugado.
var total_labyrinth_time = 0

# Variable que contiene las preguntas posibles
# para el juego de carreras
var race_questions = []
# Variable que indica que cuestion debe ser propuesta
# en la carrera
var current_race_question = 0
# Maximo de preguntas disponibles en la carrera
var num_race_questions = 8
# Tiempo total que el usuario ha jugado la carrera.
var total_race_time = 0
# Variable que guarda la posicion final del jugador en
# la carrera.
var final_position = -1

# Variables del juego Dividing Hills
var total_hills_time = 0
var ncorrect_hills = 0
var total_hills_questions = 0

# Variables del juego Decimal System Meteors
var total_meteors_time = 0
var meteor_score = 0

# -------------------- Variables necesarias en FunctionMemory. -----------
var flipped_pairs_number = 0
var total_memory_time = 0
var memory_score = 0
# -------------------- FIN -----------------------------------------------

# -------------------- Variables necesarias en MathEndlessRunner. --------
var ncorrect_runner = 0 # Add
var total_runner_time = 0 # Add
var runner_score = 0
# -------------------- FIN -----------------------------------------------

# AI-generated question arrays (Phase 5)
# Empty by default; filled from server. Minigames fall back to procedural if empty.
var dh_questions = []   # Dividing Hills
var dsm_questions = []  # Decimal System Meteors
var er_questions = []   # Math Endless Runner

# Consumption indices (cycle through AI questions)
var dh_question_index = 0
var dsm_question_index = 0
var er_question_index = 0

# Fetches questions from the server; falls back to hardcoded arrays if the
# request fails (e.g. server not running during development in the editor).
func _ready():
	_fetch_questions()

func _fetch_questions():
	var base_url = "http://localhost:8080"
	if OS.has_feature("JavaScript"):
		base_url = JavaScript.eval("window.location.origin")

	var http_lab = HTTPRequest.new()
	add_child(http_lab)
	var _r1 = http_lab.connect("request_completed", self, "_on_labyrinth_response", [http_lab])
	http_lab.request(base_url + "/api/levels/labyrinth")

	var http_race = HTTPRequest.new()
	add_child(http_race)
	var _r2 = http_race.connect("request_completed", self, "_on_race_response", [http_race])
	http_race.request(base_url + "/api/levels/fraction-race")

	var http_dh = HTTPRequest.new()
	add_child(http_dh)
	var _r3 = http_dh.connect("request_completed", self, "_on_dh_response", [http_dh])
	http_dh.request(base_url + "/api/levels/dividing-hills")

	var http_dsm = HTTPRequest.new()
	add_child(http_dsm)
	var _r4 = http_dsm.connect("request_completed", self, "_on_dsm_response", [http_dsm])
	http_dsm.request(base_url + "/api/levels/decimal-meteors")

	var http_er = HTTPRequest.new()
	add_child(http_er)
	var _r5 = http_er.connect("request_completed", self, "_on_er_response", [http_er])
	http_er.request(base_url + "/api/levels/endless-runner")

func _on_labyrinth_response(result, response_code, _headers, body, http_node):
	http_node.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var parsed = JSON.parse(body.get_string_from_utf8())
		if parsed.error == OK:
			labyrinth_questions = parsed.result["questions"]
			num_labyrinth_questions = labyrinth_questions.size()
		else:
			fill_labyrinth_questions()
	else:
		fill_labyrinth_questions()
	_labyrinth_loaded = true
	_check_questions_ready()

func _on_race_response(result, response_code, _headers, body, http_node):
	http_node.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var parsed = JSON.parse(body.get_string_from_utf8())
		if parsed.error == OK:
			race_questions = parsed.result["questions"]
			num_race_questions = race_questions.size()
		else:
			fill_race_questions()
	else:
		fill_race_questions()
	_race_loaded = true
	_check_questions_ready()

func _on_dh_response(result, response_code, _headers, body, http_node):
	http_node.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var parsed = JSON.parse(body.get_string_from_utf8())
		if parsed.error == OK and parsed.result.has("questions"):
			dh_questions = parsed.result["questions"]
	_dh_loaded = true
	_check_questions_ready()

func _on_dsm_response(result, response_code, _headers, body, http_node):
	http_node.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var parsed = JSON.parse(body.get_string_from_utf8())
		if parsed.error == OK and parsed.result.has("questions"):
			dsm_questions = parsed.result["questions"]
	_dsm_loaded = true
	_check_questions_ready()

func _on_er_response(result, response_code, _headers, body, http_node):
	http_node.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var parsed = JSON.parse(body.get_string_from_utf8())
		if parsed.error == OK and parsed.result.has("questions"):
			er_questions = parsed.result["questions"]
	_er_loaded = true
	_check_questions_ready()

func _check_questions_ready():
	if _labyrinth_loaded and _race_loaded and _dh_loaded and _dsm_loaded and _er_loaded:
		questions_loaded = true
		emit_signal("all_questions_loaded")

func fill_labyrinth_questions():
	var question1 = {}
	
	question1["question"] = "If 10cm of a map are 750m in reality, how many meters\n are 13cm in the map?"
	question1["answerA"] = ["1000m", false]
	question1["answerB"] = ["975m", true]
	question1["answerC"] = ["5000m", false]
	question1["answerD"] = ["13m", false]
	question1["explanation"] = ["res://assets/lab_explanationcards/0.png"]
	
	var question2 = {}
	
	question2["question"] = "If 8 workers can build a house in 20 days, how many\n days are they going to need with 2 additional workers?"
	question2["answerA"] = ["16 days", true]
	question2["answerB"] = ["10 days", false]
	question2["answerC"] = ["1 day", false]
	question2["answerD"] = ["100 days", false]
	question2["explanation"] = ["res://assets/lab_explanationcards/1.png"]
	
	var question3 = {}
	
	question3["question"] = "If we need 3 mathaliens to defeat 6 slimes, how many\n mathaliens do we need to defeat 12 slimes?"
	question3["answerA"] = ["9", false]
	question3["answerB"] = ["4", false]
	question3["answerC"] = ["6", true]
	question3["answerD"] = ["13", false]
	question3["explanation"] = ["res://assets/lab_explanationcards/2.png"]
	
	var question4 = {}
	
	question4["question"] = "If 6 people can stay in a hotel 12 days for 792$,\n how much is going to be paid for 15 people during 8 days?"
	question4["answerA"] = ["1400$", false]
	question4["answerB"] = ["0$", false]
	question4["answerC"] = ["1000$", false]
	question4["answerD"] = ["1320$", true]
	question4["explanation"] = ["res://assets/lab_explanationcards/3.png"]
	
	var question5 = {}
	
	question5["question"] = "If we need 20 nurses to take care of 200 patients\n in 5 days, how many nurses do we need to take care of\n 500 patients in 10 days?"
	question5["answerA"] = ["25 nurses", true]
	question5["answerB"] = ["20 nurses", false]
	question5["answerC"] = ["50 nurses", false]
	question5["answerD"] = ["15 nurses", false]
	question5["explanation"] = ["res://assets/lab_explanationcards/4.png"]
	
	labyrinth_questions = [question1, question2, question3, question4, question5]
	
func fill_race_questions():
	var question1 = {}
	
	question1["question"] = "res://assets/race_questions/q1.png"
	question1["answerA"] = ["res://assets/race_questions/q1a1.png", true]
	question1["answerB"] = ["res://assets/race_questions/q1a2.png", false]
	question1["answerC"] = ["res://assets/race_questions/q1a3.png", false]
	question1["answerD"] = ["res://assets/race_questions/q1a4.png", false]
	
	var question2 = {}
	
	question2["question"] = "res://assets/race_questions/q2.png"
	question2["answerA"] = ["res://assets/race_questions/q2a1.png", false]
	question2["answerB"] = ["res://assets/race_questions/q2a2.png", false]
	question2["answerC"] = ["res://assets/race_questions/q2a3.png", true]
	question2["answerD"] = ["res://assets/race_questions/q2a4.png", false]
	
	var question3 = {}
	
	question3["question"] = "res://assets/race_questions/q3.png"
	question3["answerA"] = ["res://assets/race_questions/q3a1.png", false]
	question3["answerB"] = ["res://assets/race_questions/q3a2.png", false]
	question3["answerC"] = ["res://assets/race_questions/q3a3.png", false]
	question3["answerD"] = ["res://assets/race_questions/q3a4.png", true]
	
	var question4 = {}
	
	question4["question"] = "res://assets/race_questions/q4.png"
	question4["answerA"] = ["res://assets/race_questions/q4a1.png", true]
	question4["answerB"] = ["res://assets/race_questions/q4a2.png", false]
	question4["answerC"] = ["res://assets/race_questions/q4a3.png", false]
	question4["answerD"] = ["res://assets/race_questions/q4a4.png", false]
	
	var question5 = {}
	
	question5["question"] = "res://assets/race_questions/q5.png"
	question5["answerA"] = ["res://assets/race_questions/q5a1.png", false]
	question5["answerB"] = ["res://assets/race_questions/q5a2.png", false]
	question5["answerC"] = ["res://assets/race_questions/q5a3.png", true]
	question5["answerD"] = ["res://assets/race_questions/q5a4.png", false]
	
	var question6 = {}
	
	question6["question"] = "res://assets/race_questions/q6.png"
	question6["answerA"] = ["res://assets/race_questions/q6a1.png", false]
	question6["answerB"] = ["res://assets/race_questions/q6a2.png", true]
	question6["answerC"] = ["res://assets/race_questions/q6a3.png", false]
	question6["answerD"] = ["res://assets/race_questions/q6a4.png", false]
	
	var question7 = {}
	
	question7["question"] = "res://assets/race_questions/q7.png"
	question7["answerA"] = ["res://assets/race_questions/q7a1.png", false]
	question7["answerB"] = ["res://assets/race_questions/q7a2.png", false]
	question7["answerC"] = ["res://assets/race_questions/q7a3.png", true]
	question7["answerD"] = ["res://assets/race_questions/q7a4.png", false]
	
	var question8 = {}
	
	question8["question"] = "res://assets/race_questions/q8.png"
	question8["answerA"] = ["res://assets/race_questions/q8a1.png", false]
	question8["answerB"] = ["res://assets/race_questions/q8a2.png", false]
	question8["answerC"] = ["res://assets/race_questions/q8a3.png", false]
	question8["answerD"] = ["res://assets/race_questions/q8a4.png", true]
	
	race_questions = [question1, question2, question3, question4, question5, question6, question7, question8]
	
var session_minigame: String = ""
var session_start_time: int = 0
var session_answers: Array = []
var question_start_time: int = 0

func start_session(minigame: String) -> void:
	session_minigame = minigame
	session_start_time = OS.get_unix_time()
	session_answers = []

func start_question_timer() -> void:
	question_start_time = OS.get_unix_time()

func record_answer(question_id: String, correct: bool, difficulty: int) -> void:
	var elapsed_time = OS.get_unix_time() - question_start_time
	session_answers.append({
		"question_id": question_id,
		"correct": correct,
		"time": elapsed_time,
		"difficulty": difficulty
	})

func end_session() -> void:
	var session_time = OS.get_unix_time() - session_start_time
	var data = {
		"minigame": session_minigame,
		"duration": session_time,
		"answers": session_answers
	}
	if OS.has_feature("JavaScript"):
		JavaScript.eval("window.saveFullGame(" + to_json(data) + ")")