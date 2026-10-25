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
	var condiments: Dictionary = products.get("boss_toyo", {})
	_assert(condiments.get("purchase_group") == "condiments" and int(condiments.get("unlock_day", 0)) == 3 and int(condiments.get("price", 0)) == 300, "condiments share the Day 3 PHP 300 purchase group")
	var purchased_stocked := StoreConfig.get_stocked_ids(config, 3, ["bato_spring_water", "condiments"])
	_assert(purchased_stocked.has("bato_spring_water") and purchased_stocked.has("boss_toyo") and purchased_stocked.has("pating") and purchased_stocked.has("real_suka"), "purchased buyable groups stock every mapped shelf product")
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
