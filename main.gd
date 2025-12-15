extends ImGui

var frame_number: int = 0

func _process(delta: float) -> void:
	super(delta)
	frame_number += 1
	label("Imgui in Godot!")
	
	separator_h()
	begin_hbox()
	
	if button("Press me"):
		print("Action 1!")
		label("Press!")
	
	if button("Press me"):
		print("Deleting your hard drive rn")
		
	end_hbox()
	separator_h()
	
	begin_grid(2)
	label("Frame number:")
	label(str(frame_number))
	label("OS Name:")
	label(OS.get_name())
	end_grid()
