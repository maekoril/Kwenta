class_name StoreRenderer
extends Node2D

const ART_SCALE := 1280.0 / 1672.0
var slots := {}
var debug_slots := false
signal purchase_requested(group_id: String)
signal purchase_denied(group_id: String)

func _ready() -> void:
	name = "StoreRoot"
	position = Vector2.ZERO
	scale = Vector2.ONE * ART_SCALE
	_load_slots()
	print("StoreRoot global_position=%s global_scale=%s" % [global_position, global_scale])

func _load_slots() -> void:
	var f := FileAccess.open("res://assets/store/kwenta_layer_pack/slots.json", FileAccess.READ)
	if f == null: return
	var j := JSON.new()
	if j.parse(f.get_as_text()) != OK: return
	for item in j.data.layers:
		var r: Array = item.slot_rect
		slots[item.id] = Rect2(r[0], r[1], r[2], r[3])

func configure(_day: int, _cash: int, _purchased: Array = []) -> void:
	for child in get_children(): child.queue_free()
	_add_art("bg_empty", "res://assets/store/kwenta_layer_pack/bg_empty.png", Vector2(836,470), 0)
	_add_art("bg_front", "res://assets/store/kwenta_layer_pack/bg_front.png", Vector2(836,470), 10)
	for id in slots:
		var rect := get_slot_rect(id)
		_add_art(id, "res://assets/store/kwenta_layer_pack/layers/%s.png" % id, rect.get_center(), 20)

func _add_art(node_name: String, path: String, at: Vector2, z: int) -> void:
	var texture: Texture2D = load(path)
	if texture == null: return
	print("%s loaded=%s" % [node_name, texture.get_size()])
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = at
	sprite.z_index = z
	add_child(sprite)
func get_slot_rect(id: String) -> Rect2: return slots.get(id, Rect2())
