class_name ImGui
extends Container

var __parent: Control = self
var __inputs: Dictionary[NodePath, Dictionary] = { }
# Call depth
var __cursor: Array[int] = [0]
var __theme_variations_stack: Array[String] = []
# Applies minimum size to ALL elements, until popped.
var __min_size_stack: Array[Vector2] = []
var __next_min_size_stack: Array[Vector2] = []


@export_group("Defaults", "_default")
@export var _default_slider_v_height: float = 50
@export var _default_slider_h_width: float = 50

func _ready() -> void:
	for child in get_children():
		push_warning("IMGUI - removing initial children")
		remove_child(child)
		child.queue_free()


func _process(_delta: float) -> void:
	assert(__cursor.size() == 1)
	__cursor[0] = 0
	if not __theme_variations_stack.is_empty():
		push_warning("Leftover theme variations in the stack: " + str(__theme_variations_stack))
		__theme_variations_stack.clear()

## All future [Control]s created with this ImGui will receive this 
## [member Control.theme_type_variation] until it is popped with [method ImGui.pop_variation].
func push_variation(theme_variation: String) -> void:
	__theme_variations_stack.append(theme_variation)

func pop_variation(count: int = 1) -> void:
	assert(count >= 1)
	for i in count:
		assert(not __theme_variations_stack.is_empty(), "Attempted to pop empty stack")
		__theme_variations_stack.pop_back()

## Set minimum size of the [i]next[/i] element that will be created. Also see [method ImGui.push_min_size].
func next_min_size(min_width: float, min_height: float) -> void:
	__next_min_size_stack.append(Vector2(min_width, min_height))

## Convenience method for [method ImGui.next_min_size]
func next_min_height(min_height: float) -> void:
	next_min_size(0, min_height)

## Convenience method for [method ImGui.next_min_size]
func next_min_width(min_width: float) -> void:
	next_min_size(min_width, 0)

## All future [Control]s created with this ImGui will get [param min_size] assigned to
## [member Control.custom_minimum_size] until it is popped with [method ImGui.pop_minimum_size].
func push_min_size(min_width: float, min_height: float) -> void:
	__min_size_stack.append(Vector2(min_width, min_height))

## Convenience method for [method ImGui.push_min_size]
func push_min_height(min_height: float) -> void:
	push_min_size(0, min_height)

## Convenience method for [method ImGui.push_min_size]
func push_min_width(min_width: float) -> void:
	push_min_size(min_width, 0)

func pop_minimum_size(count: int = 1) -> void:
	assert(count >= 1)
	for i in count:
		assert(not __min_size_stack.is_empty(), "Attempted to pop empty stack")
		__min_size_stack.pop_back()


func begin_tabs() -> void:
	begin_vbox()
	# TODO: Refactor styling
	if __parent.custom_minimum_size.is_zero_approx():
		__parent.custom_minimum_size.x = 400
	__parent.add_theme_constant_override("separation", 0)
	__parent.set_anchors_preset(Control.PRESET_FULL_RECT)
	__parent.alignment = BoxContainer.ALIGNMENT_BEGIN

	var current := _get_current_node()
	if current is not TabBar:
		_destroy_rest_of_this_layout_level()
		var tb := TabBar.new()
		__parent.add_child(tb)
		current = tb
	
	_apply_styling(current)
	__cursor[__cursor.size() - 1] += 1 # Next node

	begin_panel()
	__parent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
			while tab_bar.tab_count > index:
				tab_bar.remove_tab(tab_bar.tab_count - 1)
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


func progress_bar(value: float, max_val: float, show_percentage: bool = true) -> void:
	var current := _get_current_node()
	if current is not ProgressBar:
		_destroy_rest_of_this_layout_level()
		var pb := ProgressBar.new()
		__parent.add_child(pb)
		current = pb

	_apply_styling(current)
	current.min_value = 0
	current.max_value = max_val
	current.value = value
	current.show_percentage = show_percentage

	__cursor[__cursor.size() - 1] += 1 # Next node


func toggle(on: bool, text: String = "", enabled: bool = true) -> bool:
	var current := _get_current_node()
	if current is not CheckButton:
		_destroy_rest_of_this_layout_level()
		var check := CheckButton.new()
		check.text = text
		check.name = str(__cursor).validate_node_name()
		check.toggled.connect(_register_button_toggle.bind(check))
		__parent.add_child(check)
		current = check

	_apply_styling(current)
	current.disabled = !enabled
	var np := self.get_path_to(current)
	if not __inputs.erase(np):
		current.set_pressed_no_signal(on)
	
	__cursor[__cursor.size() - 1] += 1 # Next node

	return current.button_pressed


func checkbox(on: bool, text: String = "") -> bool:
	var current := _get_current_node()
	if current is not CheckBox:
		_destroy_rest_of_this_layout_level()
		var check := CheckBox.new()
		check.text = text
		check.name = str(__cursor).validate_node_name()
		check.toggled.connect(_register_button_toggle.bind(check))
		__parent.add_child(check)
		current = check

	_apply_styling(current)
	var np := self.get_path_to(current)
	if not __inputs.erase(np):
		current.set_pressed_no_signal(on)
		
		
	__cursor[__cursor.size() - 1] += 1 # Next node

	return current.button_pressed


func label(text: String, alignment: HorizontalAlignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var current := _get_current_node()
	if current is not Label:
		_destroy_rest_of_this_layout_level()
		var l := Label.new()
		l.name = str(__cursor).validate_node_name()
		l.text = text
		__parent.add_child(l)
		current = l

	_apply_styling(current)
	current.horizontal_alignment = alignment
	current.text = text
	__cursor[__cursor.size() - 1] += 1 # Next node

func separator() -> void:
	match __parent.get_class():
		&"HBoxContainer", &"HFlowContainer":
			separator_v()
		&"VBoxContainer", &"VFlowContainer":
			separator_h()
		_:
			breakpoint

func separator_v() -> void:
	var current := _get_current_node()
	if current is not VSeparator:
		_destroy_rest_of_this_layout_level()
		var vs := VSeparator.new()
		vs.name = str(__cursor).validate_node_name()
		__parent.add_child(vs)
		current = vs

	_apply_styling(current)
	__cursor[__cursor.size() - 1] += 1 # Next node


func separator_h() -> void:
	var current := _get_current_node()
	if current is not HSeparator:
		_destroy_rest_of_this_layout_level()
		var hs := HSeparator.new()
		hs.name = str(__cursor).validate_node_name()
		__parent.add_child(hs)
		current = hs

	_apply_styling(current)
	__cursor[__cursor.size() - 1] += 1 # Next node


func button(text: String, enabled: bool = true) -> bool:
	var current := _get_current_node()
	if current is not Button:
		_destroy_rest_of_this_layout_level()
		var b := Button.new()
		b.name = str(__cursor).validate_node_name()
		b.pressed.connect(_register_button_press.bind(b))
		__parent.add_child(b)
		current = b

	_apply_styling(current)
	current.disabled = !enabled
	current.text = text
	var np := self.get_path_to(current)

	__cursor[__cursor.size() - 1] += 1 # Next node
	return __inputs.erase(np)


func textfield(text: String, enabled: bool = true) -> String:
	var current := _get_current_node()
	if current is not LineEdit:
		_destroy_rest_of_this_layout_level()
		var le := LineEdit.new()
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		le.name = str(__cursor).validate_node_name()
		le.text_changed.connect(_register_textfield_input.bind(le))
		__parent.add_child(le)
		current = le

	_apply_styling(current)
	current.editable = enabled
	var np := self.get_path_to(current)
	if __inputs.has(np):
		__inputs.erase(np)
	else:
		# Setting text on a focused line edit messes with cursor
		# Also unnecessary text updates cause re-renders
		if not current.has_focus() and current.text != text: 
			current.text = text
	
	__cursor[__cursor.size() - 1] += 1 # Next node
	
	return current.text

## Multiline text field
func textedit(text: String, enabled: bool = true) -> String:
	var current := _get_current_node()
	if current is not TextEdit:
		_destroy_rest_of_this_layout_level()
		var te := TextEdit.new()
		te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		te.custom_minimum_size.y = 100
		te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		te.backspace_deletes_composite_character_enabled = true
		te.scroll_fit_content_height = true
		te.name = str(__cursor).validate_node_name()
		te.text_changed.connect(_register_textedit_input.bind(te))
		__parent.add_child(te)
		current = te

	_apply_styling(current)
	current.editable = enabled
	var np := self.get_path_to(current)
	if __inputs.has(np):
		__inputs.erase(np)
	else:
		# Setting text on a focused line edit messes with cursor
		# Also unnecessary text updates cause re-renders
		if not current.has_focus() and current.text != text: 
			current.text = text
	
	__cursor[__cursor.size() - 1] += 1 # Next node
	
	return current.text


func dropdown(selected_index: int, options: Array[String], enabled: bool = true) -> int:
	var current := _get_current_node()
	if current is not OptionButton:
		_destroy_rest_of_this_layout_level()
		var ob := OptionButton.new()
		ob.name = str(__cursor).validate_node_name()
		ob.item_selected.connect(func(_i: int) -> void: _register_dropdown_select(ob))
		__parent.add_child(ob)
		current = ob

	for i: int in range(options.size()):
		var text = options[i]
		if i < current.item_count:
			current.set_item_text(i, text)
		else:
			current.add_item(text)

	_apply_styling(current)
	current.disabled = !enabled 

	var np := self.get_path_to(current)
	if not __inputs.erase(np): # Means that there is no input
		(current as OptionButton).selected = selected_index

	__cursor[__cursor.size() - 1] += 1 # Next node

	return current.selected
	
	
func spinbox(value: int, min_val: int, max_val: int, step: int = 1, enabled: bool = true) -> int:
	var current := _get_current_node()
	if current is not SpinBox:
		_destroy_rest_of_this_layout_level()
		var sb := SpinBox.new()
		sb.name = str(__cursor).validate_node_name()
		sb.value_changed.connect(_register_spinbox_change.bind(sb))
		__parent.add_child(sb)
		current = sb

	_apply_styling(current)
	current.editable = enabled
	current.min_value = min_val
	current.max_value = max_val
	current.step = step
	
	var np := self.get_path_to(current)
	if not __inputs.erase(np): # Means that there is no input
		current.set_value_no_signal(value)

	__cursor[__cursor.size() - 1] += 1 # Next node

	return current.value

func slider_h(value: float, min_val: float, max_val: float, step: float = 1, enabled: bool = true) -> float:
	var current := _get_current_node()
	if current is not HSlider:
		_destroy_rest_of_this_layout_level()
		var hs := HSlider.new()
		hs.custom_minimum_size.x = _default_slider_h_width
		hs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hs.name = str(__cursor).validate_node_name()
		hs.value_changed.connect(_register_spinbox_change.bind(hs))
		__parent.add_child(hs)
		current = hs

	var enforce_minimum_height: bool = __min_size_stack.is_empty() or (__min_size_stack.back().x < _default_slider_h_width)
	if enforce_minimum_height: push_min_width(_default_slider_h_width)
	_apply_styling(current)
	if enforce_minimum_height: pop_minimum_size()

	current.editable = enabled
	current.min_value = min_val
	current.max_value = max_val
	current.step = step
	var np := self.get_path_to(current)
	current.set_value_no_signal(__inputs.get(np, {}).get("value", value))
	if __inputs.has(np): __inputs.erase(np)

	__cursor[__cursor.size() - 1] += 1 # Next node

	return current.value

##
func slider_v(value: float, min_val: float, max_val: float, step: float = 1, enabled: bool = true) -> float:
	var current := _get_current_node()
	if current is not VSlider:
		_destroy_rest_of_this_layout_level()
		var vs := VSlider.new()
		vs.custom_minimum_size.y = _default_slider_v_height
		vs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vs.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vs.name = str(__cursor).validate_node_name()
		vs.value_changed.connect(_register_spinbox_change.bind(vs))
		__parent.add_child(vs)
		current = vs

	var enforce_minimum_height: bool = __min_size_stack.is_empty() or (__min_size_stack.back().y < _default_slider_v_height)
	if enforce_minimum_height: push_min_height(_default_slider_v_height)
	_apply_styling(current)
	if enforce_minimum_height: pop_minimum_size()
	
	current.editable = enabled
	current.min_value = min_val
	current.max_value = max_val
	current.step = step
	
	var np := self.get_path_to(current)
	current.set_value_no_signal(__inputs.get(np, {}).get("value", value))
	if __inputs.has(np): __inputs.erase(np)

	__cursor[__cursor.size() - 1] += 1 # Next node

	return current.value


func begin_vbox() -> void:
	var current := _get_current_node()
	if current is not VBoxContainer:
		_destroy_rest_of_this_layout_level()
		var vbox := VBoxContainer.new()
		vbox.name = str(__cursor).validate_node_name()
		__parent.add_child(vbox)
		current = vbox

	_apply_styling(current)
	__parent = current
	__cursor.append(0)


func end_vbox() -> void:
	assert(__parent is VBoxContainer)
	if __parent.get_child_count() != __cursor[__cursor.size() - 1]:
		_destroy_rest_of_this_layout_level()

	__parent = __parent.get_parent()
	__cursor.pop_back()
	__cursor[__cursor.size() - 1] += 1


func begin_margin(margin: int = -1) -> void:
	begin_margin_v(Vector4i.ONE * margin)

func begin_margin_v(margin: Vector4i) -> void:
	var current := _get_current_node()
	if current is not MarginContainer:
		_destroy_rest_of_this_layout_level()
		var mc := MarginContainer.new()
		mc.name = str(__cursor).validate_node_name()
		__parent.add_child(mc)
		current = mc
	
	_apply_styling(current)
	
	if margin.x >= 0: current.add_theme_constant_override(&"margin_left", margin.x)
	else: current.remove_theme_constant_override(&"margin_left")
	if margin.y >= 0: current.add_theme_constant_override(&"margin_top", margin.y)
	else: current.remove_theme_constant_override(&"margin_top")
	if margin.z >= 0: current.add_theme_constant_override(&"margin_right", margin.z)
	else: current.remove_theme_constant_override(&"margin_right")
	if margin.w >= 0: current.add_theme_constant_override(&"margin_bottom", margin.w)
	else: current.remove_theme_constant_override(&"margin_bottom")

	__parent = current
	__cursor.append(0)


func end_margin() -> void:
	assert(__parent is MarginContainer)
	if __parent.get_child_count() != __cursor[__cursor.size() - 1]:
		_destroy_rest_of_this_layout_level()

	__parent = __parent.get_parent()
	__cursor.pop_back()
	__cursor[__cursor.size() - 1] += 1



func begin_hbox() -> void:
	var current := _get_current_node()
	if current is not HBoxContainer:
		_destroy_rest_of_this_layout_level()
		var vbox := HBoxContainer.new()
		vbox.name = str(__cursor).validate_node_name()
		__parent.add_child(vbox)
		current = vbox
	
	_apply_styling(current)
	__parent = current
	__cursor.append(0)


func end_hbox() -> void:
	assert(__parent is HBoxContainer)
	if __parent.get_child_count() != __cursor[__cursor.size() - 1]:
		_destroy_rest_of_this_layout_level()

	__parent = __parent.get_parent()
	__cursor.pop_back()
	__cursor[__cursor.size() - 1] += 1


func begin_panel() -> void:
	var current := _get_current_node()
	if current is not PanelContainer:
		_destroy_rest_of_this_layout_level()
		var grid := PanelContainer.new()
		grid.name = str(__cursor).validate_node_name()
		__parent.add_child(grid)
		current = grid

	_apply_styling(current)
	__parent = current
	__cursor.append(0)


func end_panel() -> void:
	assert(__parent is PanelContainer)
	if __parent.get_child_count() != __cursor[__cursor.size() - 1]:
		_destroy_rest_of_this_layout_level()

	__parent = __parent.get_parent()
	__cursor.pop_back()
	__cursor[__cursor.size() - 1] += 1


func begin_grid(columns: int) -> void:
	var current := _get_current_node()
	if current is not GridContainer:
		_destroy_rest_of_this_layout_level()
		var grid := GridContainer.new()
		grid.name = str(__cursor).validate_node_name()
		__parent.add_child(grid)
		current = grid

	_apply_styling(current)
	current.columns = columns
	__parent = current
	__cursor.append(0)


func end_grid() -> void:
	assert(__parent is GridContainer)
	if __parent.get_child_count() != __cursor[__cursor.size() - 1]:
		_destroy_rest_of_this_layout_level()

	__parent = __parent.get_parent()
	__cursor.pop_back()
	__cursor[__cursor.size() - 1] += 1

func begin_foldable(title: String, foldable_group: FoldableGroup = null):
	var current := _get_current_node()
	if current is not FoldableContainer:
		_destroy_rest_of_this_layout_level()
		var fold := FoldableContainer.new()
		fold.name = str(__cursor).validate_node_name()
		__parent.add_child(fold)
		current = fold
	
	_apply_styling(current)
	current.title = title
	current.foldable_group = foldable_group
	__parent = current
	__cursor.append(0)

func end_foldable() -> void:
	assert(__parent is FoldableContainer)
	if __parent.get_child_count() != __cursor[__cursor.size() - 1]:
		_destroy_rest_of_this_layout_level()

	__parent = __parent.get_parent()
	__cursor.pop_back()
	__cursor[__cursor.size() - 1] += 1

# -------------------- UTILITIES -------------------- #

func _register_button_press(b: Button) -> void:
	__inputs[self.get_path_to(b)] = { }

func _register_button_toggle(new_value: bool, b: BaseButton) -> void:
	__inputs[self.get_path_to(b)] = { "value": new_value }

func _register_textfield_input(new_text: String, le: LineEdit) -> void:
	__inputs[self.get_path_to(le)] = { "value": new_text }

func _register_textedit_input(te: TextEdit) -> void:
	__inputs[self.get_path_to(te)] = { "value": te.text }

func _register_dropdown_select(ob: OptionButton) -> void:
	__inputs[self.get_path_to(ob)] = { "value": ob.selected }

func _register_spinbox_change(new_value: float, origin: Control) -> void:
	__inputs[self.get_path_to(origin)] = { "value": new_value }


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

func _apply_styling(element: Control) -> void:
	element.theme_type_variation = "" if __theme_variations_stack.is_empty() else __theme_variations_stack.back()
	if not __next_min_size_stack.is_empty():
		element.custom_minimum_size = __next_min_size_stack.pop_back()
	else:
		element.custom_minimum_size = Vector2.ZERO if __min_size_stack.is_empty() else __min_size_stack.back()
