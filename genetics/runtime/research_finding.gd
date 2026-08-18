class_name ResearchFinding
extends RefCounted

enum RevealLevel { HIDDEN, INTERVAL, IDENTIFIED }

var locus_id: int
var trait_code: StringName
var reveal_level: RevealLevel = RevealLevel.HIDDEN
var confidence: float
var interval_start_cm: float
var interval_end_cm: float
var effect_direction: int

func to_dictionary() -> Dictionary:
	return {
		"locus_id": locus_id,
		"trait_code": String(trait_code),
		"reveal_level": reveal_level,
		"confidence": confidence,
		"interval_start_cm": interval_start_cm,
		"interval_end_cm": interval_end_cm,
		"effect_direction": effect_direction,
	}
