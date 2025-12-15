extends ImGui

var frame_number: int = 0

func _process(delta: float) -> void:
	super(delta)
	frame_number += 1
	label("Imgui in Godot!")
	label("Frame: " + str(frame_number))
	
	if button("Press me"):
		print("Action 1!")
		label("Press!")
	
	if button("Press me"):
		print("Deleting your hard drive rn")
