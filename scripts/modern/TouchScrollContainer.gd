extends ScrollContainer
## Keep native touch scrolling and its SCROLL_BEGIN click cancellation available
## when a gesture starts over a card or an action button, including rebuilt pages.

func _ready() -> void:
	scroll_deadzone = 12
	if not OS.has_feature("mobile"):
		Input.emulate_touch_from_mouse = true
	_watch_children(self)

func _watch_children(node: Node) -> void:
	if node is Window or node is CanvasLayer:
		return # A modal owns a separate input surface and its own scroll container.
	if node != self and node is ScrollContainer:
		return
	if node != self and node is Control:
		if node.mouse_filter == Control.MOUSE_FILTER_STOP:
			node.mouse_filter = Control.MOUSE_FILTER_PASS
		if node is BaseButton:
			# A drag must be distinguishable from a tap before purchasing anything.
			node.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	if not node.child_entered_tree.is_connected(_watch_children):
		node.child_entered_tree.connect(_watch_children)
	for child in node.get_children():
		_watch_children(child)
