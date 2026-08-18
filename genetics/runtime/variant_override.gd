class_name VariantOverride
extends RefCounted

var position_cm: float
var locus_id: int
var allele_id: int
var mutation_id: int

func _init(
		p_position_cm: float = 0.0,
		p_locus_id: int = -1,
		p_allele_id: int = 0,
		p_mutation_id: int = 0,
) -> void:
	position_cm = p_position_cm
	locus_id = p_locus_id
	allele_id = p_allele_id
	mutation_id = p_mutation_id

func duplicate_variant() -> VariantOverride:
	return VariantOverride.new(position_cm, locus_id, allele_id, mutation_id)
