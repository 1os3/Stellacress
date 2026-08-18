class_name MutationRecord
extends RefCounted

var id: int
var chromosome_id: int
var position_cm: float
var origin_plant_id: int
var origin_generation: int
var locus_id: int = -1
var new_allele_id: int
var trait_effects: Dictionary = {}
var dominance_effects: Dictionary = {}

func to_dictionary() -> Dictionary:
	return {
		"id": id, "chromosome_id": chromosome_id, "position_cm": position_cm,
		"origin_plant_id": origin_plant_id, "origin_generation": origin_generation,
		"locus_id": locus_id, "new_allele_id": new_allele_id,
		"trait_effects": trait_effects, "dominance_effects": dominance_effects,
	}
