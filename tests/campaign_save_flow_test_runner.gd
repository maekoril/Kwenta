extends SceneTree

const SAVE = preload("res://scripts/campaign_save.gd")
const TEST_PATH = "res://tests/campaign_save_test_temp.json"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	SAVE.save_path = TEST_PATH
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	assert(SAVE.load_progress().is_empty())
	var config = load("res://data/story/summer_campaign.tres")
	var campaign := CampaignState.new(config)
	var story := StoryProgression.new(config)
	campaign.day = 2
	campaign.cash = 456
	campaign.barangay_trust = 67.0
	campaign.customer_trust["aling_nena"] = 82.0
	campaign.purchased_store_groups.append("water_shelf")
	campaign.unlocked_product_ids.append("test_unlock")
	campaign.purchased_upgrade_ids.append("test_upgrade")
	campaign.product_price_bonuses["chips"] = 3
	campaign.upgrade_investment = 25
	story.choices["day1_play"] = "stay"
	assert(SAVE.write_progress(campaign, story))
	assert(SAVE.write_progress(campaign, story)) # An existing save can be replaced.
	var saved := SAVE.load_progress()
	assert(saved.campaign.day == 3 and saved.campaign.cash == 456)
	var restored := CampaignState.new(config)
	restored.from_dict(saved.campaign)
	assert(restored.barangay_trust == 67.0 and restored.customer_trust["aling_nena"] == 82.0)
	assert(restored.purchased_store_groups.has("water_shelf") and restored.unlocked_product_ids.has("test_unlock"))
	assert(restored.purchased_upgrade_ids.has("test_upgrade") and restored.product_price_bonuses["chips"] == 3 and restored.upgrade_investment == 25)
	assert(change_scene_to_file("res://scenes/main_menu.tscn") == OK)
	await process_frame
	await process_frame
	var button = current_scene.find_child("ContinueButton", true, false)
	assert(button != null)
	button.pressed.emit()
	await create_timer(2.0).timeout
	var main = current_scene
	assert(main.resumed_campaign and main.campaign.day == 3 and main.campaign.cash == 456)
	assert(main.campaign.barangay_trust == 67.0 and main.story.get_choice("day1_play") == "stay")
	assert(main.story_after_action == "start_shift" and main.bubble.visible)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("Campaign save, replacement, continue transition, and restored progress passed")
	quit()
