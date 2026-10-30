class_name ShiftManager
extends RefCounted

signal customers_changed
signal cash_changed(value: int)
signal clock_changed(value: String)
signal game_minutes_changed(value: int)
signal feedback_changed(message: String)
signal shift_completed
signal customer_timed_out(customer_instance_id: String)
signal barangay_trust_changed(new_value: float) # BAGO
signal game_over_triggered() # BAGO
signal customer_served(customer_id: String, order_units: int)
signal haggle_requested(customer_instance_id: String, ask: int)
signal mixup_requested(customer_instance_id: String, product_id: String)
signal payment_started(customer_instance_id: String)

const HAGGLE_REFUSE_TRUST_LOSS := 5.0
const MIXUP_MISSED_TRUST_LOSS := 15.0

var campaign_state: CampaignState
var products_by_id: Dictionary
var rng: RandomNumberGenerator
var active_customers: Array[CustomerState] = []
var elapsed_seconds: float = 0.0
var spawn_elapsed: float = 0.0
var current_spawn_delay: float = 0.0
var shift_duration_seconds: float = 0.0
var shift_close_minutes: int = CampaignConfig.FULL_SHIFT_GAME_MINUTES
var customer_sequence: int = 0
var is_running: bool = false
var did_emit_completion: bool = false
var shift_earnings: int = 0
var customers_served: int = 0
var customers_timed_out: int = 0
var active_customer_limit_override: int = 0
var spawn_delay_min_seconds: float = 0.0
var spawn_delay_max_seconds: float = 0.0
var patience_seconds_override: float = 0.0

# Suki Meter points lost per second for EACH customer still waiting for change
# after their patience bar is empty. Tune this to taste.
const OVERDUE_CHANGE_TRUST_DRAIN_PER_SECOND := 2.0
var _overdue_drain_accumulator: float = 0.0

# ---- Story hooks. ShiftStoryEvents fills these in before each shift. ----
var frozen: bool = false                # true while a story popup is open: clock and patience stop
var drain_mult: float = 1.0             # patience drains this much faster while drain_boost_seconds > 0
var drain_boost_seconds: float = 0.0
var haggle_asks: Dictionary = {}        # customer_id -> pesos they ask off the bill (once per shift)
var hover_notes: Dictionary = {}        # customer_id -> payment-patience multiplier (they watch the change)
var haggled_ids: Dictionary = {}
var mixup_remaining: int = 0            # how many helper mix-ups are left this shift
var mixup_every: int = 3                # a mix-up can happen on every Nth completed order
var mixup_seen: int = 0
var orders_completed: int = 0
var story_queue: Array[Dictionary] = [] # scripted customers waiting for a free window slot

# Sukli stats for the current shift.
var change_total: int = 0          # sales that needed change and were completed
var change_correct: int = 0        # of those, exact change on the first try
var change_streak: int = 0         # current run of first-try exact change
var best_change_streak: int = 0
var total_satisfaction_score: float = 0.0 # BAGO
var total_tips_earned: int = 0            # BAGO

func _init(state: CampaignState, product_map: Dictionary, random: RandomNumberGenerator) -> void:
	campaign_state = state
	products_by_id = product_map
	rng = random

func reset_story_state() -> void:
	frozen = false
	drain_mult = 1.0
	drain_boost_seconds = 0.0
	haggle_asks.clear()
	hover_notes.clear()
	haggled_ids.clear()
	mixup_remaining = 0
	mixup_every = 3
	mixup_seen = 0
	orders_completed = 0
	story_queue.clear()

func start_shift() -> void:
	frozen = false
	active_customers.clear()
	elapsed_seconds = 0.0
	spawn_elapsed = 0.0
	current_spawn_delay = _next_spawn_delay()
	shift_earnings = 0
	customers_served = 0
	customers_timed_out = 0
	change_total = 0
	change_correct = 0
	change_streak = 0
	best_change_streak = 0
	total_satisfaction_score = 0.0 # BAGO
	total_tips_earned = 0          # BAGO
	did_emit_completion = false
	is_running = true
	# CampaignConfig carries a deliberate close time for each day (noon, 5 PM,
	# 6 PM, then 8 PM). Story events can still freeze time, but never replace it.
	shift_duration_seconds = maxf(0.01, campaign_state.get_shift_length_seconds())
	shift_close_minutes = campaign_state.get_shift_close_minutes()
	_spawn_customer()
	_update_clock()

func _drain_trust_for_overdue_change(delta_seconds: float) -> void:
	if campaign_state.barangay_trust <= 0.0:
		return
	var overdue := 0
	for customer in active_customers:
		if customer.is_overdue_paying():
			overdue += 1
	if overdue == 0:
		_overdue_drain_accumulator = 0.0
		return
	# Accumulate, then apply in whole points so the HUD isn't updated every single frame.
	_overdue_drain_accumulator += OVERDUE_CHANGE_TRUST_DRAIN_PER_SECOND * float(overdue) * delta_seconds
	if _overdue_drain_accumulator < 1.0:
		return
	var points := floorf(_overdue_drain_accumulator)
	_overdue_drain_accumulator -= points
	campaign_state.barangay_trust = maxf(0.0, campaign_state.barangay_trust - points)
	barangay_trust_changed.emit(campaign_state.barangay_trust)
	if campaign_state.barangay_trust <= 0.0:
		game_over_triggered.emit()

func advance_time(delta_seconds: float) -> void:
	if not is_running or frozen or delta_seconds <= 0.0:
		return
	elapsed_seconds = minf(shift_duration_seconds, elapsed_seconds + delta_seconds)
	if elapsed_seconds >= shift_duration_seconds:
		_update_clock()
		finish_shift()
		return
	var customer_left := false

	_drain_trust_for_overdue_change(delta_seconds)

	var drain := 1.0
	if drain_boost_seconds > 0.0:
		drain = drain_mult
		drain_boost_seconds = maxf(0.0, drain_boost_seconds - delta_seconds)

	for customer in active_customers:
		if customer.advance_time(delta_seconds * drain):
			customer_left = true
			customers_timed_out += 1
			campaign_state.save_customer_trust(customer.customer_id, customer.trust)
			# --- BAGO: Bawasan ang global Barangay Trust kapag may walk-out ---
			campaign_state.barangay_trust = maxf(0.0, campaign_state.barangay_trust - 25.0)
			barangay_trust_changed.emit(campaign_state.barangay_trust)
			
			if campaign_state.barangay_trust <= 0.0:
				game_over_triggered.emit()
			# ------------------------------------------------------------------
			if customer.phase == CustomerState.Phase.PAYING:
				change_streak = 0
				feedback_changed.emit("%s didn't wait for their change. Trust fell to %d." % [customer.customer_id.capitalize(), int(customer.trust)])
			else:
				feedback_changed.emit("%s left before finishing. Trust fell to %d." % [customer.customer_id.capitalize(), int(customer.trust)])
			customer_timed_out.emit(customer.instance_id)
	var remaining_customers: Array[CustomerState] = []
	for customer in active_customers:
		if customer.active:
			remaining_customers.append(customer)
	active_customers = remaining_customers
	var spawned_customer := false
	if not story_queue.is_empty() and active_customers.size() < _active_customer_limit():
		_spawn_customer()   # a scripted story customer doesn't wait for the spawn timer
		spawned_customer = true
	elif active_customers.size() < _active_customer_limit():
		spawn_elapsed += delta_seconds
		if spawn_elapsed >= current_spawn_delay:
			spawn_elapsed = 0.0
			current_spawn_delay = _next_spawn_delay()
			_spawn_customer()
			spawned_customer = true
	if customer_left and not spawned_customer:
		customers_changed.emit()
	_update_clock()

func deliver_product(customer_id: String, product_id: String) -> int:
	for customer in active_customers:
		if customer.instance_id != customer_id:
			continue
		var result := customer.receive_product(product_id)
		if result == CustomerState.DeliveryResult.INACTIVE:
			feedback_changed.emit("Give this customer their change first.")
			return result
		if result == OrderState.DeliveryResult.WRONG_PRODUCT:
			feedback_changed.emit("That isn't in this customer's order.")
			return result
		if result == OrderState.DeliveryResult.COMPLETED:
			_on_order_completed(customer)
		else:
			feedback_changed.emit("Good! Keep going.")
		return result
	return CustomerState.DeliveryResult.INACTIVE

# The player hands over `amount` pesos in change. Returns {"result": PaymentState.Result, "diff": int}
# where diff = amount given minus what was due (negative = short, positive = over).
#   EXACT: sale completes, cash goes up by the order total.
#   OVER:  sale completes, but the extra comes out of the register.
#   SHORT: customer refuses, loses a bit of patience; the player can try again.
func give_change(customer_id: String, amount: int) -> Dictionary:
	for customer in active_customers:
		if customer.instance_id != customer_id:
			continue
		if not customer.is_paying():
			break

		var payment: PaymentState = customer.payment
		var result := payment.evaluate(amount)
		var diff := amount - payment.change_due()
		var tip := 0

		if result == PaymentState.Result.SHORT:
			payment.mistakes += 1
			change_streak = 0
			customer.penalize_patience(SukliRules.SHORT_PENALTY_SECONDS)
			feedback_changed.emit("Kulang po ang sukli!")
			return {"result": result, "diff": diff}

		change_total += 1
		
		# --- SATISFACTION AT BONUS TIP LOGIC ---
		var satisfaction := (customer.patience_remaining / customer.patience_seconds) * 100.0
		total_satisfaction_score += satisfaction

		if result == PaymentState.Result.EXACT and payment.mistakes == 0:
			change_correct += 1
			change_streak += 1
			best_change_streak = maxi(best_change_streak, change_streak)
			
			if satisfaction >= 80.0:
				tip = int(randf_range(2.0, 5.0)) # Random tip 2 to 5 pesos
				total_tips_earned += tip
				feedback_changed.emit("Tamang sukli! Ang bilis, may tip na  %d!" % tip)
			else:
				feedback_changed.emit("Tamang sukli!")
		else:
			change_streak = 0
			if result == PaymentState.Result.OVER:
				feedback_changed.emit("Sobra ang naibigay mong sukli:  %d." % diff)
			else:
				feedback_changed.emit("Tamang sukli, pero may mali muna.")

		_finish_sale(customer, payment.net_cash(amount) + tip)
		return {"result": result, "diff": diff}

	return {"result": PaymentState.Result.NO_PAYMENT, "diff": 0}

# ---------------------------------------------------------------- story hooks

# Called when every item of an order has been handed over.
func _on_order_completed(customer: CustomerState) -> void:
	orders_completed += 1
	# A helper (kalaro) may hand over the wrong item; the player decides whether to catch it.
	if mixup_remaining > 0 and not customer.mixup_done and orders_completed % maxi(1, mixup_every) == 0:
		var product_id := _pick_mixup_product(customer)
		if not product_id.is_empty():
			customer.mixup_done = true
			customer.parked = true
			mixup_remaining -= 1
			mixup_seen += 1
			mixup_requested.emit(customer.instance_id, product_id)
			return
	_after_mixup(customer)

func _pick_mixup_product(customer: CustomerState) -> String:
	var ids: Array = customer.order.delivered.keys()
	if ids.is_empty():
		return ""
	if ids.has("chips"):
		return "chips"
	return str(ids[rng.randi_range(0, ids.size() - 1)])

# Next story step after the order is really done: a haggle, or straight to payment.
func _after_mixup(customer: CustomerState) -> void:
	var ask := int(haggle_asks.get(customer.customer_id, 0))
	if ask > 0 and not haggled_ids.has(customer.customer_id):
		haggled_ids[customer.customer_id] = true
		customer.parked = true
		haggle_requested.emit(customer.instance_id, ask)
		return
	_finish_order(customer)

# Works out the bill and either takes the sale or waits for the player to give change.
func _finish_order(customer: CustomerState) -> void:
	customer.parked = false
	var prices := {}
	for id in customer.order.delivered:
		var product: ProductData = products_by_id.get(id)
		if product != null:
			prices[id] = campaign_state.get_product_price(product)
	var order_total := maxi(0, customer.order.total_price(prices) - customer.price_discount)
	var tendered := order_total
	if SukliRules.is_enabled(campaign_state.day) and not customer.exact_pay:
		tendered = SukliRules.tender_for(order_total, campaign_state.day, rng)
	if tendered > order_total:
		# Order done, but they paid with a bigger bill: wait for the player to give change.
		var payment_patience := _payment_patience_seconds()
		if payment_patience < 10000.0:
			payment_patience *= float(hover_notes.get(customer.customer_id, 1.0))
		customer.begin_payment(order_total, tendered, payment_patience)
		feedback_changed.emit("%s paid ₱%d. Tap them to give change." % [customer.customer_id.capitalize(), tendered])
		payment_started.emit(customer.instance_id)
		customers_changed.emit()
	else:
		_finish_sale(customer, order_total)
		feedback_changed.emit("Order complete! Customer paid and left.")

# The player answered a haggle: accepting takes the asked pesos off the bill.
func resolve_haggle(customer_instance_id: String, accepted: bool) -> void:
	for customer in active_customers:
		if customer.instance_id != customer_instance_id or not customer.parked:
			continue
		if accepted:
			customer.price_discount += int(haggle_asks.get(customer.customer_id, 0))
		else:
			customer.trust = maxf(0.0, customer.trust - HAGGLE_REFUSE_TRUST_LOSS)
		_finish_order(customer)
		return

# The player answered a mix-up. Caught: the wrong item is taken back and the order is open
# again. Missed: the customer is refunded that item and loses some trust.
func resolve_mixup(customer_instance_id: String, product_id: String, caught: bool) -> void:
	for customer in active_customers:
		if customer.instance_id != customer_instance_id or not customer.parked:
			continue
		if caught:
			var left := int(customer.order.delivered.get(product_id, 0)) - 1
			if left > 0:
				customer.order.delivered[product_id] = left
			else:
				customer.order.delivered.erase(product_id)
			customer.parked = false
			customers_changed.emit()
		else:
			var product := products_by_id.get(product_id) as ProductData
			if product != null:
				customer.price_discount += campaign_state.get_product_price(product)
			customer.trust = maxf(0.0, customer.trust - MIXUP_MISSED_TRUST_LOSS)
			customer.parked = false
			_after_mixup(customer)
		return

# Customers lose patience `mult` times faster for the next `seconds` (e.g. Tonyo ran off to play).
func apply_patience_boost(mult: float, seconds: float) -> void:
	drain_mult = maxf(1.0, mult)
	drain_boost_seconds = maxf(drain_boost_seconds, seconds)

# Queues a scripted customer. Items the store isn't stocking are dropped from the order.
func queue_story_customer(customer_id: String, requested: Dictionary, exact_pay: bool = false) -> bool:
	var available := campaign_state.get_available_product_ids()
	var order := {}
	for product_id in requested:
		if available.has(str(product_id)):
			order[str(product_id)] = int(requested[product_id])
	if customer_id.is_empty():
		return false
	if order.is_empty():
		# None of the scripted items are stocked today: still bring the character, with a normal order.
		push_warning("Story customer %s: none of the scripted items are stocked today; using a random order." % customer_id)
		order = OrderFactory.make_order(campaign_state.get_order_data_for_day(campaign_state.day), available, rng).requested
		if order.is_empty():
			return false
	story_queue.append({"id": customer_id, "order": order, "exact_pay": exact_pay})
	return true

func get_active_customers() -> Array[CustomerState]:
	return active_customers.duplicate()

func finish_shift() -> void:
	if did_emit_completion:
		return
	did_emit_completion = true
	is_running = false
	active_customers.clear()
	customers_changed.emit()
	shift_completed.emit()

func _finish_sale(customer: CustomerState, net_cash: int) -> void:
	var order_units := 0
	for quantity in customer.order.delivered.values():
		order_units += int(quantity)
	campaign_state.cash = maxi(0, campaign_state.cash + net_cash)
	shift_earnings += net_cash
	customers_served += 1
	campaign_state.save_customer_trust(customer.customer_id, customer.trust)
	customer.finish_as_paid()
	customer_served.emit(customer.customer_id, order_units)
	active_customers.erase(customer)
	spawn_elapsed = 0.0
	current_spawn_delay = _next_spawn_delay()
	cash_changed.emit(campaign_state.cash)
	customers_changed.emit()

func _payment_patience_seconds() -> float:
	var base: float = patience_seconds_override if patience_seconds_override > 0.0 else campaign_state.config.customer_patience_seconds
	# The final day sets a huge override so nobody ever leaves; keep it that way during payment too.
	if base >= 10000.0:
		return base
	return minf(base, SukliRules.payment_patience(campaign_state.day))

func _spawn_customer() -> void:
	if active_customers.size() >= _active_customer_limit():
		return

	var ids := campaign_state.config.customer_ids
	var id: String
	var order: OrderState
	var story_entry: Dictionary = {}

	if not story_queue.is_empty():
		# A scripted story customer (see "shift_events" in the story JSON).
		story_entry = story_queue.pop_front()
		id = str(story_entry.get("id", ""))
		order = OrderState.new(story_entry.get("order", {}))
	else:
		if ids.is_empty():
			return
		# --- DAY 1 STORY OVERRIDE: Si Aling Nena at 2 Noodz ---
		if campaign_state.day == 1 and customer_sequence == 0:
			id = "aling_nena"
			order = OrderState.new({"instant_noodles": 2})
		else:
			# Random spawn para sa mga susunod na customers
			id = _choose_customer_id()
			var order_data := campaign_state.get_order_data_for_day(campaign_state.day)
			order = OrderFactory.make_order(order_data, campaign_state.get_available_product_ids(), rng)
		# ------------------------------------------------------

	if order.requested.is_empty():
		push_warning("No stocked products are available; customer spawn skipped.")
		return

	var patience_seconds: float = patience_seconds_override if patience_seconds_override > 0.0 else campaign_state.get_customer_patience_seconds()
	var customer := CustomerState.new(id, order, patience_seconds, campaign_state.get_customer_trust(id))
	
	customer.trust_loss_on_timeout = campaign_state.config.trust_loss_on_timeout
	customer.exact_pay = bool(story_entry.get("exact_pay", false))
	customer_sequence += 1
	customer.instance_id = "%s_%d" % [id, customer_sequence]

	campaign_state.save_customer_trust(id, customer.trust)
	active_customers.append(customer)

	customers_changed.emit()

func _active_customer_limit() -> int:
	return active_customer_limit_override if active_customer_limit_override > 0 else campaign_state.get_active_customer_limit()

func _next_spawn_delay() -> float:
	if spawn_delay_min_seconds > 0.0 and spawn_delay_max_seconds >= spawn_delay_min_seconds:
		return rng.randf_range(spawn_delay_min_seconds, spawn_delay_max_seconds)
	return campaign_state.get_customer_spawn_interval()

func _choose_customer_id() -> String:
	var ids: Array[String] = []
	for candidate in campaign_state.config.customer_ids:
		var already_here := false
		for customer in active_customers:
			if customer.customer_id == candidate:
				already_here = true
				break
		if not already_here:
			ids.append(candidate)
	if ids.is_empty():
		return campaign_state.config.customer_ids[0]
	var total_weight := 0.0
	for id in ids:
		total_weight += maxf(0.05, campaign_state.get_customer_trust(id) / 100.0)
	var choice := rng.randf() * total_weight
	for id in ids:
		choice -= maxf(0.05, campaign_state.get_customer_trust(id) / 100.0)
		if choice <= 0.0:
			return id
	return ids[0]

func _update_clock() -> void:
	var game_minutes := int(floor(elapsed_seconds / shift_duration_seconds * float(shift_close_minutes)))
	var hour := 8 + floori(float(game_minutes) / 60.0)
	var minute := game_minutes % 60
	var display_hour := hour if hour <= 12 else hour - 12
	clock_changed.emit("%d:%02d %s" % [display_hour, minute, "AM" if hour < 12 else "PM"])
	game_minutes_changed.emit(game_minutes)
