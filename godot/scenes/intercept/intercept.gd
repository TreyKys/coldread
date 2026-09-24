extends CanvasLayer

var config: Dictionary
var on_done: Callable

var blocks_allowed: int = 1
var routes_data: Array = []
var blocked_routes: Array = []

@onready var confirm_button = $VBoxContainer/ConfirmButton
@onready var routes_container = $VBoxContainer/RoutesContainer
@onready var blocks_container = $VBoxContainer/BlocksContainer

func present(cfg: Dictionary, done_callback: Callable) -> void:
	config = cfg
	on_done = done_callback
	routes_data = cfg.get("routes", [])
	blocks_allowed = int(cfg.get("blocks", 1))
	
	_populate_ui()

func _populate_ui() -> void:
	for c in routes_container.get_children():
		c.queue_free()
	for c in blocks_container.get_children():
		c.queue_free()

	blocked_routes.clear()

	for i in routes_data.size():
		var r_data = routes_data[i]
		var zone = RouteZone.new()
		zone.custom_minimum_size = Vector2(200, 60)
		zone.color = Color(0.2, 0.2, 0.2)
		zone.route_data = r_data
		zone.intercept_scene = self
		
		var label = Label.new()
		label.text = String(r_data.get("name", "Route"))
		label.set_anchors_preset(Control.PRESET_CENTER)
		zone.add_child(label)
		
		routes_container.add_child(zone)

	for i in range(blocks_allowed):
		var block = Roadblock.new()
		block.custom_minimum_size = Vector2(40, 40)
		block.color = Color(0.8, 0.2, 0.2)
		blocks_container.add_child(block)

	confirm_button.disabled = true
	if not confirm_button.pressed.is_connected(_on_confirm_button_pressed):
		confirm_button.pressed.connect(_on_confirm_button_pressed)

func roadblock_placed(route_kind: String, block_node: Control) -> void:
	if blocked_routes.has(route_kind):
		return # Already blocked
	
	blocked_routes.append(route_kind)
	Mirror.record_block(route_kind)
	block_node.queue_free()
	
	if blocked_routes.size() >= blocks_allowed:
		confirm_button.disabled = false

func _on_confirm_button_pressed() -> void:
	var max_weight: float = -1.0
	var correct_route_kind: String = ""
	for r in routes_data:
		var w = float(r.get("weight", 0.0))
		if w > max_weight:
			max_weight = w
			correct_route_kind = String(r.get("kind", ""))

	var cut = blocked_routes.has(correct_route_kind)
	on_done.call({"cut": cut})
	queue_free()


class RouteZone extends ColorRect:
	var route_data: Dictionary
	var intercept_scene: Node

	func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
		return typeof(data) == TYPE_OBJECT and data.has_method("is_roadblock")

	func _drop_data(at_position: Vector2, data: Variant) -> void:
		color = Color(0.8, 0.2, 0.2) # Change color to show it's blocked
		intercept_scene.roadblock_placed(String(route_data.get("kind", "")), data)

class Roadblock extends ColorRect:
	func is_roadblock() -> bool:
		return true

	func _get_drag_data(at_position: Vector2) -> Variant:
		var preview = ColorRect.new()
		preview.custom_minimum_size = Vector2(40, 40)
		preview.color = Color(0.8, 0.2, 0.2, 0.7)
		set_drag_preview(preview)
		return self
