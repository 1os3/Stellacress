class_name SpeciesDefinition
extends Resource

@export var definition_version: int = 1
@export var code: StringName = &"stellacress"
@export var display_name: String = "星芥"
@export var chromosomes: Array[ChromosomeDefinition] = []
@export var loci: Array[LocusDefinition] = []
@export var founders: Array[FounderDefinition] = []
@export var environments: Array[EnvironmentDefinition] = []
@export var base_profile: Dictionary = {}
@export var epistasis_rules: Array[Dictionary] = []
@export var known_mutation_rate: float = 0.0002
@export var novel_qtl_mutation_rate: float = 0.00002

var _locus_by_code: Dictionary = {}
var _locus_by_id: Dictionary = {}
var _chromosome_by_id: Dictionary = {}
var _founder_by_id: Dictionary = {}
var _environment_by_code: Dictionary = {}

func build_indexes() -> void:
	_locus_by_code.clear()
	_locus_by_id.clear()
	_chromosome_by_id.clear()
	_founder_by_id.clear()
	_environment_by_code.clear()
	for chromosome: ChromosomeDefinition in chromosomes:
		_chromosome_by_id[chromosome.id] = chromosome
	for locus: LocusDefinition in loci:
		_locus_by_code[locus.code] = locus
		_locus_by_id[locus.id] = locus
	for founder: FounderDefinition in founders:
		_founder_by_id[founder.id] = founder
	for environment: EnvironmentDefinition in environments:
		_environment_by_code[environment.code] = environment

func locus_by_code(locus_code: StringName) -> LocusDefinition:
	return _locus_by_code.get(locus_code) as LocusDefinition

func locus_by_id(locus_id: int) -> LocusDefinition:
	return _locus_by_id.get(locus_id) as LocusDefinition

func chromosome_by_id(chromosome_id: int) -> ChromosomeDefinition:
	return _chromosome_by_id.get(chromosome_id) as ChromosomeDefinition

func founder_by_id(founder_id: int) -> FounderDefinition:
	return _founder_by_id.get(founder_id) as FounderDefinition

func environment_by_code(environment_code: StringName) -> EnvironmentDefinition:
	return _environment_by_code.get(environment_code) as EnvironmentDefinition

func validate_definition() -> PackedStringArray:
	build_indexes()
	var errors := PackedStringArray()
	if chromosomes.size() != 3:
		errors.append("星芥必须恰好定义 3 条染色体")
	if loci.size() != 48:
		errors.append("星芥首版必须恰好定义 48 个位点")
	if founders.size() != 4:
		errors.append("星芥首版必须恰好定义 4 个创始纯系")
	for chromosome: ChromosomeDefinition in chromosomes:
		var chromosome_error := chromosome.validate_definition()
		if not chromosome_error.is_empty():
			errors.append(chromosome_error)
	for locus: LocusDefinition in loci:
		var chromosome := chromosome_by_id(locus.chromosome_id)
		if chromosome == null:
			errors.append("%s 引用了不存在的染色体 %d" % [locus.code, locus.chromosome_id])
			continue
		var locus_error := locus.validate_definition(chromosome.length_cm)
		if not locus_error.is_empty():
			errors.append(locus_error)
	for environment: EnvironmentDefinition in environments:
		var environment_error := environment.validate_definition()
		if not environment_error.is_empty():
			errors.append(environment_error)
	return errors
