class_name OrderState
extends RefCounted

enum DeliveryResult { ACCEPTED, COMPLETED, WRONG_PRODUCT }

var requested: Dictionary = {}
var delivered: Dictionary = {}

func _init(requested_units: Dictionary = {}) -> void:
	for product_id in requested_units:
		var quantity := int(requested_units[product_id])
		if quantity > 0:
			requested[str(product_id)] = quantity

func try_deliver(product_id: String) -> int:
	if is_complete() or remaining_quantity(product_id) <= 0:
		return DeliveryResult.WRONG_PRODUCT
	delivered[product_id] = int(delivered.get(product_id, 0)) + 1
	return DeliveryResult.COMPLETED if is_complete() else DeliveryResult.ACCEPTED

func is_complete() -> bool:
	for product_id in requested:
		if int(delivered.get(product_id, 0)) < int(requested[product_id]):
			return false
	return not requested.is_empty()

func remaining_quantity(product_id: String) -> int:
	return maxi(0, int(requested.get(product_id, 0)) - int(delivered.get(product_id, 0)))

func total_price(unit_prices: Dictionary) -> int:
	var total := 0
	for product_id in delivered:
		total += int(delivered[product_id]) * int(unit_prices.get(product_id, 0))
	return total
