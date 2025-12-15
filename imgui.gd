class_name ImGui
extends Control

var __parent: Control = self
var __inputs: Dictionary[NodePath, Dictionary] = { }
## Call depth
var __cursor: Array[int] = [0]

func _ready() -> void:
	for child in get_children():
		push_warning("IMGUI - removing initial children")
		remove_child(child)
		child.queue_free()

func _process(_delta: float) -> void:
	if get_child_count() != 0:
		end_vbox()

	assert(__cursor.size() == 1)
	__cursor[0] = 0

	begin_vbox()


func begin_tabs() -> void:
	# TODO: Push zero spacing override here
	begin_vbox()
	var current := _get_current_node()
	if current is not TabBar:
		_destroy_rest_of_this_layout_level()
		var tb := TabBar.new()
		__parent.add_child(tb)
	
	__cursor[__cursor.size() - 1] += 1 # Next node
	
	begin_panel()
	__parent.set_meta(&"_imgui_tab_bar", true)
	__parent.set_meta(&"_imgui_tab_visited", -1)


func tab(tab_name: String) -> bool:
	var tab_container := __parent
	while tab_container.get_class() != &"PanelContainer" or !tab_container.has_meta(&"_imgui_tab_bar"):
		tab_container = tab_container.get_parent()
		assert(tab_container != get_tree().root, "Unclosed `begin_tabs`")
	
	var tab_bar: TabBar = tab_container.get_parent().get_child(0)
	assert(tab_bar)
	var index: int = tab_container.get_meta(&"_imgui_tab_visited")
	index += 1
	if tab_bar.tab_count <= index:
		tab_bar.add_tab(tab_name)
	else:
		if not tab_bar.get_tab_title(index) == tab_name:
			while tab_bar.tab_count >= index:
				tab_bar.remove_tab(-1)
			tab_bar.add_tab(tab_name)
	
	tab_container.set_meta(&"_imgui_tab_visited", index)
	
	return tab_bar.get_tab_title(tab_bar.current_tab) == tab_name


func end_tabs() -> void:
	if __parent.get_child_count() != __cursor[__cursor.size() - 1]:
		_destroy_rest_of_this_layout_level()
	assert(__parent is PanelContainer)
	end_panel()
	if __parent.get_child_count() != (__cursor[__cursor.size() - 1] + 1): # +1 for the TabBar?
		_destroy_rest_of_this_layout_level()
	assert(__parent is VBoxContainer)
	end_vbox()


func label(text: String) -> void:
	var current := _get_current_node()
	if current is not Label:
		_destroy_rest_of_this_layout_level()
		var l := Label.new()
		l.name = str(__cursor).validate_node_name()
		l.text = text
		__parent.add_child(l)
		current = l

	current.text = text
	__cursor[__cursor.size() - 1] += 1 # Next node


func separator_h() -> void:
	var current := _get_current_node()
	if current is not HSeparator:
		_destroy_rest_of_this_layout_level()
		var hs := HSeparator.new()
		hs.name = str(__cursor).validate_node_name()
		__parent.add_child(hs)
		current = hs

	__cursor[__cursor.size() - 1] += 1 # Next node


func separator_v() -> void:
	var current := _get_current_node()
	if current is not HSeparator:
		_destroy_rest_of_this_layout_level()
		var hs := HSeparator.new()
		hs.name = str(__cursor).validate_node_name()
		__parent.add_child(hs)
		current = hs

	__cursor[__cursor.size() - 1] += 1 # Next node


func button(text: String) -> bool:
	var current := _get_current_node()
	if current is not Button:
		_destroy_rest_of_this_layout_level()
		var b := Button.new()
		b.name = str(__cursor).validate_node_name()
		b.pressed.connect(_register_button_press.bind(b))
		__parent.add_child(b)
		current = b

	current.text = text
	var np := self.get_path_to(current)

	__cursor[__cursor.size() - 1] += 1 # Next node
	return __inputs.erase(np)


func begin_vbox() -> void:
	var c := _get_current_node()
	if c is not VBoxContainer:
		_destroy_rest_of_this_layout_level()
		var vbox := VBoxContainer.new()
		vbox.name = str(__cursor).validate_node_name()
		__parent.add_child(vbox)
		c = vbox

	__parent = c
	__cursor.append(0)


func end_vbox() -> void:
	assert(__parent is VBoxContainer)
	if __parent.get_child_count() != __cursor[__cursor.size() - 1]:
		_destroy_rest_of_this_layout_level()

	__parent = __parent.get_parent()
	__cursor.pop_back()
	__cursor[__cursor.size() - 1] += 1


func begin_hbox() -> void:
	var c := _get_current_node()
	if c is not HBoxContainer:
		_destroy_rest_of_this_layout_level()
		var vbox := HBoxContainer.new()
		vbox.name = str(__cursor).validate_node_name()
		__parent.add_child(vbox)
		c = vbox

	__parent = c
	__cursor.append(0)


func end_hbox() -> void:
	assert(__parent is HBoxContainer)
	if __parent.get_child_count() != __cursor[__cursor.size() - 1]:
		_destroy_rest_of_this_layout_level()

	__parent = __parent.get_parent()
	__cursor.pop_back()
	__cursor[__cursor.size() - 1] += 1


func begin_panel() -> void:
	var c := _get_current_node()
	if c is not PanelContainer:
		_destroy_rest_of_this_layout_level()
		var grid := PanelContainer.new()
		grid.name = str(__cursor).validate_node_name()
		__parent.add_child(grid)
		c = grid

	__parent = c
	__cursor.append(0)


func end_panel() -> void:
	assert(__parent is PanelContainer)
	if __parent.get_child_count() != __cursor[__cursor.size() - 1]:
		_destroy_rest_of_this_layout_level()

	__parent = __parent.get_parent()
	__cursor.pop_back()
	__cursor[__cursor.size() - 1] += 1


func begin_grid(columns: int) -> void:
	var c := _get_current_node()
	if c is not GridContainer:
		_destroy_rest_of_this_layout_level()
		var grid := GridContainer.new()
		grid.name = str(__cursor).validate_node_name()
		__parent.add_child(grid)
		c = grid

	c.columns = columns
	__parent = c
	__cursor.append(0)


func end_grid() -> void:
	assert(__parent is GridContainer)
	if __parent.get_child_count() != __cursor[__cursor.size() - 1]:
		_destroy_rest_of_this_layout_level()

	__parent = __parent.get_parent()
	__cursor.pop_back()
	__cursor[__cursor.size() - 1] += 1


func _register_button_press(b: Button) -> void:
	var nodepath := self.get_path_to(b)
	__inputs[nodepath] = { }


func _get_current_node() -> Control:
	var c: Control = self
	for i in __cursor:
		if c.get_child_count() > i:
			c = c.get_child(i)
		else:
			return null
	return c


func _destroy_rest_of_this_layout_level() -> void:
	if __cursor.is_empty():
		# This only happens with the very first container?
		return

	var incorrect_one := _get_current_node()
	if incorrect_one == null:
		# The node isn't created yet
		return

	var p := incorrect_one.get_parent()
	while p.get_child_count() > __cursor[__cursor.size() - 1]:
		var child := p.get_child(-1)
		p.remove_child(child)
		child.queue_free()
