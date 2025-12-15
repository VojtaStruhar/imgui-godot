class_name ImGui extends Control

var __parent: Control = self

var __inputs: Dictionary[NodePath, Dictionary] = {}
## Call depth
var __cursor: Array[int] = [0]


func _process(_delta: float) -> void:
	if get_child_count() != 0:
		end_vbox()
	
	assert(__cursor.size() == 1)
	__cursor[0] = 0
	
	begin_vbox()

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
	__cursor[__cursor.size()-1] += 1  # Next node

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
	
	__cursor[__cursor.size()-1] += 1  # Next node
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
	if __parent.get_child_count() != __cursor[__cursor.size()-1]:
		_destroy_rest_of_this_layout_level()
	
	__parent = __parent.get_parent()
	__cursor.pop_back()
	__cursor[__cursor.size()-1] += 1



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
	if __parent.get_child_count() != __cursor[__cursor.size()-1]:
		_destroy_rest_of_this_layout_level()
	
	__parent = __parent.get_parent()
	__cursor.pop_back()
	__cursor[__cursor.size()-1] += 1

func _register_button_press(b: Button) -> void:
	var nodepath := self.get_path_to(b)
	__inputs[nodepath] = {}

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
	while p.get_child_count() > __cursor[__cursor.size()-1]:
		var child := p.get_child(-1)
		p.remove_child(child)
		child.queue_free()
