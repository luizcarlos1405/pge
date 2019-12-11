extends Label


"""
	Show a message on the editor on `show_messsage(message)` method call
"""


func _ready():
	$Timer.connect("timeout", self, "_on_Timer_timeout")
	connect("resized", self, "_on_resized")
	pass


func show_message(message: String) -> void:
	text = message
	$AnimationPlayer.play("show_message")
	$Timer.start()


func _on_resized() -> void:
	rect_pivot_offset = rect_size / 2


func _on_Timer_timeout() -> void:
	$AnimationPlayer.play_backwards("show_message")