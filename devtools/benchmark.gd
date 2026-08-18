extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var species := SpeciesFactory.load_stellacress()
	var plant_store := PlantStore.new()
	var genome_store := GenomeStore.new()
	var breeder := BreedingEngine.new(species, plant_store, genome_store, 20260817)
	breeder.create_founders()
	var started := Time.get_ticks_msec()
	var population := breeder.generate_population(plant_store.get_plant(1), plant_store.get_plant(2), 5000, breeder.begin_event())
	var elapsed := Time.get_ticks_msec() - started
	print("5000 offspring: %d ms, plants=%d, genomes=%d" % [elapsed, plant_store.size(), genome_store.all_refs().size()])
	var genetics := GeneticsEngine.new(species)
	var selection := SelectionService.new(species, genetics, genome_store)
	var selection_started := Time.get_ticks_msec()
	var candidates := selection.select_candidates(population, species.environment_by_code(&"E0"), 20)
	print("5000 selection: %d ms, candidates=%d" % [Time.get_ticks_msec() - selection_started, candidates.size()])
	var invalid := 0
	for plant: PlantRecord in population:
		if not genome_store.get_genome(plant.genome_ref).validate_genome(species).is_empty(): invalid += 1
	print("invalid genomes: %d" % invalid)
	var gamete_started := Time.get_ticks_msec()
	var meiosis := MeiosisEngine.new(species)
	var parent_genome := genome_store.get_genome(population[0].genome_ref)
	var maximum_segments := 0
	for index: int in 50000:
		var gamete := meiosis.make_gamete(parent_genome, SeedContract.make_rng(91, 9, index, 0))
		for haplotype: Haplotype in gamete.chromosomes: maximum_segments = maxi(maximum_segments, haplotype.segments.size())
	print("50000 gametes: %d ms, max_segments=%d" % [Time.get_ticks_msec() - gamete_started, maximum_segments])
	quit(1 if invalid > 0 else 0)
