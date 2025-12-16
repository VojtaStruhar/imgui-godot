extends ImGui

var frame_number: int = 0
var show_advanced := true

var resource_options: Array[String] = ["Wisdom", "Gear", "Mana"]
var resource_selected := 0
var server: String = "https://server.vojtechstruhar.com"
var probabilities: Dictionary[String, float] = {
	"common": 0.9,
	"rare": 0.5,
	"epic": 0.2,
	"legendary": 0.05,
}

@onready var timer := Timer.new()



func _ready() -> void:
	super()
	timer.one_shot = true
	get_parent().add_child.call_deferred(timer)
	

func _process(delta: float) -> void:
	super(delta)
	frame_number += 1
	begin_tabs()
	begin_margin(10)
	
	if tab("Game"):
		_game_tab()
		
	if show_advanced:
		if tab("Game - advanced"):
			_advanced_tab()
	
	if tab("Other"):
		label("Some junk here")
	
	end_margin()
	end_tabs()

func _game_tab() -> void:
	begin_vbox()
	
	label("Imgui in Godot!")
	
	begin_tabs()
	begin_margin(10)
	
	
	if tab("Basic"):
		begin_vbox()
		progress_bar(frame_number % 1000, 1000)
		
		if button("Press me"):
			timer.start(3)
		
		if !timer.is_stopped() and timer.time_left > 0:
			label("This label wil disappear in  %.2fs" % timer.time_left)
		
		show_advanced = toggle(show_advanced, "Show Advanced")
		end_vbox()
	
	if tab("Configuration"):
		begin_vbox()
		begin_grid(2)
		label("Server address:")
		server = textfield(server)
		label("One more:")
		server = textfield(server)
		end_grid()
		
		separator_h()
		
		begin_panel()
		begin_margin(10)
		begin_vbox()
		label("Drop chances")
		var total: float = probabilities.values().reduce(func(a: float, b: float): return a + b, 0.0)
		begin_grid(3)
		for key in probabilities:
			label(key.capitalize())
			probabilities[key] = slider_h(probabilities[key], 0.0, 1.0, 0.01)
			label("%.2f%%" % (100.0 * probabilities[key] / total))
		end_grid()
		end_vbox()
		end_margin()
		end_panel()
		end_vbox()
	
	end_margin()
	end_tabs()
	
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
	resource_selected = spinbox(resource_selected, 0, resource_options.size() - 1)
	end_vbox()
