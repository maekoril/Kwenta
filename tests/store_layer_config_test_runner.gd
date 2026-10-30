extends SceneTree

const StoreConfig = preload("res://scripts/store_config.gd")

var failures := 0

func _initialize() -> void:
	var config := StoreConfig.load_config("res://data/store_config.json")
	_assert(config.get("base_size") == Vector2i(1672, 941), "store config preserves authored base size")
	var products: Dictionary = config.get("products", {})
	var expected_ids := ["feeta", "giga_sardines", "wemby", "ticnap_notnac", "noodz", "bfresh_gum", "golden_oil", "bato_spring_water", "cola_coca", "boss_toyo", "pating", "real_suka", "jasmine_rice", "egg_large", "maximo", "bread_winner", "thang", "zesty", "patos", "champ_powder", "kapeko_blanca", "clean", "rizz_up"]
	for product_id in expected_ids:
		_assert(products.has(product_id), "%s has editable unlock data" % product_id)
		var entry: Dictionary = products.get(product_id, {})
		_assert(str(entry.get("texture_path", "")).ends_with("layers/%s.png" % product_id), "%s maps directly to its authored layer texture" % product_id)
		_assert(str(entry.get("slot_id", "")) == product_id, "%s maps directly to its authored slot" % product_id)
		_assert(not str(entry.get("game_product_id", "")).is_empty(), "%s maps to its gameplay product" % product_id)
	var day_one_stocked := StoreConfig.get_stocked_ids(config, 1, [])
	_assert(day_one_stocked == ["feeta", "noodz", "thang", "cola_coca", "egg_large"], "Day 1 stocks only the requested five products")
	_assert(_matches_shelf(products, ["champ_powder", "clean", "rizz_up"], "hanging_strip", 150), "right hanging strip is a PHP 150 Day 1 purchase that unlocks every product")
	_assert(_matches_shelf(products, ["bato_spring_water"], "water_shelf", 120), "water shelf is a PHP 120 Day 1 purchase")
	_assert(_matches_shelf(products, ["boss_toyo", "pating", "real_suka"], "condiments", 250), "condiment shelf is a PHP 250 Day 1 purchase that unlocks every condiment")
	_assert(_matches_shelf(products, ["golden_oil"], "oil_shelf", 200), "oil shelf is a PHP 200 Day 1 purchase")
	_assert(_matches_shelf(products, ["jasmine_rice"], "rice_shelf", 300), "rice shelf is a PHP 300 Day 1 purchase")
	var purchased_stocked := StoreConfig.get_stocked_ids(config, 1, ["hanging_strip", "water_shelf", "condiments", "oil_shelf", "rice_shelf"])
	for product_id in ["champ_powder", "clean", "rizz_up", "bato_spring_water", "boss_toyo", "pating", "real_suka", "golden_oil", "jasmine_rice"]:
		_assert(purchased_stocked.has(product_id), "%s is stocked immediately after its shelf is purchased" % product_id)
	if failures > 0:
		push_error("%d store config assertion(s) failed." % failures)
		quit(1)
	print("Store layer configuration assertions passed.")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % message)

func _matches_shelf(products: Dictionary, product_ids: Array[String], group_id: String, price: int) -> bool:
	for product_id in product_ids:
		var entry: Dictionary = products.get(product_id, {})
		if entry.get("unlock_type") != "buyable" or str(entry.get("purchase_group", "")) != group_id or int(entry.get("unlock_day", 0)) != 1 or int(entry.get("price", 0)) != price:
			return false
	return true
