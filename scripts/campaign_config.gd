class_name CampaignConfig
extends Resource

const FULL_SHIFT_GAME_MINUTES := 720 # 8:00 AM through 8:00 PM
@export var product_catalog: Array[Resource] = []
@export var store_upgrades: Array[Resource] = []
@export var day_order_pools: Array[Resource] = []
@export var order_pool_start_days: Array[int] = [1, 4, 7]
@export var customer_ids: Array[String] = ["aleng_mila", "kuya_ben", "ate_liza", "jun", "manong_tomas", "nina"]
@export var initial_cash: int = 150
# Full 8 AM–8 PM shift duration. Shorter days scale from this value using their
# configured closing time, so the campaign remains easy to retune in one place.
@export var shift_length_seconds: float = 480.0
@export var shift_close_minutes_by_day: Array[int] = [240, 540, 600, 600, 720, 720, 720]
@export var customer_spawn_interval: float = 18.0
@export var customer_spawn_intervals_by_day: Array[float] = [18.0, 16.0, 14.0, 12.0, 9.0, 6.0, 12.0]
@export var customer_patience_seconds: float = 55.0
@export var customer_patience_seconds_by_day: Array[float] = [999.0, 50.0, 40.0, 32.0, 28.0, 25.0, 999999.0]
@export_range(0.0, 100.0, 1.0) var trust_loss_on_timeout: float = 25.0
@export var shelf_replacement_goal: int = 1500
@export var trusted_regular_goal: int = 3
@export_range(0.0, 100.0, 1.0) var trusted_regular_minimum: float = 80.0
@export_range(1, 30, 1) var campaign_day_count: int = 7
@export_file("*.json") var story_source_path: String = "res://data/story/kwenta_7_day_story.json"
@export var customer_caps: Array[int] = [1, 2, 2, 3, 4, 5, 4]
@export var max_order_sizes: Array[int] = [2, 3, 3, 4, 4, 5, 5]

func get_shift_close_minutes(day: int) -> int:
	if shift_close_minutes_by_day.is_empty():
		return FULL_SHIFT_GAME_MINUTES
	return shift_close_minutes_by_day[mini(maxi(day - 1, 0), shift_close_minutes_by_day.size() - 1)]

func get_shift_length_seconds_for_day(day: int) -> float:
	return shift_length_seconds * float(get_shift_close_minutes(day)) / float(FULL_SHIFT_GAME_MINUTES)

func get_customer_spawn_interval_for_day(day: int) -> float:
	if customer_spawn_intervals_by_day.is_empty():
		return customer_spawn_interval
	return customer_spawn_intervals_by_day[mini(maxi(day - 1, 0), customer_spawn_intervals_by_day.size() - 1)]

func get_customer_patience_seconds_for_day(day: int) -> float:
	if customer_patience_seconds_by_day.is_empty():
		return customer_patience_seconds
	return customer_patience_seconds_by_day[mini(maxi(day - 1, 0), customer_patience_seconds_by_day.size() - 1)]
