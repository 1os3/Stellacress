class_name Segment
extends RefCounted

var start_cm: float
var founder_haplotype_id: int

func _init(p_start_cm: float = 0.0, p_founder_haplotype_id: int = 0) -> void:
	start_cm = p_start_cm
	founder_haplotype_id = p_founder_haplotype_id

func duplicate_segment() -> Segment:
	return Segment.new(start_cm, founder_haplotype_id)
