extends ImGui

var frame_number: int = 0

func _process(delta: float) -> void:
	super(delta)
	frame_number += 1
	label("Imgui in Godot!")
	
	if button("Press me"):
		print("Action 1!")
		label("Press!")
	
	if button("Press me"):
		print("Deleting your hard drive rn")
		
	
	begin_grid(2)
	label("Frame number:")
	label(str(frame_number))
	label("OS Name:")
	label(OS.get_name())
	end_grid()
