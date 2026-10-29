class_name OrderFactory
extends RefCounted

static func make_order(order_data: OrderData, available_product_ids: Array[String], rng: RandomNumberGenerator) -> OrderState:
	var pool: Array[String] = []
	for product_id in order_data.product_ids:
		if available_product_ids.has(product_id) and not pool.has(product_id):
			pool.append(product_id)
	if pool.is_empty():
		for product_id in available_product_ids:
			pool.append(product_id)
	if pool.is_empty():
		push_warning("Order generation skipped because the stocked product pool is empty.")
		return OrderState.new()
	var low := maxi(1, order_data.minimum_units)
	var high := maxi(low, order_data.maximum_units)
	var units := rng.randi_range(low, high)
	var requested := {}
	for _index in range(units):
		var product_id := pool[rng.randi_range(0, pool.size() - 1)]
		requested[product_id] = int(requested.get(product_id, 0)) + 1
	return OrderState.new(requested)
