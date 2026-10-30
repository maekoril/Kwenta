class_name SukliRules
extends RefCounted

# Everything you might want to tune about the change (sukli) system lives here.

# Day 1 teaches direct serving. Day 2 ("Mali ang Sukli") introduces change,
# then keeps it in the loop for the rest of the campaign.
const FIRST_CHANGE_DAY := 2

# Coins and bills in the player's tray.
const DENOMINATIONS: Array[int] = [1, 5, 10, 20, 50]

# What a customer can hand over (one coin or bill).
const PAYMENT_AMOUNTS: Array[int] = [10, 20, 50, 100, 200]

# Biggest change a customer will normally ask for, per day. If the order is so big that
# nothing fits under the cap, they hand over the smallest bill that covers it.
const MAX_CHANGE_BY_DAY := {2: 30, 3: 50, 4: 70, 5: 80, 6: 100, 7: 150}

# Chance a customer pays the exact amount (no change needed) on days with change.
const EXACT_PAYMENT_CHANCE := 0.15

# Seconds the customer waits for change, per day. Starts fresh when they pay.
const PAYMENT_PATIENCE_BY_DAY := {2: 20.0, 3: 18.0, 4: 16.0, 5: 15.0, 6: 14.0, 7: 14.0}

# Each "kulang" (too little) attempt costs this much of the customer's patience.
const SHORT_PENALTY_SECONDS := 4.0

static func is_enabled(day: int) -> bool:
	return day >= FIRST_CHANGE_DAY

# Days 1–2 show the complete calculation helper. Every day still shows the
# amount due, so later difficulty comes from serving under pressure instead of
# remembering a hidden number.
static func sukli_guide_enabled_for_day(day: int) -> bool:
	return day == 1 or day == 2

static func max_change(day: int) -> int:
	return int(MAX_CHANGE_BY_DAY.get(mini(day, 7), 150))

static func payment_patience(day: int) -> float:
	return float(PAYMENT_PATIENCE_BY_DAY.get(mini(day, 7), 14.0))

# Picks what the customer hands over for an order costing `total`.
static func tender_for(total: int, day: int, rng: RandomNumberGenerator) -> int:
	if total <= 0:
		return total
	if rng.randf() < EXACT_PAYMENT_CHANCE:
		return total
	var cap := max_change(day)
	var candidates: Array[int] = []
	for amount in PAYMENT_AMOUNTS:
		if amount > total and amount - total <= cap:
			candidates.append(amount)
	if candidates.is_empty():
		# Nothing fits under the cap: use the smallest bill that covers the order,
		# or the next hundred for very large orders.
		for amount in PAYMENT_AMOUNTS:
			if amount > total:
				return amount
		return (int(floor(float(total) / 100.0)) + 1) * 100
	return candidates[rng.randi() % candidates.size()]
