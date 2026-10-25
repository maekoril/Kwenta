class_name CustomerState
extends RefCounted

enum DeliveryResult { INACTIVE = 3 }
enum Phase { ORDERING, PAYING }

var customer_id: String
var instance_id: String = ""
var order: OrderState
var patience_seconds: float
var patience_remaining: float
var trust: float
var active: bool = true
var timed_out: bool = false
var trust_loss_on_timeout: float = 25.0
var phase: int = Phase.ORDERING
var payment: PaymentState = null

func _init(id: String, customer_order: OrderState, patience: float, initial_trust: float = 100.0) -> void:
	customer_id = id
	order = customer_order
	patience_seconds = maxf(0.1, patience)
	patience_remaining = patience_seconds
	trust = clampf(initial_trust, 0.0, 100.0)

func receive_product(product_id: String) -> int:
	if not active or phase != Phase.ORDERING:
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

# The order is done and the customer hands over `tendered`. They stay at the window
# (still `active`) with a fresh patience timer until the player gives change.
func begin_payment(order_total: int, tendered: int, payment_patience: float) -> void:
	phase = Phase.PAYING
	payment = PaymentState.new(order_total, tendered)
	patience_seconds = maxf(0.1, payment_patience)
	patience_remaining = patience_seconds

func is_paying() -> bool:
	return active and phase == Phase.PAYING

# Used for wrong (short) change: the customer gets more impatient, but never hits zero
# from this alone; the normal timer tick does that.
func penalize_patience(seconds: float) -> void:
	patience_remaining = maxf(0.1, patience_remaining - seconds)

func finish_as_paid() -> void:
	active = false

func get_return_weight() -> float:
	return clampf(trust / 100.0, 0.0, 1.0)
