class_name TrialRecord
extends RefCounted

var id: int
var environment_code: StringName
var replicate_count: int
var plant_ids: Array[int] = []
var observations: Array[PhenotypeObservation] = []

func to_dictionary() -> Dictionary:
	var observation_data: Array[Dictionary] = []
	for observation: PhenotypeObservation in observations:
		observation_data.append(observation.to_dictionary())
	return {
		"id": id,
		"environment_code": String(environment_code),
		"replicate_count": replicate_count,
		"plant_ids": plant_ids,
		"observations": observation_data,
	}
