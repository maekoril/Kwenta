extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for id in ["neighbor_lina", "neighbor_rosa", "neighbor_nico", "neighbor_ramon"]:
		var actor = load("res://scenes/customer_slot.tscn").instantiate()
		root.add_child(actor)
		var customer := CustomerState.new(id, OrderState.new({"biscuits": 1}), 10.0)
		actor.set_customer(customer, {})
		var normal := actor.portrait.texture as AtlasTexture
		assert(normal.atlas.resource_path.ends_with("%s.png" % id))
		customer.patience_remaining = 2.0
		actor.refresh_patience()
		var impatient := actor.portrait.texture as AtlasTexture
		assert(impatient.atlas.resource_path.ends_with("%s_impatient.png" % id))
		customer.patience_remaining = 10.0
		actor.refresh_patience()
		assert((actor.portrait.texture as AtlasTexture).atlas == normal.atlas)
		actor.queue_free()
	print("All neighbor impatience portraits switch and reset correctly")
	quit()
