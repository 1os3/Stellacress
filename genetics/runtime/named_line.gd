class_name NamedLine
extends RefCounted

var id: int
var line_name: String
var plant_id: int
var homozygosity: float
var created_event_id: int

func to_dictionary() -> Dictionary:
	return {"id": id, "line_name": line_name, "plant_id": plant_id, "homozygosity": homozygosity, "created_event_id": created_event_id}
