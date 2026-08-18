class_name TrialService
extends RefCounted

var species: SpeciesDefinition
var genetics_engine: GeneticsEngine
var phenotype_engine: PhenotypeEngine
var genome_store: GenomeStore
var run_seed: int
var next_trial_id: int = 1
var trials: Array[TrialRecord] = []

func _init(p_species: SpeciesDefinition, p_genetics_engine: GeneticsEngine, p_genome_store: GenomeStore, p_run_seed: int) -> void:
	species = p_species
	genetics_engine = p_genetics_engine
	genome_store = p_genome_store
	run_seed = p_run_seed
	phenotype_engine = PhenotypeEngine.new(species)

func run_trial(plants: Array[PlantRecord], environment: EnvironmentDefinition, replicate_count: int = 3) -> TrialRecord:
	var trial := TrialRecord.new()
	trial.id = next_trial_id
	next_trial_id += 1
	trial.environment_code = environment.code
	trial.replicate_count = clampi(replicate_count, 1, 20)
	for plant: PlantRecord in plants:
		trial.plant_ids.append(plant.id)
		var genome := genome_store.get_genome(plant.genome_ref)
		var profile := genetics_engine.build_genetic_profile(genome)
		for replicate_id: int in trial.replicate_count:
			var rng := SeedContract.make_rng(run_seed, trial.id, plant.id, 200 + replicate_id)
			var observation := phenotype_engine.observe_phenotype(profile, environment, rng)
			observation.plant_id = plant.id
			observation.replicate_id = replicate_id
			trial.observations.append(observation)
	trials.append(trial)
	return trial

func summary_for(trial: TrialRecord, plant_id: int) -> Dictionary:
	var values: Array[float] = []
	for observation: PhenotypeObservation in trial.observations:
		if observation.plant_id == plant_id:
			values.append(observation.yield_g)
	if values.is_empty():
		return {}
	var mean := _mean(values)
	var variance := 0.0
	for value: float in values:
		variance += pow(value - mean, 2.0)
	variance /= float(maxi(1, values.size() - 1))
	return {"mean_yield_g": mean, "variance": variance, "standard_error": sqrt(variance / float(values.size())), "replicates": values.size()}

func has_qualified_trial(plant_id: int, minimum_replicates: int = 3) -> bool:
	for trial: TrialRecord in trials:
		if trial.replicate_count >= minimum_replicates and trial.plant_ids.has(plant_id):
			return true
	return false

func _mean(values: Array[float]) -> float:
	var total := 0.0
	for value: float in values:
		total += value
	return total / float(maxi(1, values.size()))
