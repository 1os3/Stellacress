class_name SpeciesFactory
extends RefCounted

const DATA_PATH: String = "res://data/species/stellacress.json"

static func load_stellacress(path: String = DATA_PATH) -> SpeciesDefinition:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("无法读取物种定义：%s（错误 %d）" % [path, FileAccess.get_open_error()])
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("物种定义不是有效 JSON 对象：%s" % path)
		return null
	var data: Dictionary = parsed
	var species := SpeciesDefinition.new()
	species.definition_version = int(data.get("definition_version", 1))
	species.base_profile = (data.get("base_profile", {}) as Dictionary).duplicate(true)
	for chromosome_data: Dictionary in data.get("chromosomes", []):
		var chromosome := ChromosomeDefinition.new()
		chromosome.id = int(chromosome_data["id"])
		chromosome.code = StringName(chromosome_data["code"])
		chromosome.length_cm = float(chromosome_data["length_cm"])
		species.chromosomes.append(chromosome)
	var next_locus_id := 1
	for locus_data: Dictionary in data.get("major_loci", []):
		var locus := _make_locus(locus_data, next_locus_id, LocusDefinition.Kind.MAJOR)
		species.loci.append(locus)
		next_locus_id += 1
	for locus_data: Dictionary in data.get("qtl_loci", []):
		var locus := _make_locus(locus_data, next_locus_id, LocusDefinition.Kind.QTL)
		locus.hidden_until_researched = true
		species.loci.append(locus)
		next_locus_id += 1
	species.build_indexes()
	for founder_data: Dictionary in data.get("founders", []):
		var founder := FounderDefinition.new()
		founder.id = int(founder_data["id"])
		founder.code = StringName(founder_data["code"])
		founder.display_name = String(founder_data["name"])
		founder.description = String(founder_data["description"])
		founder.color = Color.from_string(String(founder_data["color"]), Color.WHITE)
		var major: Dictionary = founder_data.get("major", {})
		for locus_code: String in major:
			var locus := species.locus_by_code(StringName(locus_code))
			if locus != null:
				founder.alleles[locus.id] = int(major[locus_code])
		for qtl_code: String in founder_data.get("qtl", []):
			var locus := species.locus_by_code(StringName(qtl_code))
			if locus != null:
				founder.alleles[locus.id] = 1
		species.founders.append(founder)
	for environment_data: Dictionary in data.get("environments", []):
		species.environments.append(_make_environment(environment_data))
	for rule_data: Dictionary in data.get("epistasis_rules", []):
		species.epistasis_rules.append(rule_data.duplicate(true))
	species.build_indexes()
	for chromosome: ChromosomeDefinition in species.chromosomes:
		var ids := PackedInt32Array()
		var chromosome_loci := species.loci.filter(func(locus: LocusDefinition) -> bool: return locus.chromosome_id == chromosome.id)
		chromosome_loci.sort_custom(func(a: LocusDefinition, b: LocusDefinition) -> bool: return a.position_cm < b.position_cm)
		for locus: LocusDefinition in chromosome_loci:
			ids.append(locus.id)
		chromosome.locus_ids_sorted = ids
	var errors := species.validate_definition()
	if not errors.is_empty():
		for error: String in errors:
			push_error("%s: %s" % [path, error])
		return null
	return species

static func _make_locus(data: Dictionary, locus_id: int, kind: LocusDefinition.Kind) -> LocusDefinition:
	var locus := LocusDefinition.new()
	locus.id = locus_id
	locus.code = StringName(data["code"])
	locus.chromosome_id = int(data["chr"])
	locus.position_cm = float(data["position_cm"])
	locus.kind = kind
	var labels: Array = data.get("alleles", ["0", "1"])
	locus.allele_labels = PackedStringArray(labels)
	locus.effect_allele = 1
	locus.additive_effects = (data.get("add", {}) as Dictionary).duplicate(true)
	locus.dominance_effects = (data.get("dominance", {}) as Dictionary).duplicate(true)
	locus.genotype_effects = (data.get("genotype_effects", {}) as Dictionary).duplicate(true)
	locus.categories = PackedStringArray(data.get("categories", []))
	return locus

static func _make_environment(data: Dictionary) -> EnvironmentDefinition:
	var environment := EnvironmentDefinition.new()
	environment.id = int(data["id"])
	environment.code = StringName(data["code"])
	environment.display_name = String(data["name"])
	environment.season_length_days = float(data["season"])
	environment.water_stress = float(data["water"])
	environment.heat_stress = float(data["heat"])
	environment.pathogen_a_pressure = float(data["path_a"])
	environment.pathogen_b_pressure = float(data["path_b"])
	environment.harvest_delay = float(data["delay"])
	environment.density_stress = float(data.get("density", 0.2))
	return environment
