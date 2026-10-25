class_name StoreUpgradeData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_range(0, 100000, 1) var purchase_cost: int = 0
@export_range(1, 10, 1) var offer_after_day: int = 1
@export var product_ids: Array[String] = []
@export var product_price_bonuses: Dictionary = {}
