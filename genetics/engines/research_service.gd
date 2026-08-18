class_name ResearchService
extends RefCounted

var species: SpeciesDefinition
var findings: Dictionary = {}

func _init(p_species: SpeciesDefinition) -> void:
	species = p_species

func update_from_trials(trials: Array[TrialRecord]) -> Array[ResearchFinding]:
	var plant_ids: Dictionary = {}
	var environment_codes: Dictionary = {}
	for trial: TrialRecord in trials:
		environment_codes[trial.environment_code] = true
		for plant_id: int in trial.plant_ids:
			plant_ids[plant_id] = true
	var plant_count := plant_ids.size()
	var environment_count := environment_codes.size()
	var updated: Array[ResearchFinding] = []
	for locus: LocusDefinition in species.loci:
		if locus.kind != LocusDefinition.Kind.QTL:
			continue
		var finding: ResearchFinding = findings.get(locus.id) as ResearchFinding
		if finding == null:
			finding = ResearchFinding.new()
			finding.locus_id = locus.id
			finding.trait_code = StringName(locus.additive_effects.keys()[0]) if not locus.additive_effects.is_empty() else &"unknown"
			findings[locus.id] = finding
		var sample_factor := clampf(float(plant_count) / 100.0, 0.0, 1.0)
		var environment_factor := clampf(float(environment_count) / 3.0, 0.0, 1.0)
		finding.confidence = sample_factor * environment_factor
		if plant_count >= 100 and environment_count >= 3:
			finding.reveal_level = ResearchFinding.RevealLevel.IDENTIFIED
			finding.interval_start_cm = locus.position_cm
			finding.interval_end_cm = locus.position_cm
		elif plant_count >= 30 and environment_count >= 2:
			finding.reveal_level = ResearchFinding.RevealLevel.INTERVAL
			var chromosome := species.chromosome_by_id(locus.chromosome_id)
			finding.interval_start_cm = maxf(0.0, locus.position_cm - 6.0)
			finding.interval_end_cm = minf(chromosome.length_cm, locus.position_cm + 6.0)
		finding.effect_direction = signi(int(sign(float(locus.additive_effects.get(String(finding.trait_code), 0.0)))))
		updated.append(finding)
	return updated

func reveal_level_for(locus_id: int) -> ResearchFinding.RevealLevel:
	var finding: ResearchFinding = findings.get(locus_id) as ResearchFinding
	return finding.reveal_level if finding != null else ResearchFinding.RevealLevel.HIDDEN
