class_name MeiosisEngine
extends RefCounted

const POSITION_QUANTUM_CM: float = 0.01

var species: SpeciesDefinition

func _init(p_species: SpeciesDefinition) -> void:
	species = p_species

func make_gamete(parent: Genome, rng: RandomNumberGenerator) -> Gamete:
	var gamete := Gamete.new()
	for chromosome: ChromosomeDefinition in species.chromosomes:
		var haplotype_a := parent.haplotype_for(chromosome.id, true)
		var haplotype_b := parent.haplotype_for(chromosome.id, false)
		var chromosome_rng := RandomNumberGenerator.new()
		chromosome_rng.seed = SeedContract.hash_v1(rng.seed, 0, 0, chromosome.id)
		gamete.chromosomes.append(make_gamete_chromosome(haplotype_a, haplotype_b, chromosome, chromosome_rng))
	return gamete

func make_gamete_chromosome(
		haplotype_a: Haplotype,
		haplotype_b: Haplotype,
		chromosome: ChromosomeDefinition,
		rng: RandomNumberGenerator,
) -> Haplotype:
	var crossover_count := sample_poisson(chromosome.length_cm / 100.0, rng)
	var cuts: Array[float] = []
	for _index: int in crossover_count:
		var cut := snappedf(rng.randf_range(0.0, chromosome.length_cm), POSITION_QUANTUM_CM)
		if cut > 0.0 and cut < chromosome.length_cm and not cuts.has(cut):
			cuts.append(cut)
	cuts.sort()
	var boundaries: Array[float] = [0.0]
	boundaries.append_array(cuts)
	boundaries.append(chromosome.length_cm)
	var use_a := rng.randf() < 0.5
	var output := Haplotype.new(chromosome.id)
	for index: int in range(boundaries.size() - 1):
		var source := haplotype_a if use_a else haplotype_b
		_append_interval(output, source, boundaries[index], boundaries[index + 1], chromosome.length_cm)
		use_a = not use_a
	_merge_adjacent(output.segments)
	output.variants.sort_custom(func(a: VariantOverride, b: VariantOverride) -> bool: return a.position_cm < b.position_cm)
	return output

func sample_poisson(lambda_value: float, rng: RandomNumberGenerator) -> int:
	if lambda_value <= 0.0:
		return 0
	var limit := exp(-lambda_value)
	var product := 1.0
	var count := 0
	while product > limit:
		count += 1
		product *= rng.randf()
	return count - 1

func _append_interval(
		output: Haplotype,
		source: Haplotype,
		left_cm: float,
		right_cm: float,
		chromosome_length_cm: float,
) -> void:
	for index: int in source.segments.size():
		var segment := source.segments[index]
		var segment_end := source.segments[index + 1].start_cm if index + 1 < source.segments.size() else chromosome_length_cm
		if segment.start_cm >= right_cm or segment_end <= left_cm:
			continue
		var clipped_start := maxf(left_cm, segment.start_cm)
		if output.segments.is_empty() or output.segments[-1].founder_haplotype_id != segment.founder_haplotype_id:
			output.segments.append(Segment.new(clipped_start, segment.founder_haplotype_id))
	for variant: VariantOverride in source.variants:
		var in_interval := variant.position_cm >= left_cm and (variant.position_cm < right_cm or is_equal_approx(right_cm, chromosome_length_cm))
		if in_interval:
			output.variants.append(variant.duplicate_variant())

func _merge_adjacent(segments: Array[Segment]) -> void:
	var index := 1
	while index < segments.size():
		if segments[index - 1].founder_haplotype_id == segments[index].founder_haplotype_id:
			segments.remove_at(index)
		else:
			index += 1
