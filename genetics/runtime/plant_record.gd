class_name PlantRecord
extends RefCounted

var id: int
var parent_a_id: int
var parent_b_id: int
var generation: int
var birth_event_id: int
var genome_ref: int
var phenotype_summary_ref: int = 0
var display_name: String
var is_founder: bool = false

func _init(p_id: int = 0) -> void:
	id = p_id
	display_name = "植株 #%d" % id
