extends Sprite2D

func _on_timer_off_timeout() -> void:
	hide()
	$TimerOn.start()

func _on_timer_on_timeout() -> void:
	show()
	$TimerOff.start()
