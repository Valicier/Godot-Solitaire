extends Sprite2D

var seen = 0
var card_full = ""
var top_draw = 0

func _process(delta: float) -> void:
	if seen == 1:
		$Back.hide()
	else:
		$Back.show()
	
	if top_draw == 1:
		top_level = true
