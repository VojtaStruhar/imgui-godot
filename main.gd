extends Control


var frame_number: int = 0
var show_advanced := true

var resource_options: Array[String] = ["Wisdom", "Gear", "Mana"]
var resource_selected := 0
var server: String = "https://server.vojtechstruhar.com"
var music_volume: float = 80
var probabilities: Dictionary[String, float] = {
	"common": 0.9,
	"rare": 0.5,
	"epic": 0.2,
	"legendary": 0.05,
}

var user_name: String = ""
var user_bio: String = ""
var user_logged_in: bool = true

@onready var timer := Timer.new()
@onready var g: ImGui = $Imgui



func _ready() -> void:
	timer.one_shot = true
	get_parent().add_child.call_deferred(timer)
	

func _process(_delta: float) -> void:
	frame_number += 1
	g.begin_tabs()
	g.begin_margin(10)
	
	if g.tab("Game"):
		_game_tab()
		
	if show_advanced:
		if g.tab("Game - advanced"):
			_advanced_tab()
	
	if g.tab("Other"):
		g.begin_vbox()
		g.label("Some junk here")
		g.begin_hbox()
		g.label("Music volume")
		for i in range(4):
			g.next_min_size(50, 150)
			g.begin_vbox()
			music_volume = g.slider_v(music_volume, 40, 120)
			g.label("%ddb" % music_volume)
			g.end_vbox()
			
		
		g.end_hbox()
		g.begin_grid(2)
		for i in range(2):
			g.label("Username:")
			user_name = g.textfield(user_name)
		g.end_grid()
		
		user_bio = g.textedit(user_bio)
		g.label(user_bio)
		
		g.end_vbox()
		
	
	g.end_margin()
	g.end_tabs()

func _game_tab() -> void:
	g.begin_vbox()
	
	g.label("Imgui in Godot!", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER)
	
	g.begin_tabs()
	g.begin_margin(10)
	
	if g.tab("Basic"):
		g.begin_vbox()
		g.progress_bar(frame_number % 1000, 1000)
		
		if g.button("Press me"):
			timer.start(3)
		
		if !timer.is_stopped() and timer.time_left > 0:
			g.label("This label wil disappear in  %.2fs" % timer.time_left)
		
		show_advanced = g.toggle(show_advanced, "Show Advanced")
		show_advanced = g.checkbox(show_advanced, "Show Advanced")
		g.end_vbox()
	
	if g.tab("Configuration"):
		g.begin_vbox()
		
		g.separator()
		
		g.begin_panel()
		g.begin_margin(10)
		g.begin_vbox()
		g.label("Drop chances")
		var total: float = probabilities.values().reduce(func(a: float, b: float): return a + b, 0.0)
		g.begin_grid(3)
		for key in probabilities:
			g.label(key.capitalize())
			probabilities[key] = g.slider_h(probabilities[key], 0.0, 1.0, 0.01)
			g.label("%.2f%%" % (100.0 * probabilities[key] / total))
		g.end_grid()
		g.end_vbox()
		g.end_margin()
		g.end_panel()
		g.end_vbox()
	
	if g.tab("Online"):
		g.begin_vbox()
		
		g.begin_grid(2)
		g.label("Connected to server:")
		g.label("Yes" if server else "No")
		g.label("User logged in:")
		g.label("Yes" if user_logged_in else "No")
		g.end_grid()
		
		if g.button("Disconnect from server", server != ""):
			user_logged_in = false
			server = ""
		if g.button("Log out", server and user_logged_in):
			user_logged_in = false
		if g.button("Reconnect", server != "" and user_logged_in == false):
			user_logged_in = true
		
		g.separator()
		
		g.begin_grid(2)
		g.label("Server address:")
		server = g.textfield(server)
		g.end_grid()
		if server == "":
			g.push_variation(&"Label_Error")
			g.label("Server address must not be empty!")
			g.pop_variation()
		g.end_vbox()
		
	
	g.end_margin()
	g.end_tabs()
	
	g.end_vbox()

func _advanced_tab() -> void:
	g.begin_vbox()
	g.begin_grid(2)
	g.label("Frame number:")
	g.label(str(frame_number))
	g.label("OS Name:")
	g.label(OS.get_name())
	
	g.label("Resources:")
	resource_selected = g.dropdown(resource_selected, resource_options)
	g.end_grid()
	
	g.label("+100 %s" % resource_options[resource_selected])
	resource_selected = g.spinbox(resource_selected, 0, resource_options.size() - 1)
	g.end_vbox()
