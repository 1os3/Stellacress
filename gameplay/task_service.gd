class_name TaskService
extends RefCounted

var species: SpeciesDefinition
var genetics_engine: GeneticsEngine
var pedigree_service: PedigreeService
var trial_service: TrialService
var plant_store: PlantStore
var genome_store: GenomeStore
var mode: StringName = &"tasks"
var completed: Dictionary = {"A": false, "B": false, "C": false}

func _init(
		p_species: SpeciesDefinition,
		p_genetics_engine: GeneticsEngine,
		p_pedigree_service: PedigreeService,
		p_trial_service: TrialService,
		p_plant_store: PlantStore,
		p_genome_store: GenomeStore,
) -> void:
	species = p_species
	genetics_engine = p_genetics_engine
	pedigree_service = p_pedigree_service
	trial_service = p_trial_service
	plant_store = p_plant_store
	genome_store = p_genome_store

func evaluate(named_lines: Array[NamedLine]) -> PackedStringArray:
	var newly_completed := PackedStringArray()
	if not bool(completed["A"]) and _has_task_a_line(named_lines):
		completed["A"] = true
		newly_completed.append("A")
	if bool(completed["A"]) and not bool(completed["B"]) and _has_task_b_line(named_lines):
		completed["B"] = true
		newly_completed.append("B")
	if bool(completed["B"]) and not bool(completed["C"]) and _has_task_c_lines(named_lines):
		completed["C"] = true
		newly_completed.append("C")
	return newly_completed

func state() -> Dictionary:
	return {"mode": String(mode), "completed": completed.duplicate(true)}

func restore(data: Dictionary) -> void:
	mode = StringName(data.get("mode", "tasks"))
	completed = (data.get("completed", completed) as Dictionary).duplicate(true)

func _has_task_a_line(lines: Array[NamedLine]) -> bool:
	var yld1 := species.locus_by_code(&"YLD1")
	var hgt := species.locus_by_code(&"HGT")
	for line: NamedLine in lines:
		var plant := plant_store.get_plant(line.plant_id)
		var genome := genome_store.get_genome(plant.genome_ref)
		if genetics_engine.allele_dosage(genome, yld1) == 2 and genetics_engine.allele_dosage(genome, hgt) == 0:
			return true
	return false

func _has_task_b_line(lines: Array[NamedLine]) -> bool:
	var res2 := species.locus_by_code(&"RES2")
	var frt := species.locus_by_code(&"FRT")
	var shat := species.locus_by_code(&"SHAT")
	for line: NamedLine in lines:
		var plant := plant_store.get_plant(line.plant_id)
		var genome := genome_store.get_genome(plant.genome_ref)
		var ancestry := pedigree_service.genome_ancestry(plant.id)
		if genetics_engine.allele_dosage(genome, res2) == 2 and genetics_engine.allele_dosage(genome, frt) == 2 and genetics_engine.allele_dosage(genome, shat) == 2 and float(ancestry.get(3, 0.0)) <= 0.10:
			return true
	return false

func _has_task_c_lines(lines: Array[NamedLine]) -> bool:
	if lines.size() < 2:
		return false
	var winners: Dictionary = {}
	for environment_code: StringName in [&"E1", &"E2"]:
		var environment := species.environment_by_code(environment_code)
		var founder_best := 0.0
		var phenotype_engine := PhenotypeEngine.new(species)
		for founder_id: int in range(1, 5):
			var founder_plant := plant_store.get_plant(founder_id)
			if founder_plant != null:
				var profile := genetics_engine.build_genetic_profile(genome_store.get_genome(founder_plant.genome_ref))
				founder_best = maxf(founder_best, phenotype_engine.expected_phenotype(profile, environment).expected_yield_g)
		var best_line_id := 0
		var best_yield := founder_best * 1.05
		for line: NamedLine in lines:
			for trial: TrialRecord in trial_service.trials:
				if trial.environment_code != environment_code or trial.replicate_count < 3 or not trial.plant_ids.has(line.plant_id):
					continue
				var summary := trial_service.summary_for(trial, line.plant_id)
				if float(summary.get("mean_yield_g", 0.0)) > best_yield:
					best_yield = float(summary["mean_yield_g"])
					best_line_id = line.id
		if best_line_id == 0:
			return false
		winners[environment_code] = best_line_id
	return winners[&"E1"] != winners[&"E2"]
