class_name PaymentState
extends RefCounted

# One pending payment: the customer's order is done, they hand over `tendered`,
# and the player must give back `change_due()`.

enum Result { EXACT, SHORT, OVER, NO_PAYMENT }

var total: int
var tendered: int
var mistakes: int = 0   # wrong (short) attempts so far on this payment

func _init(order_total: int, tendered_amount: int) -> void:
	total = order_total
	tendered = maxi(tendered_amount, order_total)

func change_due() -> int:
	return tendered - total

func evaluate(amount_given: int) -> int:
	var due := change_due()
	if amount_given == due:
		return Result.EXACT
	if amount_given < due:
		return Result.SHORT
	return Result.OVER

# What the register ends up with: they gave us `tendered`, we gave back `amount_given`.
# Exact change nets exactly the order total; over-giving makes it smaller.
func net_cash(amount_given: int) -> int:
	return tendered - amount_given
