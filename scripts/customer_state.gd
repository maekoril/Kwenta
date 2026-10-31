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
var patience_expired: bool = false
var tutorial_protected: bool = false
var story_arrival_pending: bool = false
var trust_loss_on_timeout: float = 25.0
var phase: int = Phase.ORDERING
var payment: PaymentState = null

# Story hooks (see shift_manager.gd and shift_story_events.gd)
var price_discount: int = 0     # pesos knocked off the bill (a haggle, or a refunded wrong item)
var exact_pay: bool = false     # pays the exact amount, no change needed
var tendered_override: int = 0  # optional scripted bill, used only when it covers the order
var parked: bool = false        # order is done, but the sale waits on a story popup (haggle / mix-up)
var mixup_done: bool = false    # a helper mix-up already happened for this customer

func _init(id: String, customer_order: OrderState, patience: float, initial_trust: float = 100.0) -> void:
	customer_id = id
	order = customer_order
	patience_seconds = maxf(0.1, patience)
	patience_remaining = patience_seconds
	trust = clampf(initial_trust, 0.0, 100.0)

func receive_product(product_id: String) -> int:
	if not active or story_arrival_pending or phase != Phase.ORDERING:
		return DeliveryResult.INACTIVE
	return order.try_deliver(product_id)

func advance_time(delta_seconds: float) -> bool:
	if not active or tutorial_protected or delta_seconds <= 0.0:
		return false

	patience_remaining = maxf(0.0, patience_remaining - delta_seconds)

	if patience_remaining > 0.0:
		return false
	patience_expired = true

	# --- BAGONG LOGIC: Continuous Trust Drain sa Suklian ---
	if phase == Phase.PAYING:
		# Babawas ng 1 trust point per second kapag naubos ang patience
		trust = maxf(0.0, trust - (1.0 * delta_seconds))
		return false # HINDI aalis ang customer
	# -------------------------------------------------------

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

# Customer is still waiting for change but their patience bar is already empty.
func is_overdue_paying() -> bool:
	return active and phase == Phase.PAYING and patience_remaining <= 0.0

# Used for wrong (short) change: the customer gets more impatient, but never hits zero
# from this alone; the normal timer tick does that.
func penalize_patience(seconds: float) -> void:
	patience_remaining = maxf(0.1, patience_remaining - seconds)

func finish_as_paid() -> void:
	active = false

func get_return_weight() -> float:
	return clampf(trust / 100.0, 0.0, 1.0)
