class_name ImGui extends Node

func _process(_delta: float) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func label(text: String) -> void:
	var l := Label.new()
	l.text = text
	add_child(l)
	
