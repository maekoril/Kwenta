class_name OrderData
extends Resource

@export var product_ids: Array[String] = []
@export_range(1, 20, 1) var minimum_units: int = 1
@export_range(1, 20, 1) var maximum_units: int = 3
