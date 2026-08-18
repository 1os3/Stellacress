class_name PhenotypeObservation
extends RefCounted

var plant_id: int
var environment_code: StringName
var replicate_id: int
var expected_yield_g: float
var yield_g: float
var height_cm: float
var maturity_days: float
var seed_mass_mg: float
var drought_score: float
var heat_score: float
var disease_score: float
var quality_score: float

func to_dictionary() -> Dictionary:
	return {
		"plant_id": plant_id,
		"environment_code": String(environment_code),
		"replicate_id": replicate_id,
		"expected_yield_g": expected_yield_g,
		"yield_g": yield_g,
		"height_cm": height_cm,
		"maturity_days": maturity_days,
		"seed_mass_mg": seed_mass_mg,
		"drought_score": drought_score,
		"heat_score": heat_score,
		"disease_score": disease_score,
		"quality_score": quality_score,
	}
