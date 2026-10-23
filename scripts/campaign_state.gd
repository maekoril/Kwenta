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

func get_max_order_units() -> int:
	if config.max_order_sizes.is_empty():
		return 3
	return int(config.max_order_sizes[mini(day - 1, config.max_order_sizes.size() - 1)])

func get_available_product_ids() -> Array[String]:
	var result: Array[String] = []
	for product_resource in config.product_catalog:
		var product: ProductData = product_resource
		if is_product_available(product):
			result.append(product.id)
	return result

func get_order_data_for_day(requested_day: int) -> OrderData:
	if config.day_order_pools.is_empty():
		var fallback := OrderData.new()
		fallback.minimum_units = 1
		fallback.maximum_units = mini(3, get_max_order_units())
		fallback.product_ids = get_available_product_ids()
		return fallback
	var index := 0
	for pool_index in range(config.order_pool_start_days.size()):
		if config.order_pool_start_days[pool_index] <= requested_day:
			index = pool_index
	index = mini(index, config.day_order_pools.size() - 1)
	var source: OrderData = config.day_order_pools[index]
	var result := OrderData.new()
	result.product_ids = source.product_ids.duplicate()
	result.minimum_units = source.minimum_units
	result.maximum_units = maxi(source.minimum_units, mini(source.maximum_units, get_max_order_units()))
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
