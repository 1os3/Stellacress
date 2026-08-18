class_name LocusDefinition
extends Resource

enum Kind { MAJOR, QTL, MARKER }

@export var id: int
@export var code: StringName
@export var chromosome_id: int
@export var position_cm: float
@export var kind: Kind = Kind.MAJOR
@export var allele_labels: PackedStringArray
@export var effect_allele: int = 1
@export var additive_effects: Dictionary = {}
@export var dominance_effects: Dictionary = {}
@export var genotype_effects: Dictionary = {}
@export var categories: PackedStringArray
@export var hidden_until_researched: bool = false

func validate_definition(chromosome_length_cm: float) -> String:
	if id <= 0 or code.is_empty():
		return "位点 id/code 无效"
	if position_cm < 0.0 or position_cm > chromosome_length_cm:
		return "%s.position_cm=%s 超出染色体范围" % [code, position_cm]
	if allele_labels.size() < 2:
		return "%s 至少需要两个等位基因" % code
	if effect_allele < 0 or effect_allele >= allele_labels.size():
		return "%s.effect_allele 无效" % code
	return ""
