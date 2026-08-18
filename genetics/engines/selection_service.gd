class_name SelectionService
extends RefCounted

var species: SpeciesDefinition
var genetics_engine: GeneticsEngine
var phenotype_engine: PhenotypeEngine
var genome_store: GenomeStore

func _init(p_species: SpeciesDefinition, p_genetics_engine: GeneticsEngine, p_genome_store: GenomeStore) -> void:
	species = p_species
	genetics_engine = p_genetics_engine
	genome_store = p_genome_store
	phenotype_engine = PhenotypeEngine.new(species)

func select_candidates(
		plants: Array[PlantRecord],
		environment: EnvironmentDefinition,
		maximum_count: int = 20,
		hard_filters: Dictionary = {},
		weights: Dictionary = {"yield": 1.0, "drought": 0.4, "quality": 0.3},
) -> Array[PlantRecord]:
	var evaluated: Array[Dictionary] = []
	for plant: PlantRecord in plants:
		var genome := genome_store.get_genome(plant.genome_ref)
		var profile := genetics_engine.build_genetic_profile(genome)
		var phenotype := phenotype_engine.expected_phenotype(profile, environment)
		if not _passes_filters(profile, phenotype, hard_filters):
			continue
		evaluated.append({"plant": plant, "genome": genome, "yield": phenotype.expected_yield_g, "drought": phenotype.drought_score, "quality": phenotype.quality_score})
	# 对大群体先保留综合分最高的 300 株，再做精确 Pareto，避免 O(n²) 扫描 5000 株。
	if evaluated.size() > 300:
		evaluated.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _score(a, weights) > _score(b, weights))
		evaluated = evaluated.slice(0, 300)
	var frontier := _pareto_front(evaluated)
	var pool := frontier if frontier.size() >= maximum_count else evaluated
	pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _score(a, weights) > _score(b, weights))
	var selected: Array[PlantRecord] = []
	for candidate: Dictionary in pool:
		if selected.size() >= maximum_count:
			break
		if _is_diverse(candidate["genome"] as Genome, selected) or selected.size() < mini(5, maximum_count):
			selected.append(candidate["plant"] as PlantRecord)
	# 群体遗传差异很小时，多样性阈值可能不足额；按综合分补齐，但不重复植株。
	if selected.size() < maximum_count:
		for candidate: Dictionary in pool:
			var plant := candidate["plant"] as PlantRecord
			if not selected.has(plant):
				selected.append(plant)
			if selected.size() >= maximum_count:
				break
	return selected

func genetic_distance(genome_a: Genome, genome_b: Genome) -> float:
	var total := 0.0
	for locus: LocusDefinition in species.loci:
		total += absf(float(genetics_engine.allele_dosage(genome_a, locus) - genetics_engine.allele_dosage(genome_b, locus))) / 2.0
	return total / float(species.loci.size())

func _passes_filters(profile: GeneticProfile, phenotype: PhenotypeObservation, filters: Dictionary) -> bool:
	if filters.has("max_maturity") and phenotype.maturity_days > float(filters["max_maturity"]):
		return false
	if filters.has("min_fertility") and profile.value(&"fertility_factor") < float(filters["min_fertility"]):
		return false
	if filters.has("min_yield") and phenotype.expected_yield_g < float(filters["min_yield"]):
		return false
	return true

func _pareto_front(evaluated: Array[Dictionary]) -> Array[Dictionary]:
	var frontier: Array[Dictionary] = []
	for candidate: Dictionary in evaluated:
		var dominated := false
		for other: Dictionary in evaluated:
			if other == candidate:
				continue
			var no_worse := float(other["yield"]) >= float(candidate["yield"]) and float(other["drought"]) >= float(candidate["drought"]) and float(other["quality"]) >= float(candidate["quality"])
			var strictly_better := float(other["yield"]) > float(candidate["yield"]) or float(other["drought"]) > float(candidate["drought"]) or float(other["quality"]) > float(candidate["quality"])
			if no_worse and strictly_better:
				dominated = true
				break
		if not dominated:
			frontier.append(candidate)
	return frontier

func _score(candidate: Dictionary, weights: Dictionary) -> float:
	return float(candidate["yield"]) * 10.0 * float(weights.get("yield", 1.0)) + float(candidate["drought"]) * float(weights.get("drought", 0.4)) + float(candidate["quality"]) * float(weights.get("quality", 0.3))

func _is_diverse(genome: Genome, selected: Array[PlantRecord]) -> bool:
	for plant: PlantRecord in selected:
		if genetic_distance(genome, genome_store.get_genome(plant.genome_ref)) < 0.05:
			return false
	return true
