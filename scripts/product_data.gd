class_name ProductData
extends Resource

## A small, reusable definition for one product sold in the store.
@export var id: String = ""
@export var display_name: String = ""
@export_range(0, 100000, 1) var price: int = 0
@export var shelf_location: String = ""
@export_range(0.5, 2.5, 0.05) var display_scale: float = 1.6
@export_range(0, 10, 1) var unlock_day: int = 1
@export_range(0, 100000, 1) var unlock_cost: int = 0
