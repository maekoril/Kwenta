class_name CampaignState
extends RefCounted

var config: CampaignConfig
var day: int = 1
var cash: int
var unlocked_product_ids: Array[String] = []
var purchased_upgrade_ids: Array[String] = []
var upgrade_investment: int = 0
var product_price_bonuses: Dictionary = {}
var customer_trust: Dictionary = {}
var purchased_store_groups: Array[String] = []
var stocked_product_ids: Array[String] = []
var barangay_trust: float = 100.0 # BAGO: Global trust limit kada araw

func purchase_store_group(group_id: String, price: int) -> bool:
	if group_id.is_empty() or purchased_store_groups.has(group_id) or cash < price:
		return false
	cash -= price
	purchased_store_groups.append(group_id)
	return true

func _init(campaign_config: CampaignConfig) -> void:
	config = campaign_config
	cash = config.initial_cash
	for product_resource in config.product_catalog:
		var product: ProductData = product_resource
		if product.unlock_day == 1:
			unlocked_product_ids.append(product.id)

func get_active_customer_limit() -> int:
	if config.customer_caps.is_empty():
		return 2
	return int(config.customer_caps[mini(day - 1, config.customer_caps.size() - 1)])

func get_shift_close_minutes() -> int:
	return config.get_shift_close_minutes(day)

func get_shift_length_seconds() -> float:
	return config.get_shift_length_seconds_for_day(day)

func get_customer_spawn_interval() -> float:
	return config.get_customer_spawn_interval_for_day(day)

func get_customer_patience_seconds() -> float:
	return config.get_customer_patience_seconds_for_day(day)

func get_max_order_units() -> int:
	if config.max_order_sizes.is_empty():
		return 3
	return int(config.max_order_sizes[mini(day - 1, config.max_order_sizes.size() - 1)])

func get_available_product_ids() -> Array[String]:
	if not stocked_product_ids.is_empty():
		return stocked_product_ids.duplicate()
	var result: Array[String] = []
	for product_resource in config.product_catalog:
		var product: ProductData = product_resource
		if is_product_available(product):
			result.append(product.id)
	return result

func set_stocked_product_ids(product_ids: Array[String]) -> void:
	stocked_product_ids.clear()
	for product_id in product_ids:
		if not product_id.is_empty() and not stocked_product_ids.has(product_id):
			stocked_product_ids.append(product_id)

func to_dict() -> Dictionary:
	return {"day": day, "cash": cash, "purchased_store_groups": purchased_store_groups.duplicate(), "barangay_trust": barangay_trust}

func from_dict(data: Dictionary) -> void:
	day = clampi(int(data.get("day", day)), 1, config.campaign_day_count)
	cash = int(data.get("cash", cash))
	purchased_store_groups.clear()
	for group_id in data.get("purchased_store_groups", []):
		var value := str(group_id)
		if not value.is_empty() and not purchased_store_groups.has(value):
			purchased_store_groups.append(value)
			barangay_trust = float(data.get("barangay_trust", 100.0))

func get_order_data_for_day(requested_day: int) -> OrderData:
	var result := OrderData.new()
	result.product_ids = get_available_product_ids()
	result.minimum_units = 1
	result.maximum_units = maxi(1, get_max_order_units())
	return result

func get_customer_trust(customer_id: String) -> float:
	return float(customer_trust.get(customer_id, 100.0))

func save_customer_trust(customer_id: String, trust: float) -> void:
	customer_trust[customer_id] = clampf(trust, 0.0, 100.0)

func count_trusted_regulars() -> int:
	var count := 0
	for trust_value in customer_trust.values():
		if float(trust_value) >= config.trusted_regular_minimum:
			count += 1
	return count

func get_shelf_goal_progress() -> int:
	return cash + upgrade_investment

func get_product_price(product: ProductData) -> int:
	return product.price + int(product_price_bonuses.get(product.id, 0))

func is_product_available(product: ProductData) -> bool:
	if unlocked_product_ids.has(product.id):
		return true
	return product.unlock_day > 0 and day >= product.unlock_day

func purchase_unlock(product: ProductData) -> bool:
	if product.unlock_day > 0 or product.unlock_cost <= 0 or unlocked_product_ids.has(product.id) or cash < product.unlock_cost:
		return false
	cash -= product.unlock_cost
	unlocked_product_ids.append(product.id)
	return true

func purchase_upgrade(upgrade: StoreUpgradeData) -> bool:
	if upgrade == null or upgrade.id.is_empty() or purchased_upgrade_ids.has(upgrade.id):
		return false
	if day < upgrade.offer_after_day or day >= config.campaign_day_count or cash < upgrade.purchase_cost:
		return false
	cash -= upgrade.purchase_cost
	upgrade_investment += upgrade.purchase_cost
	purchased_upgrade_ids.append(upgrade.id)
	for product_id in upgrade.product_ids:
		if not unlocked_product_ids.has(product_id):
			unlocked_product_ids.append(product_id)
	for product_id in upgrade.product_price_bonuses:
		product_price_bonuses[product_id] = int(product_price_bonuses.get(product_id, 0)) + int(upgrade.product_price_bonuses[product_id])
	return true

func advance_day() -> void:
	day = mini(config.campaign_day_count, day + 1)
	for product_resource in config.product_catalog:
		var product: ProductData = product_resource
		if product.unlock_day == day and not unlocked_product_ids.has(product.id):
			unlocked_product_ids.append(product.id)
