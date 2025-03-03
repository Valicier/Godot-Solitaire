extends Node2D

@onready var card_scene = preload("res://card.tscn")
@onready var outline = preload("res://outline.tscn")

var card_y_spacing = 30
var card_x_spacing = 147.15
var card_y_initial = 260
var card_x_initial = 80
var draw_y = 75

var deck = []
var suit_list = ["club", "spade", "heart", "diamond"]
var suit_spacing = 98
var val_list = ["ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king"]
var val_spacing = 73

var rows = {
	"row1": [], "row2": [], "row3": [], "row4": [], "row5": [], "row6": [], "row7": [],
	"draw_pile": [], "discard": [], "ace1": [], "ace2": [], "ace3": [], "ace4": []
}
var rows_shown = {
	"row1": [1], "row2": [1], "row3": [1], "row4": [1], "row5": [1], "row6": [1], "row7": [1],
}

var selected = 0
var selected_vert = 0
var selectable = ["discard", "ace1", "ace2", "ace3", "ace4", "row1", "row2", "row3", "row4", "row5", "row6", "row7"]
var stored_select = []
var new_select = []
var is_selected = 0

var stored_card = []
var selected_card = []
var stored_card_val = 0
var selected_card_val = 0
var stored_card_suit = 0
var selected_card_suit = 0

func _ready() -> void:
	create_deck()
	place_cards()
	deal()
	set_shown_cards()
	draw_face()

func game_update():
	card_pos_update()


## ----- Game Setup Functions ----- ##
func create_deck():
	for suit in suit_list:
		for val in val_list:
			deck.append(suit + val)
	deck.shuffle()

func place_cards():
	for i in range(1,8):
		for j in range(1,i+1):
			var new_card = card_scene.instantiate()
			new_card.position = Vector2(card_x_initial + card_x_spacing*(i-1), card_y_initial + card_y_spacing*(j-1))
			add_child(new_card)
			rows["row" + str(i)].append(new_card)
	
	for i in range(0,24):
		var new_card = card_scene.instantiate()
		new_card.position = Vector2(card_x_initial,draw_y)
		add_child(new_card)
		rows["draw_pile"].append(new_card)

func deal():
	for i in range(1,8):
		for j in range(i,8):
			rows["row" + str(j)][i-1].card_full = deck.pop_front()
	for i in range(0, rows["draw_pile"].size()):
		rows["draw_pile"][i].card_full = deck[i]

func set_shown_cards():
	for i in range(1,8):
		for j in rows_shown["row" + str(i)]:
			for n in range(1, j+1):
				rows["row" + str(i)][-n].seen = 1

func draw_face():
	for key in rows.keys():
		for list in range(0,rows[key].size()):
			var card = (rows[key][list])
			var card_full = card.card_full
			var card_suit
			var card_val
			for i in range(suit_list.size()):
				if card_full.contains(suit_list[i]):
					card_suit = i
			for i in range(val_list.size()):
				if card_full.contains(val_list[i]):
					card_val = i
			card.region_rect = Rect2(1+ card_val*val_spacing, 1+ card_suit*suit_spacing, val_spacing, suit_spacing)


## ----- Mid-Game Card Functions ----- ##
func card_pos_update():
	for key in rows.keys():
		for list in range(0,rows[key].size()):
			var card = (rows[key][list])
			var key_pos = rows.keys().find(key)
			
			if key.contains("draw"):
				card.position = Vector2(card_x_initial,draw_y)
			
			if key.contains("discard"):
				card.position = Vector2(card_x_initial + card_x_spacing,draw_y)
			
			if key.contains("ace"):
				card.position = Vector2(card_x_initial + card_x_spacing*(key_pos-6), draw_y)
				card.z_index = list
			
			if key.contains("row"):
				card.position = Vector2(card_x_initial + card_x_spacing*(key_pos), card_y_initial + card_y_spacing*(list))
				card.z_index = list

func card_check():
	stored_card = rows[stored_select[0]][stored_select[1]].card_full
	if rows[new_select[0]].size() > 0:
		selected_card = rows[new_select[0]][new_select[1]].card_full
	
	if new_select[0].contains("row"):
		if stored_card.contains("club") or stored_card.contains("spade"):
			if selected_card.contains("heart") or selected_card.contains("diamond"):
				for i in range(0, val_list.size()):
					if stored_card.contains(val_list[i]):
						stored_card_val = i
					if selected_card.contains(val_list[i]):
						selected_card_val = i
				if stored_card_val == selected_card_val -1:
					card_move()
		
		if stored_card.contains("heart") or stored_card.contains("diamond"):
			if selected_card.contains("club") or selected_card.contains("spade"):
				for i in range(0, val_list.size()):
					if stored_card.contains(val_list[i]):
						stored_card_val = i
					if selected_card.contains(val_list[i]):
						selected_card_val = i
				if stored_card_val == selected_card_val -1:
					card_move()
	
	if new_select[0].contains("ace"):
		if rows[new_select[0]].size() > 0:
			for i in range(0, suit_list.size()):
				if stored_card.contains(suit_list[i]):
					stored_card_suit = i
				if selected_card.contains(suit_list[i]):
					selected_card_suit = i
			if stored_card_suit == selected_card_suit:
					card_move()
		elif stored_card.contains("ace"):
			card_move()

func card_move():
	for i in range(rows[stored_select[0]].size() -stored_select[1], 0, -1):
		rows[new_select[0]].append(rows[stored_select[0]][-i])
		rows[stored_select[0]].remove_at(rows[stored_select[0]].size() -i)
	if new_select[0].contains("row") and rows[stored_select[0]].size() > 0:
		rows[stored_select[0]][-1].seen = 1
	$"Selected Card".queue_free()
	is_selected = 0


## ----- Input Functions ----- ##
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Move Left"):
		selected -= 1
		if selected < 0:
			selected = 11
		selected_vert = 0
		move_outline()
	if event.is_action_pressed("Move Right"):
		selected = (selected + 1) %12
		selected_vert = 0
		move_outline()
	
	if event.is_action_pressed("Move Up"):
		if selected_vert < rows[ selectable[selected] ].size() -1:
			if rows[selectable[selected]] [rows[selectable[selected]].size() -selected_vert -2].seen == 1:
				selected_vert += 1
		move_outline()
	if event.is_action_pressed("Move Down"):
		if selected_vert > 0:
			selected_vert -= 1
		move_outline()
	
	if event.is_action_pressed("Draw"):
		if rows["draw_pile"].size() > 0:
			rows["discard"].append(rows["draw_pile"][0])
			rows["draw_pile"].pop_front()
			rows["discard"][-1].seen = 1
		else:
			rows["draw_pile"] = rows["discard"].duplicate()
			rows["discard"].clear()
			for list in range(0, rows["draw_pile"].size()):
				var card = (rows["draw_pile"][list])
				card.seen = 0
	
	if event.is_action_pressed("Select"):
		if is_selected == 0:
			var new_outline = outline.instantiate()
			new_outline.position = $Outline.position
			new_outline.name = "Selected Card"
			add_child(new_outline)
			new_outline.get_node("TimerOff").start()
			stored_select = [selectable[selected], rows[selectable[selected]].size() -1 -selected_vert]
			is_selected = 1
		else:
			new_select = [selectable[selected], rows[selectable[selected]].size() -1 -selected_vert]
			card_check()
	
	if event.is_action_pressed("Clear Select"):
		if is_selected == 1:
			$"Selected Card".queue_free()
			is_selected = 0
	
	if event.is_action_pressed("Quit"):
		get_tree().quit()
	
	if event.is_action_pressed("Restart"):
		get_tree().reload_current_scene()
	
	game_update()

func move_outline():
	var row_selected = selectable[selected]
	var row_length = rows[row_selected].size()
	if row_selected.contains("discard"):
		$Outline.position = Vector2(card_x_initial + card_x_spacing, draw_y)
	if row_selected.contains("ace"):
		$Outline.position = Vector2(card_x_initial + card_x_spacing*(selected+2), draw_y)
	if row_selected.contains("row"):
		$Outline.position = Vector2(card_x_initial + card_x_spacing*(selected-5), card_y_initial + card_y_spacing*(row_length -1 -selected_vert))
		if row_length == 0:
			$Outline.position.y = card_y_initial + card_y_spacing*(row_length -selected_vert)
