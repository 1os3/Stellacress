class_name GenomeStore
extends RefCounted

var _genomes: Dictionary = {}
var _next_ref: int = 1

func add(genome: Genome) -> int:
	var genome_ref := _next_ref
	_next_ref += 1
	_genomes[genome_ref] = genome
	return genome_ref

func put(genome_ref: int, genome: Genome) -> void:
	_genomes[genome_ref] = genome
	_next_ref = maxi(_next_ref, genome_ref + 1)

func get_genome(genome_ref: int) -> Genome:
	return _genomes.get(genome_ref) as Genome

func all_refs() -> Array:
	var refs := _genomes.keys()
	refs.sort()
	return refs

func clear() -> void:
	_genomes.clear()
	_next_ref = 1
