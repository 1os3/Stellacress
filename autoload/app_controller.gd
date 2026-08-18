extends Node

signal game_ready
signal breeding_progress(completed: int, total: int)
signal breeding_completed(candidate_ids: Array[int])
signal trial_completed(trial_id: int)
signal research_updated
signal save_completed(slot_index: int)
signal save_failed(message: String)
signal state_changed

const DEFAULT_RUN_SEED: int = 20260817
const BATCH_SIZE: int = 128

var species: SpeciesDefinition
var plant_store: PlantStore
var genome_store: GenomeStore
var genetics_engine: GeneticsEngine
var breeding_engine: BreedingEngine
var phenotype_engine: PhenotypeEngine
var pedigree_service: PedigreeService
var selection_service: SelectionService
var trial_service: TrialService
var research_service: ResearchService
var mutation_service: MutationService
var task_service: TaskService
var tutorial_service: TutorialService
var save_service: SaveService

var run_seed: int = DEFAULT_RUN_SEED
var current_slot: int = 1
var current_slot_name: String = "新育种计划"
var current_environment_code: StringName = &"E0"
var current_population: Array[PlantRecord] = []
var candidates: Array[PlantRecord] = []
var events: Array[BreedingEvent] = []
var named_lines: Array[NamedLine] = []
var busy: bool = false
var has_game: bool = false
var selection_filters: Dictionary = {"max_maturity": 60.0, "min_fertility": 0.5}
var selection_weights: Dictionary = {"yield": 1.0, "drought": 0.4, "quality": 0.3}
var autosave_pending: bool = false

func _ready() -> void:
	species = SpeciesFactory.load_stellacress()
	if species == null:
		push_error("星芥定义加载失败，无法启动游戏")
		return
	save_service = SaveService.new(species)

func new_game(mode: StringName = &"tasks", seed_value: int = DEFAULT_RUN_SEED, slot_index: int = 1, slot_name: String = "新育种计划") -> void:
	run_seed = seed_value
	current_slot = slot_index
	current_slot_name = slot_name
	_initialize_services()
	task_service.mode = mode
	tutorial_service.start(mode == &"tasks")
	breeding_engine.mutation_enabled = mode == &"sandbox"
	breeding_engine.create_founders()
	current_population = plant_store.all_plants()
	candidates = current_population.duplicate()
	has_game = true
	game_ready.emit()
	state_changed.emit()

func _initialize_services() -> void:
	plant_store = PlantStore.new()
	genome_store = GenomeStore.new()
	genetics_engine = GeneticsEngine.new(species)
	breeding_engine = BreedingEngine.new(species, plant_store, genome_store, run_seed)
	mutation_service = MutationService.new(species, genetics_engine)
	breeding_engine.set_mutation_service(mutation_service)
	phenotype_engine = PhenotypeEngine.new(species)
	pedigree_service = PedigreeService.new(species, plant_store, genome_store)
	selection_service = SelectionService.new(species, genetics_engine, genome_store)
	trial_service = TrialService.new(species, genetics_engine, genome_store, run_seed)
	research_service = ResearchService.new(species)
	task_service = TaskService.new(species, genetics_engine, pedigree_service, trial_service, plant_store, genome_store)
	tutorial_service = TutorialService.new()
	events.clear()
	named_lines.clear()
	current_population.clear()
	candidates.clear()

func generate_population(parent_a_id: int, parent_b_id: int, count: int, operation: StringName = &"cross") -> void:
	if busy or not has_game:
		return
	var parent_a := plant_store.get_plant(parent_a_id)
	var parent_b := plant_store.get_plant(parent_b_id)
	if parent_a == null or parent_b == null:
		push_error("生成群体时指定了不存在的亲本")
		return
	busy = true
	count = clampi(count, 1, 5000)
	var event_id := breeding_engine.begin_event()
	var event := BreedingEvent.new()
	event.id = event_id
	event.parent_a_id = parent_a.id
	event.parent_b_id = parent_a.id if operation == &"self" else parent_b.id
	event.type = BreedingEvent.Type.SELF if operation == &"self" else (BreedingEvent.Type.BACKCROSS if operation == &"backcross" else BreedingEvent.Type.CROSS)
	current_population.clear()
	for offspring_index: int in count:
		var child := breeding_engine.self_cross(parent_a, event_id, offspring_index) if operation == &"self" else breeding_engine.cross(parent_a, parent_b, event_id, offspring_index)
		if child != null:
			current_population.append(child)
			event.offspring_ids.append(child.id)
		if (offspring_index + 1) % BATCH_SIZE == 0:
			breeding_progress.emit(offspring_index + 1, count)
			await get_tree().process_frame
	events.append(event)
	var environment := species.environment_by_code(current_environment_code)
	candidates = selection_service.select_candidates(current_population, environment, 20, selection_filters, selection_weights)
	busy = false
	breeding_progress.emit(count, count)
	breeding_completed.emit(_plant_ids(candidates))
	tutorial_service.advance_to(3)
	state_changed.emit()
	autosave()

func run_trial_for(plant_ids: Array[int], environment_code: StringName, replicate_count: int = 3) -> TrialRecord:
	var plants: Array[PlantRecord] = []
	for plant_id: int in plant_ids:
		var plant := plant_store.get_plant(plant_id)
		if plant != null:
			plants.append(plant)
	var environment := species.environment_by_code(environment_code)
	if plants.is_empty() or environment == null:
		return null
	var trial := trial_service.run_trial(plants, environment, replicate_count)
	research_service.update_from_trials(trial_service.trials)
	trial_completed.emit(trial.id)
	tutorial_service.advance_to(6)
	research_updated.emit()
	state_changed.emit()
	autosave()
	return trial

func name_line(plant_id: int, line_name: String) -> String:
	var clean_name := line_name.strip_edges()
	if clean_name.is_empty() or clean_name.length() > 32:
		return "品系名必须为 1–32 个字符"
	var plant := plant_store.get_plant(plant_id)
	if plant == null:
		return "植株不存在"
	var homozygosity := genetics_engine.homozygosity(genome_store.get_genome(plant.genome_ref))
	if homozygosity < 0.90:
		return "该植株纯合度 %.1f%%，尚未达到 90%%" % (homozygosity * 100.0)
	if not trial_service.has_qualified_trial(plant_id, 3):
		return "命名稳定品系前至少需要一次三重复试验"
	var line := NamedLine.new()
	line.id = named_lines.size() + 1
	line.line_name = clean_name
	line.plant_id = plant_id
	line.homozygosity = homozygosity
	line.created_event_id = plant.birth_event_id
	named_lines.append(line)
	tutorial_service.advance_to(7)
	plant.display_name = clean_name
	task_service.evaluate(named_lines)
	state_changed.emit()
	autosave()
	return ""

func create_custom_material(
		material_name: String,
		base_founder_id: int,
		alleles_a: Dictionary,
		alleles_b: Dictionary,
) -> Dictionary:
	if not has_game:
		return {"error": "请先创建或载入档案"}
	var clean_name := material_name.strip_edges()
	if clean_name.is_empty() or clean_name.length() > 32:
		return {"error": "材料名称必须为 1–32 个字符"}
	var founder := species.founder_by_id(base_founder_id)
	if founder == null:
		return {"error": "基础创始系不存在"}
	for allele_map: Dictionary in [alleles_a, alleles_b]:
		for locus_id: int in allele_map:
			if species.locus_by_id(locus_id) == null or int(allele_map[locus_id]) not in [0, 1]:
				return {"error": "自定义等位基因数据无效"}
	var genome := GenomeFactory.create_custom_genome(species, founder, alleles_a, alleles_b)
	var genome_error := genome.validate_genome(species)
	if not genome_error.is_empty():
		return {"error": genome_error}
	var plant := PlantRecord.new(plant_store.allocate_id())
	plant.display_name = clean_name
	plant.is_founder = true
	plant.genome_ref = genome_store.add(genome)
	var plant_error := plant_store.add(plant)
	if not plant_error.is_empty():
		return {"error": plant_error}
	current_population.append(plant)
	candidates.append(plant)
	state_changed.emit()
	autosave()
	return {"error": "", "plant_id": plant.id}

func save_current() -> void:
	if not has_game:
		return
	var error := save_service.save_slot(
		current_slot, current_slot_name, run_seed, {"tasks": task_service.state(), "tutorial": tutorial_service.state()}, plant_store, genome_store,
		events, trial_service.trials, mutation_service.records, research_service.findings,
		named_lines, breeding_engine.next_event_id,
	)
	if error.is_empty():
		save_completed.emit(current_slot)
	else:
		save_failed.emit(error)

func delete_archive(archive_id: int) -> String:
	if archive_id == current_slot:
		has_game = false
		busy = false
		autosave_pending = false
	return save_service.delete_archive(archive_id)

func autosave() -> void:
	if autosave_pending:
		return
	autosave_pending = true
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		autosave_pending = false
		save_current()
	)

func load_game(slot_index: int) -> String:
	var loaded := save_service.load_slot(slot_index)
	var error := String(loaded.get("error", "未知载入错误"))
	if not error.is_empty():
		return error
	var manifest: Dictionary = loaded["manifest"]
	run_seed = int(manifest["run_seed"])
	current_slot = slot_index
	current_slot_name = String(manifest.get("slot_name", "育种计划"))
	_initialize_services()
	for genome_ref: int in loaded["genomes"]:
		genome_store.put(genome_ref, loaded["genomes"][genome_ref])
	for plant: PlantRecord in loaded["plants"]:
		var plant_error := plant_store.add(plant)
		if not plant_error.is_empty(): return plant_error
	plant_store.next_plant_id = int(manifest["next_plant_id"])
	breeding_engine.next_event_id = int(manifest["next_event_id"])
	var progress_state: Dictionary = manifest.get("task_state", {})
	if progress_state.has("tasks"):
		task_service.restore(progress_state.get("tasks", {}))
		tutorial_service.restore(progress_state.get("tutorial", {}))
	else:
		# 兼容首版三槽存档。
		task_service.restore(progress_state)
		tutorial_service.start(task_service.mode == &"tasks")
	breeding_engine.mutation_enabled = task_service.mode == &"sandbox"
	_restore_events(loaded.get("events", []))
	_restore_trials(loaded.get("trials", []))
	_restore_mutations(loaded.get("mutations", []))
	_restore_research(loaded.get("research", []))
	_restore_named_lines(manifest.get("named_lines", []))
	current_population = plant_store.all_plants()
	candidates = current_population.slice(maxi(0, current_population.size() - 20))
	has_game = true
	game_ready.emit()
	state_changed.emit()
	return ""

func _restore_events(items: Array) -> void:
	for data: Dictionary in items:
		var event := BreedingEvent.new()
		event.id = int(data["id"])
		event.type = int(data["type"]) as BreedingEvent.Type
		event.parent_a_id = int(data["parent_a_id"])
		event.parent_b_id = int(data["parent_b_id"])
		event.offspring_ids.assign(data.get("offspring_ids", []))
		event.note = String(data.get("note", ""))
		events.append(event)

func _restore_trials(items: Array) -> void:
	for data: Dictionary in items:
		var trial := TrialRecord.new()
		trial.id = int(data["id"])
		trial.environment_code = StringName(data["environment_code"])
		trial.replicate_count = int(data["replicate_count"])
		trial.plant_ids.assign(data.get("plant_ids", []))
		for observation_data: Dictionary in data.get("observations", []):
			var observation := PhenotypeObservation.new()
			observation.plant_id = int(observation_data.get("plant_id", 0))
			observation.environment_code = StringName(observation_data["environment_code"])
			observation.replicate_id = int(observation_data.get("replicate_id", 0))
			observation.expected_yield_g = float(observation_data.get("expected_yield_g", 0.0))
			observation.yield_g = float(observation_data.get("yield_g", 0.0))
			observation.height_cm = float(observation_data.get("height_cm", 0.0))
			observation.maturity_days = float(observation_data.get("maturity_days", 0.0))
			observation.seed_mass_mg = float(observation_data.get("seed_mass_mg", 0.0))
			observation.drought_score = float(observation_data.get("drought_score", 0.0))
			observation.heat_score = float(observation_data.get("heat_score", 0.0))
			observation.disease_score = float(observation_data.get("disease_score", 0.0))
			observation.quality_score = float(observation_data.get("quality_score", 0.0))
			trial.observations.append(observation)
		trial_service.trials.append(trial)
		trial_service.next_trial_id = maxi(trial_service.next_trial_id, trial.id + 1)

func _restore_mutations(items: Array) -> void:
	for data: Dictionary in items:
		var record := MutationRecord.new()
		record.id = int(data["id"])
		record.chromosome_id = int(data["chromosome_id"])
		record.position_cm = float(data["position_cm"])
		record.origin_plant_id = int(data["origin_plant_id"])
		record.origin_generation = int(data["origin_generation"])
		record.locus_id = int(data["locus_id"])
		record.new_allele_id = int(data["new_allele_id"])
		record.trait_effects = data.get("trait_effects", {})
		record.dominance_effects = data.get("dominance_effects", {})
		mutation_service.records.append(record)
		mutation_service.next_mutation_id = maxi(mutation_service.next_mutation_id, record.id + 1)
		genetics_engine.register_mutation(record)

func _restore_research(items: Array) -> void:
	for data: Dictionary in items:
		var finding := ResearchFinding.new()
		finding.locus_id = int(data["locus_id"])
		finding.trait_code = StringName(data["trait_code"])
		finding.reveal_level = int(data["reveal_level"]) as ResearchFinding.RevealLevel
		finding.confidence = float(data["confidence"])
		finding.interval_start_cm = float(data["interval_start_cm"])
		finding.interval_end_cm = float(data["interval_end_cm"])
		finding.effect_direction = int(data["effect_direction"])
		research_service.findings[finding.locus_id] = finding

func _restore_named_lines(items: Array) -> void:
	for data: Dictionary in items:
		var line := NamedLine.new()
		line.id = int(data["id"])
		line.line_name = String(data["line_name"])
		line.plant_id = int(data["plant_id"])
		line.homozygosity = float(data["homozygosity"])
		line.created_event_id = int(data["created_event_id"])
		named_lines.append(line)

func _plant_ids(plants: Array[PlantRecord]) -> Array[int]:
	var ids: Array[int] = []
	for plant: PlantRecord in plants:
		ids.append(plant.id)
	return ids
