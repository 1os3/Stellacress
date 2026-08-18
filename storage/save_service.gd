class_name SaveService
extends RefCounted

const SAVE_FORMAT_VERSION: int = 1
const PRNG_ALGORITHM_VERSION: int = SeedContract.ALGORITHM_VERSION
const FILE_NAMES: PackedStringArray = ["plants.bin", "genomes.bin", "events.bin", "trials.bin", "mutations.bin", "research.bin"]

var species: SpeciesDefinition
var storage_root: String

func _init(p_species: SpeciesDefinition, p_storage_root: String = "user://saves") -> void:
	species = p_species
	storage_root = p_storage_root.trim_suffix("/")

func save_slot(
		slot_index: int,
		slot_name: String,
		run_seed: int,
		task_state: Dictionary,
		plant_store: PlantStore,
		genome_store: GenomeStore,
		events: Array[BreedingEvent],
		trials: Array[TrialRecord],
		mutations: Array[MutationRecord],
		research_findings: Dictionary,
		named_lines: Array[NamedLine],
		next_event_id: int,
) -> String:
	if slot_index < 1:
		return "档案 ID 必须大于 0"
	var slot_path := _slot_path(slot_index)
	var absolute_slot_path := ProjectSettings.globalize_path(slot_path)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_slot_path)
	if make_error != OK:
		return "无法创建存档目录：%s（错误 %d）" % [slot_path, make_error]
	var error := _write_plants(slot_path, plant_store)
	if not error.is_empty(): return error
	error = _write_genomes(slot_path, genome_store)
	if not error.is_empty(): return error
	error = _write_json_file(slot_path, "events.bin", events.map(func(event: BreedingEvent) -> Dictionary: return event.to_dictionary()))
	if not error.is_empty(): return error
	error = _write_json_file(slot_path, "trials.bin", trials.map(func(trial: TrialRecord) -> Dictionary: return trial.to_dictionary()))
	if not error.is_empty(): return error
	error = _write_json_file(slot_path, "mutations.bin", mutations.map(func(mutation: MutationRecord) -> Dictionary: return mutation.to_dictionary()))
	if not error.is_empty(): return error
	var research_data: Array[Dictionary] = []
	for finding: ResearchFinding in research_findings.values():
		research_data.append(finding.to_dictionary())
	error = _write_json_file(slot_path, "research.bin", research_data)
	if not error.is_empty(): return error
	var line_data: Array[Dictionary] = []
	for line: NamedLine in named_lines:
		line_data.append(line.to_dictionary())
	var manifest := {
		"save_format_version": SAVE_FORMAT_VERSION,
		"species_definition_version": species.definition_version,
		"prng_algorithm_version": PRNG_ALGORITHM_VERSION,
		"slot_name": slot_name,
		"updated_unix": int(Time.get_unix_time_from_system()),
		"run_seed": run_seed,
		"next_plant_id": plant_store.next_plant_id,
		"next_event_id": next_event_id,
		"task_state": task_state,
		"named_lines": line_data,
	}
	error = _write_text_atomic(slot_path.path_join("manifest.json"), JSON.stringify(manifest, "  "))
	return error

func load_slot(slot_index: int) -> Dictionary:
	var slot_path := _slot_path(slot_index)
	var manifest_path := slot_path.path_join("manifest.json")
	if not FileAccess.file_exists(manifest_path):
		return {"error": "存档槽 %d 为空" % slot_index}
	var manifest_variant: Variant = _read_json(manifest_path)
	if not manifest_variant is Dictionary:
		return {"error": "manifest.json 损坏"}
	var manifest: Dictionary = manifest_variant
	var version_error := _validate_manifest(manifest)
	if not version_error.is_empty():
		return {"error": version_error}
	for file_name: String in FILE_NAMES:
		if not FileAccess.file_exists(slot_path.path_join(file_name)):
			return {"error": "存档缺少 %s" % file_name}
	var plants_result := _read_plants(slot_path)
	if plants_result.has("error"): return plants_result
	var genomes_result := _read_genomes(slot_path)
	if genomes_result.has("error"): return genomes_result
	return {
		"error": "",
		"manifest": manifest,
		"plants": plants_result["plants"],
		"genomes": genomes_result["genomes"],
		"events": _read_json(slot_path.path_join("events.bin")),
		"trials": _read_json(slot_path.path_join("trials.bin")),
		"mutations": _read_json(slot_path.path_join("mutations.bin")),
		"research": _read_json(slot_path.path_join("research.bin")),
	}

func allocate_archive_id() -> int:
	var maximum_id := 0
	for summary: Dictionary in archive_summaries():
		maximum_id = maxi(maximum_id, int(summary["slot"]))
	return maximum_id + 1

func archive_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(storage_root)):
		return summaries
	var directory_names := DirAccess.get_directories_at(storage_root)
	for directory_name: String in directory_names:
		if not directory_name.begins_with("archive_") and not directory_name.begins_with("slot_"):
			continue
		var id_text := directory_name.trim_prefix("archive_").trim_prefix("slot_")
		if not id_text.is_valid_int():
			continue
		var slot_index := int(id_text)
		var path := storage_root.path_join(directory_name).path_join("manifest.json")
		if not FileAccess.file_exists(path):
			continue
		var manifest: Variant = _read_json(path)
		if manifest is Dictionary:
			summaries.append({"slot": slot_index, "empty": false, "name": manifest.get("slot_name", "未命名"), "updated_unix": manifest.get("updated_unix", 0)})
		else:
			summaries.append({"slot": slot_index, "empty": false, "name": "损坏的存档", "updated_unix": 0})
	summaries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("updated_unix", 0)) > int(b.get("updated_unix", 0)))
	return summaries

func slot_summaries() -> Array[Dictionary]:
	return archive_summaries()

func delete_archive(archive_id: int) -> String:
	if archive_id < 1:
		return "档案 ID 无效"
	var archive_path := _slot_path(archive_id)
	var root_absolute := ProjectSettings.globalize_path(storage_root).simplify_path().replace("\\", "/").trim_suffix("/")
	var target_absolute := ProjectSettings.globalize_path(archive_path).simplify_path().replace("\\", "/").trim_suffix("/")
	if target_absolute == root_absolute or not target_absolute.begins_with(root_absolute + "/"):
		return "拒绝删除存档根目录以外的路径"
	if not DirAccess.dir_exists_absolute(target_absolute):
		return "档案不存在"
	var error := _remove_directory_tree(target_absolute)
	return "" if error == OK else "删除档案失败（错误 %d）" % error

func _remove_directory_tree(absolute_path: String) -> Error:
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return DirAccess.get_open_error()
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var entry_path := absolute_path.path_join(entry)
			var error := OK
			if directory.current_is_dir():
				error = _remove_directory_tree(entry_path)
			else:
				error = DirAccess.remove_absolute(entry_path)
			if error != OK:
				directory.list_dir_end()
				return error
		entry = directory.get_next()
	directory.list_dir_end()
	return DirAccess.remove_absolute(absolute_path)

func _write_plants(slot_path: String, plant_store: PlantStore) -> String:
	var target := slot_path.path_join("plants.bin")
	var temp := target + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return "无法写入 %s" % temp
	var plants := plant_store.all_plants()
	file.store_32(plants.size())
	for plant: PlantRecord in plants:
		file.store_64(plant.id)
		file.store_64(plant.parent_a_id)
		file.store_64(plant.parent_b_id)
		file.store_32(plant.generation)
		file.store_64(plant.birth_event_id)
		file.store_64(plant.genome_ref)
		file.store_64(plant.phenotype_summary_ref)
		file.store_8(1 if plant.is_founder else 0)
		file.store_pascal_string(plant.display_name)
	file.close()
	return _commit_temp(temp, target)

func _write_genomes(slot_path: String, genome_store: GenomeStore) -> String:
	var target := slot_path.path_join("genomes.bin")
	var temp := target + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return "无法写入 %s" % temp
	var refs := genome_store.all_refs()
	file.store_32(refs.size())
	for genome_ref: int in refs:
		file.store_64(genome_ref)
		var genome := genome_store.get_genome(genome_ref)
		for homologues: Array[Haplotype] in [genome.homolog_a, genome.homolog_b]:
			for haplotype: Haplotype in homologues:
				file.store_8(haplotype.chromosome_id)
				file.store_16(haplotype.segments.size())
				for segment: Segment in haplotype.segments:
					file.store_16(clampi(roundi(segment.start_cm * 100.0), 0, 65535))
					file.store_16(segment.founder_haplotype_id)
				file.store_16(haplotype.variants.size())
				for variant: VariantOverride in haplotype.variants:
					file.store_16(clampi(roundi(variant.position_cm * 100.0), 0, 65535))
					# 加一后写入无符号字段，使 novel QTL 的 -1 能无歧义往返。
					file.store_32(variant.locus_id + 1)
					file.store_16(variant.allele_id)
					file.store_64(variant.mutation_id)
	file.close()
	return _commit_temp(temp, target)

func _read_plants(slot_path: String) -> Dictionary:
	var file := FileAccess.open(slot_path.path_join("plants.bin"), FileAccess.READ)
	if file == null: return {"error": "无法读取 plants.bin"}
	var plants: Array[PlantRecord] = []
	var count := file.get_32()
	if count > 10000000: return {"error": "plants.bin 记录数异常"}
	for _index: int in count:
		var plant := PlantRecord.new(file.get_64())
		plant.parent_a_id = file.get_64()
		plant.parent_b_id = file.get_64()
		plant.generation = file.get_32()
		plant.birth_event_id = file.get_64()
		plant.genome_ref = file.get_64()
		plant.phenotype_summary_ref = file.get_64()
		plant.is_founder = file.get_8() == 1
		plant.display_name = file.get_pascal_string()
		plants.append(plant)
	return {"plants": plants}

func _read_genomes(slot_path: String) -> Dictionary:
	var file := FileAccess.open(slot_path.path_join("genomes.bin"), FileAccess.READ)
	if file == null: return {"error": "无法读取 genomes.bin"}
	var genomes: Dictionary = {}
	var count := file.get_32()
	if count > 10000000: return {"error": "genomes.bin 记录数异常"}
	for _index: int in count:
		var genome_ref := file.get_64()
		var genome := Genome.new()
		for homolog_index: int in 2:
			var target: Array[Haplotype] = genome.homolog_a if homolog_index == 0 else genome.homolog_b
			for _chromosome_index: int in species.chromosomes.size():
				var haplotype := Haplotype.new(file.get_8())
				var segment_count := file.get_16()
				for _segment_index: int in segment_count:
					haplotype.segments.append(Segment.new(float(file.get_16()) / 100.0, file.get_16()))
				var variant_count := file.get_16()
				for _variant_index: int in variant_count:
					haplotype.variants.append(VariantOverride.new(float(file.get_16()) / 100.0, file.get_32() - 1, file.get_16(), file.get_64()))
				target.append(haplotype)
		var genome_error := genome.validate_genome(species)
		if not genome_error.is_empty(): return {"error": "genomes.bin: %s" % genome_error}
		genomes[genome_ref] = genome
	return {"genomes": genomes}

func _write_json_file(slot_path: String, file_name: String, data: Variant) -> String:
	return _write_text_atomic(slot_path.path_join(file_name), JSON.stringify(data))

func _write_text_atomic(target: String, content: String) -> String:
	var temp := target + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return "无法写入 %s" % temp
	file.store_string(content)
	file.close()
	if _read_json(temp) == null:
		return "%s 写后校验失败" % temp
	return _commit_temp(temp, target)

func _commit_temp(temp: String, target: String) -> String:
	var absolute_temp := ProjectSettings.globalize_path(temp)
	var absolute_target := ProjectSettings.globalize_path(target)
	var absolute_backup := absolute_target + ".bak"
	if FileAccess.file_exists(target):
		if FileAccess.file_exists(target + ".bak"):
			DirAccess.remove_absolute(absolute_backup)
		var backup_error := DirAccess.rename_absolute(absolute_target, absolute_backup)
		if backup_error != OK: return "无法备份 %s（错误 %d）" % [target, backup_error]
	var rename_error := DirAccess.rename_absolute(absolute_temp, absolute_target)
	if rename_error != OK:
		if FileAccess.file_exists(target + ".bak"):
			DirAccess.rename_absolute(absolute_backup, absolute_target)
		return "无法提交 %s（错误 %d）" % [target, rename_error]
	return ""

func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return null
	return JSON.parse_string(file.get_as_text())

func _validate_manifest(manifest: Dictionary) -> String:
	if int(manifest.get("save_format_version", -1)) != SAVE_FORMAT_VERSION:
		return "不支持的存档格式版本"
	if int(manifest.get("species_definition_version", -1)) != species.definition_version:
		return "存档的物种定义版本与当前版本不一致"
	if int(manifest.get("prng_algorithm_version", -1)) != PRNG_ALGORITHM_VERSION:
		return "存档的随机算法版本与当前版本不一致"
	return ""

func _slot_path(slot_index: int) -> String:
	var archive_path := storage_root.path_join("archive_%d" % slot_index)
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(archive_path)):
		return archive_path
	var legacy_path := storage_root.path_join("slot_%d" % slot_index)
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(legacy_path)):
		return legacy_path
	return archive_path
