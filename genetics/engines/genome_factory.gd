class_name GenomeFactory
extends RefCounted

static func create_founder_genome(species: SpeciesDefinition, founder: FounderDefinition) -> Genome:
	var genome := Genome.new()
	for chromosome: ChromosomeDefinition in species.chromosomes:
		var haplotype_a := Haplotype.new(chromosome.id)
		haplotype_a.segments.append(Segment.new(0.0, founder.id))
		var haplotype_b := Haplotype.new(chromosome.id)
		haplotype_b.segments.append(Segment.new(0.0, founder.id))
		genome.homolog_a.append(haplotype_a)
		genome.homolog_b.append(haplotype_b)
	return genome

static func create_single_locus_genome(
		species: SpeciesDefinition,
		locus: LocusDefinition,
		allele_a_founder_id: int,
		allele_b_founder_id: int,
) -> Genome:
	var genome := Genome.new()
	for chromosome: ChromosomeDefinition in species.chromosomes:
		var founder_a := allele_a_founder_id if chromosome.id == locus.chromosome_id else 1
		var founder_b := allele_b_founder_id if chromosome.id == locus.chromosome_id else 1
		var hap_a := Haplotype.new(chromosome.id)
		hap_a.segments.append(Segment.new(0.0, founder_a))
		var hap_b := Haplotype.new(chromosome.id)
		hap_b.segments.append(Segment.new(0.0, founder_b))
		genome.homolog_a.append(hap_a)
		genome.homolog_b.append(hap_b)
	return genome

static func create_custom_genome(
		species: SpeciesDefinition,
		base_founder: FounderDefinition,
		alleles_a: Dictionary,
		alleles_b: Dictionary,
) -> Genome:
	var genome := create_founder_genome(species, base_founder)
	for locus: LocusDefinition in species.loci:
		var allele_a := int(alleles_a.get(locus.id, base_founder.allele_at(locus.id)))
		var allele_b := int(alleles_b.get(locus.id, base_founder.allele_at(locus.id)))
		if allele_a != base_founder.allele_at(locus.id):
			genome.haplotype_for(locus.chromosome_id, true).variants.append(VariantOverride.new(locus.position_cm, locus.id, allele_a, 0))
		if allele_b != base_founder.allele_at(locus.id):
			genome.haplotype_for(locus.chromosome_id, false).variants.append(VariantOverride.new(locus.position_cm, locus.id, allele_b, 0))
	for haplotype: Haplotype in genome.homolog_a + genome.homolog_b:
		haplotype.variants.sort_custom(func(a: VariantOverride, b: VariantOverride) -> bool: return a.position_cm < b.position_cm)
	return genome
