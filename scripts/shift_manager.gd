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

var campaign_state: CampaignState
var products_by_id: Dictionary
var rng: RandomNumberGenerator
var active_customers: Array[CustomerState] = []
var elapsed_seconds: float = 0.0
var spawn_elapsed: float = 0.0
var current_spawn_delay: float = 0.0
var customer_sequence: int = 0
var is_running: bool = false
var did_emit_completion: bool = false
var shift_earnings: int = 0
var active_customer_limit_override: int = 0
var spawn_delay_min_seconds: float = 0.0
var spawn_delay_max_seconds: float = 0.0
var patience_seconds_override: float = 0.0

# Suki Meter points lost per second for EACH customer still waiting for change
# after their patience bar is empty. Tune this to taste.
const OVERDUE_CHANGE_TRUST_DRAIN_PER_SECOND := 2.0
var _overdue_drain_accumulator: float = 0.0

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

func start_shift() -> void:
	active_customers.clear()
	elapsed_seconds = 0.0
	spawn_elapsed = 0.0
	current_spawn_delay = _next_spawn_delay()
	shift_earnings = 0
	change_total = 0
	change_correct = 0
	change_streak = 0
	best_change_streak = 0
	total_satisfaction_score = 0.0 # BAGO
	total_tips_earned = 0          # BAGO
	did_emit_completion = false
	is_running = true
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
	if not is_running or delta_seconds <= 0.0:
		return
	elapsed_seconds = minf(campaign_state.config.shift_length_seconds, elapsed_seconds + delta_seconds)
	if elapsed_seconds >= campaign_state.config.shift_length_seconds:
		_update_clock()
		finish_shift()
		return
	var customer_left := false
	_drain_trust_for_overdue_change(delta_seconds)
	for customer in active_customers:
		if customer.advance_time(delta_seconds):
			customer_left = true
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
	if active_customers.size() < _active_customer_limit():
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
			var prices := {}
			for id in customer.order.delivered:
				var product: ProductData = products_by_id.get(id)
				if product != null:
					prices[id] = campaign_state.get_product_price(product)
			var order_total := customer.order.total_price(prices)
			var tendered := order_total
			if SukliRules.is_enabled(campaign_state.day):
				tendered = SukliRules.tender_for(order_total, campaign_state.day, rng)
			if tendered > order_total:
				# Order done, but they paid with a bigger bill: wait for the player to give change.
				customer.begin_payment(order_total, tendered, _payment_patience_seconds())
				feedback_changed.emit("%s paid ₱%d. Tap them to give change." % [customer.customer_id.capitalize(), tendered])
				customers_changed.emit()
			else:
				_finish_sale(customer, order_total)
				feedback_changed.emit("Order complete! Customer paid and left.")
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
	campaign_state.cash = maxi(0, campaign_state.cash + net_cash)
	shift_earnings += net_cash
	campaign_state.save_customer_trust(customer.customer_id, customer.trust)
	customer.finish_as_paid()
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
	if ids.is_empty():
		return

	var id: String
	var order: OrderState

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

	var patience_seconds: float = patience_seconds_override if patience_seconds_override > 0.0 else campaign_state.config.customer_patience_seconds
	var customer := CustomerState.new(id, order, patience_seconds, campaign_state.get_customer_trust(id))
	
	customer.trust_loss_on_timeout = campaign_state.config.trust_loss_on_timeout
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
	return campaign_state.config.customer_spawn_interval

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
	var game_minutes := int(floor(elapsed_seconds / campaign_state.config.shift_length_seconds * 600.0))
	var hour := 8 + floori(float(game_minutes) / 60.0)
	var minute := game_minutes % 60
	var display_hour := hour if hour <= 12 else hour - 12
	clock_changed.emit("%d:%02d %s" % [display_hour, minute, "AM" if hour < 12 else "PM"])
	game_minutes_changed.emit(game_minutes)
