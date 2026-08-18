class_name GeneticProfile
extends RefCounted

var values: Dictionary = {}
var color_category: String = "中间"
var anthocyanin_category: String = "无紫"
var flags: Dictionary = {}

func value(trait_code: StringName, fallback: float = 0.0) -> float:
	return float(values.get(trait_code, fallback))

func set_value(trait_code: StringName, amount: float) -> void:
	values[trait_code] = amount

func add_value(trait_code: StringName, amount: float) -> void:
	values[trait_code] = value(trait_code) + amount

func multiply_value(trait_code: StringName, factor: float) -> void:
	values[trait_code] = value(trait_code) * factor
