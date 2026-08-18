class_name MutationService
extends RefCounted

const NOVEL_TEMPLATES: Array[Dictionary] = [
	{"seed_number_potential": 45.0},
	{"drought_score": 4.0},
	{"heat_score": 4.0},
	{"quality_score": 4.0},
	{"maturity_days": -1.0},
]

var species: SpeciesDefinition
var genetics_engine: GeneticsEngine
var records: Array[MutationRecord] = []
var next_mutation_id: int = 1

func _init(p_species: SpeciesDefinition, p_genetics_engine: GeneticsEngine) -> void:
	species = p_species
	genetics_engine = p_genetics_engine

func apply_to_gamete(gamete: Gamete, rng: RandomNumberGenerator, origin_plant_id: int, generation: int) -> Array[MutationRecord]:
	var created: Array[MutationRecord] = []
	if rng.randf() < species.known_mutation_rate:
		var locus: LocusDefinition = species.loci[rng.randi_range(0, species.loci.size() - 1)]
		var haplotype := gamete.haplotype_for(locus.chromosome_id)
		var current_allele := genetics_engine.get_allele(haplotype, locus)
		var record := _new_record(origin_plant_id, generation, locus.chromosome_id, locus.position_cm)
		record.locus_id = locus.id
		record.new_allele_id = 1 - current_allele
		for index: int in range(haplotype.variants.size() - 1, -1, -1):
			if haplotype.variants[index].locus_id == locus.id:
				haplotype.variants.remove_at(index)
		haplotype.variants.append(VariantOverride.new(locus.position_cm, locus.id, record.new_allele_id, record.id))
		haplotype.variants.sort_custom(func(a: VariantOverride, b: VariantOverride) -> bool: return a.position_cm < b.position_cm)
		created.append(record)
	if rng.randf() < species.novel_qtl_mutation_rate:
		var chromosome: ChromosomeDefinition = species.chromosomes[rng.randi_range(0, species.chromosomes.size() - 1)]
		var position := snappedf(rng.randf_range(0.0, chromosome.length_cm), 0.01)
		var record := _new_record(origin_plant_id, generation, chromosome.id, position)
		record.locus_id = -1
		record.trait_effects = NOVEL_TEMPLATES[rng.randi_range(0, NOVEL_TEMPLATES.size() - 1)].duplicate(true)
		var haplotype := gamete.haplotype_for(chromosome.id)
		haplotype.variants.append(VariantOverride.new(position, -1, 1, record.id))
		haplotype.variants.sort_custom(func(a: VariantOverride, b: VariantOverride) -> bool: return a.position_cm < b.position_cm)
		created.append(record)
	return created

func _new_record(origin_plant_id: int, generation: int, chromosome_id: int, position_cm: float) -> MutationRecord:
	var record := MutationRecord.new()
	record.id = next_mutation_id
	next_mutation_id += 1
	record.origin_plant_id = origin_plant_id
	record.origin_generation = generation
	record.chromosome_id = chromosome_id
	record.position_cm = position_cm
	records.append(record)
	genetics_engine.register_mutation(record)
	return record
