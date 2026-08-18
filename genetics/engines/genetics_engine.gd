class_name GeneticsEngine
extends RefCounted

var species: SpeciesDefinition
var mutation_records: Dictionary = {}

func _init(p_species: SpeciesDefinition) -> void:
	species = p_species

func get_allele(haplotype: Haplotype, locus: LocusDefinition) -> int:
	# 同一位点若经历连续突变，最后写入的 override 是当前事实源。
	for index: int in range(haplotype.variants.size() - 1, -1, -1):
		var variant := haplotype.variants[index]
		if variant.locus_id == locus.id:
			return variant.allele_id
	var founder_id := haplotype.ancestry_at(locus.position_cm)
	var founder := species.founder_by_id(founder_id)
	if founder == null:
		push_error("位点 %s 查询到了未知创始祖源 %d" % [locus.code, founder_id])
		return 0
	return founder.allele_at(locus.id)

func get_genotype(genome: Genome, locus: LocusDefinition) -> Vector2i:
	var haplotype_a := genome.haplotype_for(locus.chromosome_id, true)
	var haplotype_b := genome.haplotype_for(locus.chromosome_id, false)
	if haplotype_a == null or haplotype_b == null:
		return Vector2i(-1, -1)
	return Vector2i(get_allele(haplotype_a, locus), get_allele(haplotype_b, locus))

func allele_dosage(genome: Genome, locus: LocusDefinition, target_allele: int = -1) -> int:
	var target := locus.effect_allele if target_allele < 0 else target_allele
	var genotype := get_genotype(genome, locus)
	return int(genotype.x == target) + int(genotype.y == target)

func genotype_label(genome: Genome, locus: LocusDefinition) -> String:
	var genotype := get_genotype(genome, locus)
	if genotype.x < 0 or genotype.y < 0:
		return "?"
	return "%s%s" % [locus.allele_labels[genotype.x], locus.allele_labels[genotype.y]]

func homozygosity(genome: Genome) -> float:
	var homozygous := 0
	for locus: LocusDefinition in species.loci:
		var genotype := get_genotype(genome, locus)
		if genotype.x == genotype.y:
			homozygous += 1
	return float(homozygous) / float(maxi(1, species.loci.size()))

func qtl_effect(dosage: int, additive: float, dominance: float) -> float:
	return additive * float(dosage - 1) + (dominance if dosage == 1 else 0.0)

func build_genetic_profile(genome: Genome) -> GeneticProfile:
	var profile := GeneticProfile.new()
	profile.values = species.base_profile.duplicate(true)
	for locus: LocusDefinition in species.loci:
		var dosage := allele_dosage(genome, locus)
		if locus.kind == LocusDefinition.Kind.MAJOR:
			_apply_major_locus(profile, locus, dosage)
		elif locus.kind == LocusDefinition.Kind.QTL:
			for trait_code: String in locus.additive_effects:
				var additive := float(locus.additive_effects[trait_code])
				var dominance := float(locus.dominance_effects.get(trait_code, 0.0))
				profile.add_value(StringName(trait_code), qtl_effect(dosage, additive, dominance))
	_apply_epistasis(profile, genome)
	_apply_novel_mutations(profile, genome)
	_finalize_profile(profile)
	return profile

func register_mutation(record: MutationRecord) -> void:
	mutation_records[record.id] = record

func _apply_novel_mutations(profile: GeneticProfile, genome: Genome) -> void:
	var applied: Dictionary = {}
	for haplotype: Haplotype in genome.homolog_a + genome.homolog_b:
		for variant: VariantOverride in haplotype.variants:
			if variant.locus_id >= 0 or applied.has(variant.mutation_id):
				continue
			var record := mutation_records.get(variant.mutation_id) as MutationRecord
			if record == null:
				continue
			applied[record.id] = true
			for trait_code: String in record.trait_effects:
				profile.add_value(StringName(trait_code), float(record.trait_effects[trait_code]))

func _apply_major_locus(profile: GeneticProfile, locus: LocusDefinition, dosage: int) -> void:
	var bundle: Dictionary = locus.genotype_effects.get(str(dosage), {})
	for trait_code: String in bundle.get("add", {}):
		profile.add_value(StringName(trait_code), float(bundle["add"][trait_code]))
	for trait_code: String in bundle.get("multiply", {}):
		profile.multiply_value(StringName(trait_code), float(bundle["multiply"][trait_code]))
	for trait_code: String in bundle.get("set", {}):
		profile.set_value(StringName(trait_code), float(bundle["set"][trait_code]))
	if not locus.categories.is_empty() and dosage < locus.categories.size():
		if locus.code == &"CLR":
			profile.color_category = locus.categories[dosage]
		elif locus.code == &"ANT":
			profile.anthocyanin_category = locus.categories[dosage]

func _apply_epistasis(profile: GeneticProfile, genome: Genome) -> void:
	for rule: Dictionary in species.epistasis_rules:
		var matches := true
		for condition: Array in rule.get("conditions", []):
			var locus := species.locus_by_code(StringName(condition[0]))
			if locus == null or allele_dosage(genome, locus) < int(condition[1]):
				matches = false
				break
		if not matches:
			continue
		for trait_code: String in rule.get("add", {}):
			profile.add_value(StringName(trait_code), float(rule["add"][trait_code]))
		for trait_code: String in rule.get("multiply", {}):
			profile.multiply_value(StringName(trait_code), float(rule["multiply"][trait_code]))
		if rule.has("flag"):
			profile.flags[StringName(rule["flag"])] = true

func _finalize_profile(profile: GeneticProfile) -> void:
	for trait_code: StringName in [&"drought_score", &"heat_score", &"resistance_a", &"resistance_b", &"shatter_resistance", &"maturity_uniformity", &"quality_score", &"dormancy_score"]:
		profile.set_value(trait_code, clampf(profile.value(trait_code), 0.0, 100.0))
	profile.set_value(&"fertility_factor", clampf(profile.value(&"fertility_factor"), 0.0, 1.1))
	profile.set_value(&"seed_number_potential", maxf(0.0, profile.value(&"seed_number_potential")))
	profile.set_value(&"seed_mass_mg", maxf(0.1, profile.value(&"seed_mass_mg")))
