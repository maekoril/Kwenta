class_name CampaignConfig
extends Resource

@export var product_catalog: Array[Resource] = []
@export var store_upgrades: Array[Resource] = []
@export var day_order_pools: Array[Resource] = []
@export var order_pool_start_days: Array[int] = [1, 4, 7]
@export var customer_ids: Array[String] = ["aleng_mila", "kuya_ben", "ate_liza", "jun", "manong_tomas", "nina"]
@export var initial_cash: int = 150
@export var shift_length_seconds: float = 480.0
@export var customer_spawn_interval: float = 18.0
@export var customer_patience_seconds: float = 55.0
@export_range(0.0, 100.0, 1.0) var trust_loss_on_timeout: float = 25.0
@export var shelf_replacement_goal: int = 1500
@export var trusted_regular_goal: int = 3
@export_range(0.0, 100.0, 1.0) var trusted_regular_minimum: float = 80.0
@export_range(1, 30, 1) var campaign_day_count: int = 7
@export_file("*.json") var story_source_path: String = "res://data/story/kwenta_7_day_story.json"
@export var customer_caps: Array[int] = [2, 2, 2, 3, 3, 4, 4]
@export var max_order_sizes: Array[int] = [3, 3, 3, 4, 4, 4, 5]
