extends ImGui

var frame_number: int = 0
var cheats_enabled := false

var resource_options: Array[String] = ["Wisdom", "Gear", "Mana"]
var resource_selected := 0

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
		_game_tab()
		
	if cheats_enabled:
		if tab("Game - advanced"):
			_advanced_tab()
	
	if tab("Other"):
		label("Some junk here")
	
	end_tabs()

func _game_tab() -> void:
	begin_vbox()
	label("Imgui in Godot!")
	
	progress_bar(frame_number % 1000, 1000)
	
	if button("Press me"):
		timer.start(3)
	
	if !timer.is_stopped() and timer.time_left > 0:
		label("This label wil disappear in  %.2fs" % timer.time_left)
	
	cheats_enabled = toggle(cheats_enabled, "Cheats enabled")
	end_vbox()

func _advanced_tab() -> void:
	begin_vbox()
	begin_grid(2)
	label("Frame number:")
	label(str(frame_number))
	label("OS Name:")
	label(OS.get_name())
	
	label("Resources:")
	resource_selected = dropdown(resource_selected, resource_options)
	end_grid()
	
	label("+100 %s" % resource_options[resource_selected])
	end_vbox()
