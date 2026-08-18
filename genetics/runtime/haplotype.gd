class_name Haplotype
extends RefCounted

const FLOAT_TOLERANCE: float = 0.000001

var chromosome_id: int
var segments: Array[Segment] = []
var variants: Array[VariantOverride] = []

func _init(p_chromosome_id: int = 0) -> void:
	chromosome_id = p_chromosome_id

func duplicate_haplotype() -> Haplotype:
	var copy := Haplotype.new(chromosome_id)
	for segment: Segment in segments:
		copy.segments.append(segment.duplicate_segment())
	for variant: VariantOverride in variants:
		copy.variants.append(variant.duplicate_variant())
	return copy

func ancestry_at(position_cm: float) -> int:
	var low := 0
	var high := segments.size()
	while low < high:
		var middle := (low + high) >> 1
		if segments[middle].start_cm <= position_cm:
			low = middle + 1
		else:
			high = middle
	return segments[maxi(0, low - 1)].founder_haplotype_id

func validate_haplotype(chromosome_length_cm: float) -> String:
	if segments.is_empty():
		return "Chr%d 单倍型没有 Segment" % chromosome_id
	if absf(segments[0].start_cm) > FLOAT_TOLERANCE:
		return "Chr%d 首个 Segment.start_cm 必须为 0" % chromosome_id
	var previous_start := -1.0
	var previous_founder := -1
	for segment: Segment in segments:
		if segment.start_cm <= previous_start or segment.start_cm < 0.0 or segment.start_cm >= chromosome_length_cm:
			return "Chr%d Segment.start_cm 未严格递增或超界" % chromosome_id
		if segment.founder_haplotype_id == previous_founder:
			return "Chr%d 存在未合并的相邻同祖源 Segment" % chromosome_id
		previous_start = segment.start_cm
		previous_founder = segment.founder_haplotype_id
	var previous_position := -1.0
	for variant: VariantOverride in variants:
		if variant.position_cm < 0.0 or variant.position_cm > chromosome_length_cm or variant.position_cm < previous_position:
			return "Chr%d Variant 未排序或超界" % chromosome_id
		previous_position = variant.position_cm
	return ""
