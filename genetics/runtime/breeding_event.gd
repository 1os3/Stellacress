class_name BreedingEvent
extends RefCounted

enum Type { CROSS, SELF, BACKCROSS, TRIAL, SELECTION, MUTATION_DISCOVERY, RECOMBINATION_DISCOVERY }

var id: int
var type: Type
var parent_a_id: int
var parent_b_id: int
var offspring_ids: Array[int] = []
var note: String

func to_dictionary() -> Dictionary:
	return {"id": id, "type": type, "parent_a_id": parent_a_id, "parent_b_id": parent_b_id, "offspring_ids": offspring_ids, "note": note}
