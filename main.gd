extends ImGui

var frame_number: int = 0
var cheats_enabled := false

@onready var timer := Timer.new()

func _ready() -> void:
	super()
	timer.one_shot = true
	get_parent().add_child.call_deferred(timer)
	

func _process(delta: float) -> void:
	super(delta)
	frame_number += 1
	begin_tabs()
	
	if tab("Game"):
		begin_vbox()
		label("Imgui in Godot!")
		
		if button("Press me"):
			timer.start(3)
		
		if !timer.is_stopped() and timer.time_left > 0:
			label("This label wil disappear in  %.2fs" % timer.time_left)
		
		cheats_enabled = toggle(cheats_enabled, "Cheats enabled")
		end_vbox()
		
	if cheats_enabled:
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
