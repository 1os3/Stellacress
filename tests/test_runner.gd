extends SceneTree

const SAMPLE_COUNT: int = 100000

var failures: PackedStringArray = []
var assertions: int = 0
var species: SpeciesDefinition
var genetics: GeneticsEngine
var meiosis: MeiosisEngine

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("Stellacress headless regression suite")
	species = SpeciesFactory.load_stellacress()
	_expect(species != null, "物种定义可加载")
	if species == null:
		_finish()
		return
	genetics = GeneticsEngine.new(species)
	meiosis = MeiosisEngine.new(species)
	_test_definitions()
	_test_mendelian_f1()
	_test_self_segregation()
	_test_six_cm_recombination()
	_test_independent_assortment()
	_test_segments_and_ancestry()
	_test_determinism()
	_test_phenotypes()
	_test_research()
	_test_mutations()
	_test_task_rules()
	_test_tutorial_state()
	_test_tutorial_catalog()
	_test_custom_genome()
	_test_save_roundtrip()
	_test_unlimited_archives_and_delete()
	_test_app_save_restore()
	await _test_scene_smoke()
	_finish()

func _test_definitions() -> void:
	_expect(species.chromosomes.size() == 3, "定义 3 条染色体")
	_expect(species.loci.size() == 48, "定义 18 主效基因 + 30 QTL")
	_expect(species.founders.size() == 4, "定义 4 个创始纯系")
	_expect(species.environments.size() == 4, "定义 E0–E3 环境")
	for founder: FounderDefinition in species.founders:
		var genome := GenomeFactory.create_founder_genome(species, founder)
		_expect(genome.validate_genome(species).is_empty(), "%s Genome 满足不变量" % founder.code)

func _test_mendelian_f1() -> void:
	var gold := GenomeFactory.create_founder_genome(species, species.founder_by_id(1))
	var sand := GenomeFactory.create_founder_genome(species, species.founder_by_id(2))
	var yld1 := species.locus_by_code(&"YLD1")
	for index: int in 1000:
		var gamete_a := meiosis.make_gamete(gold, SeedContract.make_rng(11, 1, index, 0))
		var gamete_b := meiosis.make_gamete(sand, SeedContract.make_rng(11, 1, index, 1))
		var dosage := int(genetics.get_allele(gamete_a.haplotype_for(1), yld1) == 1) + int(genetics.get_allele(gamete_b.haplotype_for(1), yld1) == 1)
		if dosage != 1:
			_expect(false, "AA × aa 的后代全部为 Aa")
			return
	_expect(true, "AA × aa 的 1000 个后代全部为 Aa")

func _test_self_segregation() -> void:
	var f1 := _gold_sand_f1()
	var yld1 := species.locus_by_code(&"YLD1")
	var counts := PackedInt32Array([0, 0, 0])
	for index: int in SAMPLE_COUNT:
		var gamete_a := meiosis.make_gamete(f1, SeedContract.make_rng(23, 2, index, 0))
		var gamete_b := meiosis.make_gamete(f1, SeedContract.make_rng(23, 2, index, 1))
		var dosage := int(genetics.get_allele(gamete_a.haplotype_for(1), yld1) == 1) + int(genetics.get_allele(gamete_b.haplotype_for(1), yld1) == 1)
		counts[dosage] += 1
	var frequencies := Vector3(float(counts[0]), float(counts[1]), float(counts[2])) / float(SAMPLE_COUNT)
	_expect(absf(frequencies.x - 0.25) < 0.006 and absf(frequencies.y - 0.50) < 0.008 and absf(frequencies.z - 0.25) < 0.006, "Aa 自交符合 1:2:1（%s）" % frequencies)

func _test_six_cm_recombination() -> void:
	var f1 := _gold_sand_f1()
	var yld1 := species.locus_by_code(&"YLD1")
	var hgt := species.locus_by_code(&"HGT")
	var recombinant := 0
	for index: int in SAMPLE_COUNT:
		var gamete := meiosis.make_gamete(f1, SeedContract.make_rng(37, 3, index, 0))
		var hap := gamete.haplotype_for(1)
		var y := genetics.get_allele(hap, yld1)
		var t := genetics.get_allele(hap, hgt)
		if y != t:
			recombinant += 1
	var rate := float(recombinant) / float(SAMPLE_COUNT)
	_expect(absf(rate - 0.0565) <= 0.0030, "6 cM 重组率 %.4f 接近 0.0565" % rate)

func _test_independent_assortment() -> void:
	var f1 := _gold_sand_f1()
	var yld1 := species.locus_by_code(&"YLD1")
	var dry := species.locus_by_code(&"DRY")
	var differing := 0
	for index: int in SAMPLE_COUNT:
		var gamete := meiosis.make_gamete(f1, SeedContract.make_rng(41, 4, index, 0))
		if genetics.get_allele(gamete.haplotype_for(1), yld1) != genetics.get_allele(gamete.haplotype_for(2), dry):
			differing += 1
	var rate := float(differing) / float(SAMPLE_COUNT)
	_expect(absf(rate - 0.5) < 0.006, "不同染色体独立分配（%.4f）" % rate)

func _test_segments_and_ancestry() -> void:
	var stores := _make_founder_stores()
	var plant_store: PlantStore = stores[0]
	var genome_store: GenomeStore = stores[1]
	var breeder := BreedingEngine.new(species, plant_store, genome_store, 77)
	breeder.next_event_id = 10
	var children := breeder.generate_population(plant_store.get_plant(1), plant_store.get_plant(2), 1000, breeder.begin_event())
	for child: PlantRecord in children:
		var genome := genome_store.get_genome(child.genome_ref)
		if not genome.validate_genome(species).is_empty():
			_expect(false, "随机重组 Genome 始终满足 Segment 不变量")
			return
	var pedigree := PedigreeService.new(species, plant_store, genome_store)
	var ancestry := pedigree.genome_ancestry(children[-1].id)
	var total := 0.0
	for proportion: float in ancestry.values(): total += proportion
	_expect(absf(total - 1.0) <= 0.000001, "祖源比例之和为 1")
	_expect(pedigree.get_ancestors(children[-1].id, 10).size() == 2, "父母可由谱系查询")

func _test_determinism() -> void:
	var f1 := _gold_sand_f1()
	var rng_a := SeedContract.make_rng(99, 8, 321, 0)
	var rng_b := SeedContract.make_rng(99, 8, 321, 0)
	var gamete_a := meiosis.make_gamete(f1, rng_a)
	var gamete_b := meiosis.make_gamete(f1, rng_b)
	_expect(_gamete_signature(gamete_a) == _gamete_signature(gamete_b), "相同种子合同生成字段级相同的配子")
	_expect(SeedContract.hash_v1(99, 8, 321, 0) == SeedContract.hash_v1(99, 8, 321, 0), "hash_v1 稳定")

func _test_phenotypes() -> void:
	var sand_genome := GenomeFactory.create_founder_genome(species, species.founder_by_id(2))
	var profile := genetics.build_genetic_profile(sand_genome)
	var engine := PhenotypeEngine.new(species)
	var e0 := engine.expected_phenotype(profile, species.environment_by_code(&"E0"))
	var e1 := engine.expected_phenotype(profile, species.environment_by_code(&"E1"))
	_expect(e1.expected_yield_g < e0.expected_yield_g, "水分与短季压力不会提高同基因型产量")
	var iron_profile := genetics.build_genetic_profile(GenomeFactory.create_founder_genome(species, species.founder_by_id(3)))
	var frt := species.locus_by_code(&"FRT")
	var ff_value := float((frt.genotype_effects["0"]["set"] as Dictionary)["fertility_factor"])
	_expect(absf(ff_value - 0.65) < 0.000001 and genetics.allele_dosage(GenomeFactory.create_founder_genome(species, species.founder_by_id(3)), frt) == 0, "FRT=ff 的基础结实倍率为 0.65（QTL 可继续修饰）")
	var hot_profile := profile
	var non_hot_profile := genetics.build_genetic_profile(GenomeFactory.create_founder_genome(species, species.founder_by_id(1)))
	var e2 := species.environment_by_code(&"E2")
	_expect(engine.expected_phenotype(hot_profile, e2).expected_yield_g > 0.0 and hot_profile.value(&"heat_score") > non_hot_profile.value(&"heat_score"), "HOT 在热环境提供更高耐热潜力")

func _test_research() -> void:
	var service := ResearchService.new(species)
	var trials: Array[TrialRecord] = []
	for environment_index: int in 3:
		var trial := TrialRecord.new()
		trial.id = environment_index + 1
		trial.environment_code = StringName("E%d" % environment_index)
		for plant_id: int in range(1, 101): trial.plant_ids.append(plant_id)
		trials.append(trial)
	service.update_from_trials(trials)
	_expect(service.reveal_level_for(species.locus_by_code(&"Q01").id) == ResearchFinding.RevealLevel.IDENTIFIED, "100 株 × 3 环境解锁 QTL 标签")

func _test_mutations() -> void:
	var original_known := species.known_mutation_rate
	var original_novel := species.novel_qtl_mutation_rate
	species.known_mutation_rate = 0.0
	species.novel_qtl_mutation_rate = 1.0
	var engine := GeneticsEngine.new(species)
	var service := MutationService.new(species, engine)
	var genome := GenomeFactory.create_founder_genome(species, species.founder_by_id(1))
	var gamete := meiosis.make_gamete(genome, SeedContract.make_rng(3, 3, 3, 3))
	var records := service.apply_to_gamete(gamete, SeedContract.make_rng(4, 4, 4, 4), 10, 2)
	_expect(records.size() == 1 and records[0].locus_id == -1, "新生 QTL 以稀疏 Variant 和 MutationRecord 登记")
	var found_variant := false
	for haplotype: Haplotype in gamete.chromosomes:
		for variant: VariantOverride in haplotype.variants:
			if variant.mutation_id == records[0].id: found_variant = true
	_expect(found_variant, "新生 QTL 附着于发生突变的配子区间")
	species.known_mutation_rate = original_known
	species.novel_qtl_mutation_rate = original_novel

func _test_task_rules() -> void:
	var stores := _make_founder_stores()
	var plant_store: PlantStore = stores[0]
	var genome_store: GenomeStore = stores[1]
	var local_genetics := GeneticsEngine.new(species)
	var trial_service := TrialService.new(species, local_genetics, genome_store, 10)
	var pedigree := PedigreeService.new(species, plant_store, genome_store)
	var task_service := TaskService.new(species, local_genetics, pedigree, trial_service, plant_store, genome_store)
	var task_a_genome := GenomeFactory.create_founder_genome(species, species.founder_by_id(1))
	_set_locus_allele(task_a_genome, species.locus_by_code(&"HGT"), 0)
	var task_a_plant := PlantRecord.new(plant_store.allocate_id())
	task_a_plant.parent_a_id = 1; task_a_plant.parent_b_id = 2; task_a_plant.genome_ref = genome_store.add(task_a_genome)
	plant_store.add(task_a_plant)
	var line_a := NamedLine.new(); line_a.id = 1; line_a.plant_id = task_a_plant.id; line_a.line_name = "YT 解锁系"; line_a.homozygosity = 1.0
	var lines: Array[NamedLine] = [line_a]
	task_service.evaluate(lines)
	_expect(bool(task_service.completed["A"]), "任务 A 识别 YY/tt 稳定品系")
	var task_b_genome := GenomeFactory.create_founder_genome(species, species.founder_by_id(1))
	_set_locus_allele(task_b_genome, species.locus_by_code(&"RES2"), 1)
	var task_b_plant := PlantRecord.new(plant_store.allocate_id())
	task_b_plant.parent_a_id = 1; task_b_plant.parent_b_id = 3; task_b_plant.genome_ref = genome_store.add(task_b_genome)
	plant_store.add(task_b_plant)
	var line_b := NamedLine.new(); line_b.id = 2; line_b.plant_id = task_b_plant.id; line_b.line_name = "抗病恢复系"; line_b.homozygosity = 1.0
	lines.append(line_b)
	task_service.evaluate(lines)
	_expect(bool(task_service.completed["B"]), "任务 B 识别 BB/FF/NN 且铁盾祖源不高于 10%")
	for environment_code: StringName in [&"E1", &"E2"]:
		var trial := TrialRecord.new(); trial.id = trial_service.next_trial_id; trial_service.next_trial_id += 1
		trial.environment_code = environment_code; trial.replicate_count = 3; trial.plant_ids = [task_a_plant.id, task_b_plant.id]
		for plant_id: int in trial.plant_ids:
			for replicate_id: int in 3:
				var observation := PhenotypeObservation.new(); observation.plant_id = plant_id; observation.environment_code = environment_code; observation.replicate_id = replicate_id
				observation.yield_g = 100.0 if (environment_code == &"E1" and plant_id == task_a_plant.id) or (environment_code == &"E2" and plant_id == task_b_plant.id) else 20.0
				trial.observations.append(observation)
		trial_service.trials.append(trial)
	task_service.evaluate(lines)
	_expect(bool(task_service.completed["C"]), "任务 C 要求 E1/E2 由不同稳定品系获胜")

func _set_locus_allele(genome: Genome, locus: LocusDefinition, allele_id: int) -> void:
	for use_a: bool in [true, false]:
		var haplotype := genome.haplotype_for(locus.chromosome_id, use_a)
		haplotype.variants.append(VariantOverride.new(locus.position_cm, locus.id, allele_id, 0))

func _test_tutorial_state() -> void:
	var tutorial := TutorialService.new()
	tutorial.start(true)
	tutorial.next_step()
	tutorial.advance_to(4)
	var state := tutorial.state()
	var restored := TutorialService.new()
	restored.restore(state)
	_expect(restored.enabled and restored.step_index == 4 and String(restored.current_step()["title"]).contains("染色体"), "教程步骤可推进并随档案恢复")
	restored.close()
	_expect(not restored.enabled, "新手引导可关闭并从顶部按钮重新打开")

func _test_tutorial_catalog() -> void:
	var required_codes: Array[StringName] = [&"overview", &"genetics_basics", &"chromosome_map", &"breeding_operations", &"genes_qtl", &"phenotype_environment", &"selection", &"trials_research", &"pedigree_ancestry", &"standard_tasks", &"genome_workshop", &"mutations", &"archives_determinism"]
	_expect(TutorialCatalog.TOPICS.size() >= required_codes.size(), "教程百科覆盖概念、玩法、工具和系统说明")
	for code: StringName in required_codes:
		_expect(not TutorialCatalog.topic_by_code(code).is_empty(), "教程百科包含 %s" % code)
	var workshop_topic := TutorialCatalog.topic_by_code(&"genome_workshop")
	var workshop_content := String(workshop_topic.get("content", ""))
	_expect(workshop_content.contains("同源 A") and workshop_content.contains("Variant Override") and workshop_content.contains("纯合") and workshop_content.contains("杂合"), "基因组工坊教程解释 A/B、Variant、纯合与杂合")
	_expect(TutorialCatalog.topics("QTL").size() >= 2, "教程百科支持全文与关键词搜索")

func _test_custom_genome() -> void:
	var base := species.founder_by_id(1)
	var hgt := species.locus_by_code(&"HGT")
	var custom := GenomeFactory.create_custom_genome(species, base, {hgt.id: 0}, {hgt.id: 1})
	_expect(custom.validate_genome(species).is_empty(), "自定义 Genome 满足 Segment 与二倍体不变量")
	_expect(genetics.allele_dosage(custom, hgt) == 1, "基因组工坊可创建 HGT=T/t 杂合材料")
	_expect(genetics.homozygosity(custom) < 1.0, "A/B 独立编辑会正确降低纯合度")

func _test_save_roundtrip() -> void:
	var stores := _make_founder_stores()
	var plant_store: PlantStore = stores[0]
	var genome_store: GenomeStore = stores[1]
	genome_store.get_genome(1).homolog_a[0].variants.append(VariantOverride.new(2.0, -1, 1, 12))
	var service := SaveService.new(species, "res://tests/tmp/saves")
	var error := service.save_slot(1, "自动化测试", 1234, {"mode":"tasks","completed":{"A":false,"B":false,"C":false}}, plant_store, genome_store, [], [], [], {}, [], 1)
	_expect(error.is_empty(), "项目内测试存档可写入：%s" % error)
	var loaded := service.load_slot(1)
	_expect(String(loaded.get("error", "")) == "", "存档可完整读取")
	if String(loaded.get("error", "")) == "":
		_expect((loaded["plants"] as Array).size() == 4 and (loaded["genomes"] as Dictionary).size() == 4, "存档往返保留四创始系")
		var loaded_genome: Genome = loaded["genomes"][1]
		_expect(loaded_genome.validate_genome(species).is_empty(), "读取的 Genome 满足不变量")
		_expect(loaded_genome.homolog_a[0].variants[0].locus_id == -1, "新生 QTL 的 locus_id=-1 可二进制往返")

func _test_unlimited_archives_and_delete() -> void:
	var stores := _make_founder_stores()
	var plant_store: PlantStore = stores[0]
	var genome_store: GenomeStore = stores[1]
	var service := SaveService.new(species, "res://tests/tmp/unlimited_archives")
	for archive_id: int in [1, 4, 12]:
		var error := service.save_slot(archive_id, "档案 %d" % archive_id, archive_id, {}, plant_store, genome_store, [], [], [], {}, [], 1)
		_expect(error.is_empty(), "可创建不限于三槽的档案 #%d" % archive_id)
	var summaries := service.archive_summaries()
	_expect(summaries.size() >= 3 and service.allocate_archive_id() > 12, "档案列表动态扫描并分配无上限 ID")
	var delete_error := service.delete_archive(12)
	_expect(delete_error.is_empty(), "档案可经确认流程安全删除")
	var still_exists := false
	for summary: Dictionary in service.archive_summaries():
		if int(summary["slot"]) == 12: still_exists = true
	_expect(not still_exists, "删除后的档案不再出现在列表")

func _test_app_save_restore() -> void:
	var app := root.get_node_or_null("AppController")
	_expect(app != null, "AppController Autoload 存在")
	if app == null: return
	var app_save_service := app.get("save_service") as SaveService
	app_save_service.storage_root = "res://tests/tmp/app_saves"
	app.call("new_game", &"tasks", 5678, 2, "集成存档")
	var hgt := species.locus_by_code(&"HGT")
	var custom_result: Dictionary = app.call("create_custom_material", "杂合测试材料", 1, {hgt.id: 0}, {hgt.id: 1})
	_expect(String(custom_result.get("error", "")) == "", "应用层可创建自定义杂合亲本材料")
	var custom_plant_id := int(custom_result.get("plant_id", 0))
	app.call("generate_population", 1, 2, 10, &"cross")
	var trial_plant_ids: Array[int] = [1]
	var trial: TrialRecord = app.call("run_trial_for", trial_plant_ids, &"E0", 3) as TrialRecord
	_expect(trial != null and trial.observations.size() == 3, "应用层可运行三重复试验")
	var line_error := String(app.call("name_line", 1, "测试稳定系"))
	_expect(line_error.is_empty(), "纯合创始材料经试验后可命名稳定品系")
	app.call("save_current")
	var load_error := String(app.call("load_game", 2))
	_expect(load_error.is_empty(), "带试验、研究和命名品系的应用存档可恢复：%s" % load_error)
	if load_error.is_empty():
		var restored_trial_service := app.get("trial_service") as TrialService
		var restored_lines: Array = app.get("named_lines")
		var restored_events: Array = app.get("events")
		var restored_plant_store := app.get("plant_store") as PlantStore
		var restored_tutorial := app.get("tutorial_service") as TutorialService
		_expect(restored_trial_service.trials.size() == 1 and restored_lines.size() == 1, "应用存档恢复试验和命名品系")
		_expect(restored_events.size() == 1 and restored_plant_store.size() == 15, "应用存档恢复育种事件、自定义材料和全部后代")
		var restored_genome_store := app.get("genome_store") as GenomeStore
		var restored_genetics := app.get("genetics_engine") as GeneticsEngine
		var restored_custom := restored_plant_store.get_plant(custom_plant_id)
		_expect(restored_custom != null and restored_genetics.allele_dosage(restored_genome_store.get_genome(restored_custom.genome_ref), hgt) == 1, "自定义杂合 Genome 可随档案往返")
		_expect(restored_tutorial.step_index >= 3, "应用存档恢复教程进度")

func _test_scene_smoke() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	_expect(scene != null, "主场景可加载")
	if scene != null:
		var instance := scene.instantiate()
		root.add_child(instance)
		await process_frame
		_expect(instance is Control, "主场景可实例化为 Control")
		instance.call("_open_tutorial_center", &"genome_workshop")
		await process_frame
		var center := instance.get("tutorial_center") as PanelContainer
		var article_title := instance.get("tutorial_article_title") as Label
		_expect(center.visible and article_title.text.contains("基因组工坊"), "教程百科可从上下文入口打开指定文章")
		instance.queue_free()

func _gold_sand_f1() -> Genome:
	var gold := GenomeFactory.create_founder_genome(species, species.founder_by_id(1))
	var sand := GenomeFactory.create_founder_genome(species, species.founder_by_id(2))
	var genome := Genome.new()
	for chromosome: ChromosomeDefinition in species.chromosomes:
		genome.homolog_a.append(gold.haplotype_for(chromosome.id, true).duplicate_haplotype())
		genome.homolog_b.append(sand.haplotype_for(chromosome.id, true).duplicate_haplotype())
	return genome

func _make_founder_stores() -> Array:
	var plant_store := PlantStore.new()
	var genome_store := GenomeStore.new()
	var breeder := BreedingEngine.new(species, plant_store, genome_store, 7)
	breeder.create_founders()
	return [plant_store, genome_store]

func _gamete_signature(gamete: Gamete) -> String:
	var parts := PackedStringArray()
	for haplotype: Haplotype in gamete.chromosomes:
		parts.append("C%d" % haplotype.chromosome_id)
		for segment: Segment in haplotype.segments:
			parts.append("%.2f:%d" % [segment.start_cm, segment.founder_haplotype_id])
	return "|".join(parts)

func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if condition:
		print("  PASS  ", message)
	else:
		failures.append(message)
		push_error("  FAIL  %s" % message)

func _finish() -> void:
	print("\n%d assertions, %d failures" % [assertions, failures.size()])
	if not failures.is_empty():
		for failure: String in failures: print(" - ", failure)
	quit(1 if not failures.is_empty() else 0)
