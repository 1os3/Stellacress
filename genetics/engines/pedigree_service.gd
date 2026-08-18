class_name PedigreeService
extends RefCounted

var species: SpeciesDefinition
var plant_store: PlantStore
var genome_store: GenomeStore

func _init(p_species: SpeciesDefinition, p_plant_store: PlantStore, p_genome_store: GenomeStore) -> void:
	species = p_species
	plant_store = p_plant_store
	genome_store = p_genome_store

func get_ancestors(plant_id: int, max_depth: int = 10) -> Dictionary:
	var result: Dictionary = {}
	var queue: Array[Vector2i] = [Vector2i(plant_id, 0)]
	var cursor := 0
	while cursor < queue.size():
		var entry := queue[cursor]
		cursor += 1
		if entry.y >= max_depth:
			continue
		var plant := plant_store.get_plant(entry.x)
		if plant == null:
			continue
		for parent_id: int in [plant.parent_a_id, plant.parent_b_id]:
			if parent_id <= 0:
				continue
			var depth := entry.y + 1
			if not result.has(parent_id) or depth < int(result[parent_id]):
				result[parent_id] = depth
			queue.append(Vector2i(parent_id, depth))
	return result

func genome_ancestry(plant_id: int) -> Dictionary:
	var plant := plant_store.get_plant(plant_id)
	if plant == null:
		return {}
	var genome := genome_store.get_genome(plant.genome_ref)
	var ancestry: Dictionary = {}
	var total_length := 0.0
	for chromosome: ChromosomeDefinition in species.chromosomes:
		for haplotype: Haplotype in [genome.haplotype_for(chromosome.id, true), genome.haplotype_for(chromosome.id, false)]:
			total_length += chromosome.length_cm
			for index: int in haplotype.segments.size():
				var start := haplotype.segments[index].start_cm
				var end := haplotype.segments[index + 1].start_cm if index + 1 < haplotype.segments.size() else chromosome.length_cm
				var founder_id := haplotype.segments[index].founder_haplotype_id
				ancestry[founder_id] = float(ancestry.get(founder_id, 0.0)) + end - start
	if total_length > 0.0:
		for founder_id: int in ancestry:
			ancestry[founder_id] = float(ancestry[founder_id]) / total_length
	return ancestry

func founder_at(plant_id: int, chromosome_id: int, homolog_a: bool, position_cm: float) -> int:
	var plant := plant_store.get_plant(plant_id)
	if plant == null:
		return 0
	var genome := genome_store.get_genome(plant.genome_ref)
	var haplotype := genome.haplotype_for(chromosome_id, homolog_a)
	return haplotype.ancestry_at(position_cm) if haplotype != null else 0
