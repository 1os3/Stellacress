class_name ChromosomeDefinition
extends Resource

@export var id: int
@export var code: StringName
@export var length_cm: float
@export var locus_ids_sorted: PackedInt32Array

func validate_definition() -> String:
	if id <= 0:
		return "染色体 id 必须大于 0"
	if code.is_empty():
		return "染色体 code 不能为空"
	if length_cm <= 0.0:
		return "%s.length_cm 必须大于 0" % code
	return ""
