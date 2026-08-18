class_name BreedingEngine
extends RefCounted

var species: SpeciesDefinition
var meiosis_engine: MeiosisEngine
var mutation_service: MutationService
var plant_store: PlantStore
var genome_store: GenomeStore
var run_seed: int
var next_event_id: int = 1
var mutation_enabled: bool = false

func _init(
		p_species: SpeciesDefinition,
		p_plant_store: PlantStore,
		p_genome_store: GenomeStore,
		p_run_seed: int,
) -> void:
	species = p_species
	plant_store = p_plant_store
	genome_store = p_genome_store
	run_seed = p_run_seed
	meiosis_engine = MeiosisEngine.new(species)
	mutation_service = MutationService.new(species, GeneticsEngine.new(species))

func set_mutation_service(service: MutationService) -> void:
	mutation_service = service

func create_founders() -> Array[PlantRecord]:
	var created: Array[PlantRecord] = []
	for founder: FounderDefinition in species.founders:
		var plant := PlantRecord.new(plant_store.allocate_id())
		plant.is_founder = true
		plant.display_name = founder.display_name
		plant.genome_ref = genome_store.add(GenomeFactory.create_founder_genome(species, founder))
		var error := plant_store.add(plant)
		if error.is_empty():
			created.append(plant)
		else:
			push_error(error)
	return created

func begin_event() -> int:
	var event_id := next_event_id
	next_event_id += 1
	return event_id

func cross(
		parent_a: PlantRecord,
		parent_b: PlantRecord,
		event_id: int,
		offspring_index: int,
) -> PlantRecord:
	var genome_a := genome_store.get_genome(parent_a.genome_ref)
	var genome_b := genome_store.get_genome(parent_b.genome_ref)
	var rng_a := SeedContract.make_rng(run_seed, event_id, offspring_index, 0)
	var rng_b := SeedContract.make_rng(run_seed, event_id, offspring_index, 1)
	var gamete_a := meiosis_engine.make_gamete(genome_a, rng_a)
	var gamete_b := meiosis_engine.make_gamete(genome_b, rng_b)
	var child_id := plant_store.allocate_id()
	if mutation_enabled:
		mutation_service.apply_to_gamete(gamete_a, SeedContract.make_rng(run_seed, event_id, offspring_index, 99), child_id, maxi(parent_a.generation, parent_b.generation) + 1)
		mutation_service.apply_to_gamete(gamete_b, SeedContract.make_rng(run_seed, event_id, offspring_index, 100), child_id, maxi(parent_a.generation, parent_b.generation) + 1)
	var child_genome := Genome.new()
	for chromosome: ChromosomeDefinition in species.chromosomes:
		child_genome.homolog_a.append(gamete_a.haplotype_for(chromosome.id))
		child_genome.homolog_b.append(gamete_b.haplotype_for(chromosome.id))
	var child := PlantRecord.new(child_id)
	child.parent_a_id = parent_a.id
	child.parent_b_id = parent_b.id
	child.generation = maxi(parent_a.generation, parent_b.generation) + 1
	child.birth_event_id = event_id
	child.genome_ref = genome_store.add(child_genome)
	var error := plant_store.add(child)
	if not error.is_empty():
		push_error(error)
		return null
	return child

func self_cross(parent: PlantRecord, event_id: int, offspring_index: int) -> PlantRecord:
	return cross(parent, parent, event_id, offspring_index)

func backcross(selected_parent: PlantRecord, recurrent_parent: PlantRecord, event_id: int, offspring_index: int) -> PlantRecord:
	return cross(selected_parent, recurrent_parent, event_id, offspring_index)

func generate_population(parent_a: PlantRecord, parent_b: PlantRecord, count: int, event_id: int) -> Array[PlantRecord]:
	var result: Array[PlantRecord] = []
	for offspring_index: int in count:
		var child := cross(parent_a, parent_b, event_id, offspring_index)
		if child != null:
			result.append(child)
	return result
