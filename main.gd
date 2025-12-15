extends ImGui

var frame_number: int = 0


func _ready() -> void:
	super()
	

func _process(delta: float) -> void:
	super(delta)
	frame_number += 1
	begin_tabs()
	
	if tab("Game"):
		begin_vbox()
		label("Imgui in Godot!")
		
		separator_h()
		begin_hbox()
		
		if button("Press me"):
			print("Action 1!")
			label("Press!")
		
		if button("Press me"):
			print("Deleting your hard drive rn")
			
		end_hbox()
		end_vbox()
		
	
	if tab("Game - advanced"):
		begin_grid(2)
		label("Frame number:")
		label(str(frame_number))
		label("OS Name:")
		label(OS.get_name())
		end_grid()
	
	if tab("Other"):
		label("Some junk here")
	
	end_tabs()
