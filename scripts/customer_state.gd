class_name CustomerState
extends RefCounted

enum DeliveryResult { INACTIVE = 3 }

var customer_id: String
var instance_id: String = ""
var order: OrderState
var patience_seconds: float
var patience_remaining: float
var trust: float
var active: bool = true
var timed_out: bool = false
var trust_loss_on_timeout: float = 25.0

func _init(id: String, customer_order: OrderState, patience: float, initial_trust: float = 100.0) -> void:
	customer_id = id
	order = customer_order
	patience_seconds = maxf(0.1, patience)
	patience_remaining = patience_seconds
	trust = clampf(initial_trust, 0.0, 100.0)

func receive_product(product_id: String) -> int:
	if not active:
		return DeliveryResult.INACTIVE
	return order.try_deliver(product_id)

func advance_time(delta_seconds: float) -> bool:
	if not active or delta_seconds <= 0.0:
		return false
	patience_remaining = maxf(0.0, patience_remaining - delta_seconds)
	if patience_remaining > 0.0:
		return false
	active = false
	timed_out = true
	trust = maxf(0.0, trust - trust_loss_on_timeout)
	return true

func finish_as_paid() -> void:
	active = false

func get_return_weight() -> float:
	return clampf(trust / 100.0, 0.0, 1.0)
