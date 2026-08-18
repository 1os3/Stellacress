class_name Genome
extends RefCounted

var homolog_a: Array[Haplotype] = []
var homolog_b: Array[Haplotype] = []

func duplicate_genome() -> Genome:
	var copy := Genome.new()
	for haplotype: Haplotype in homolog_a:
		copy.homolog_a.append(haplotype.duplicate_haplotype())
	for haplotype: Haplotype in homolog_b:
		copy.homolog_b.append(haplotype.duplicate_haplotype())
	return copy

func haplotype_for(chromosome_id: int, use_a: bool) -> Haplotype:
	var source: Array[Haplotype] = homolog_a if use_a else homolog_b
	for haplotype: Haplotype in source:
		if haplotype.chromosome_id == chromosome_id:
			return haplotype
	return null

func validate_genome(species: SpeciesDefinition) -> String:
	if homolog_a.size() != species.chromosomes.size() or homolog_b.size() != species.chromosomes.size():
		return "Genome 的同源染色体数量与物种定义不一致"
	for chromosome: ChromosomeDefinition in species.chromosomes:
		var hap_a := haplotype_for(chromosome.id, true)
		var hap_b := haplotype_for(chromosome.id, false)
		if hap_a == null or hap_b == null:
			return "Genome 缺少 Chr%d 的同源副本" % chromosome.id
		var error_a := hap_a.validate_haplotype(chromosome.length_cm)
		if not error_a.is_empty():
			return error_a
		var error_b := hap_b.validate_haplotype(chromosome.length_cm)
		if not error_b.is_empty():
			return error_b
	return ""
