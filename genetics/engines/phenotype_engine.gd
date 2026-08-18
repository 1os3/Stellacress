class_name PhenotypeEngine
extends RefCounted

var species: SpeciesDefinition

func _init(p_species: SpeciesDefinition) -> void:
	species = p_species

func expected_phenotype(profile: GeneticProfile, environment: EnvironmentDefinition) -> PhenotypeObservation:
	var observation := PhenotypeObservation.new()
	observation.environment_code = environment.code
	var drought := profile.value(&"drought_score")
	var heat := profile.value(&"heat_score")
	var resistance_a := profile.value(&"resistance_a")
	var resistance_b := profile.value(&"resistance_b")
	var water_factor := clampf(1.0 - environment.water_stress * (0.75 - 0.0065 * drought), 0.20, 1.05)
	var heat_factor := clampf(1.0 - environment.heat_stress * (0.65 - 0.0055 * heat), 0.25, 1.05)
	var disease_a_factor := clampf(1.0 - environment.pathogen_a_pressure * (0.65 - 0.0055 * resistance_a), 0.25, 1.0)
	var disease_b_factor := clampf(1.0 - environment.pathogen_b_pressure * (0.65 - 0.0055 * resistance_b), 0.25, 1.0)
	var maturity_days := profile.value(&"maturity_days")
	var season_factor := 1.0
	if maturity_days > environment.season_length_days:
		season_factor = maxf(0.20, 1.0 - 0.06 * (maturity_days - environment.season_length_days))
	var shatter_factor := 1.0 - environment.harvest_delay * (1.0 - profile.value(&"shatter_resistance") / 100.0) * 0.60
	var density_factor := 1.0 - environment.density_stress * maxf(0.0, (profile.value(&"height_cm") - 24.0) / 100.0)
	if profile.flags.get(&"branch_height_density_penalty", false):
		density_factor -= environment.density_stress * 0.10
	density_factor = clampf(density_factor, 0.65, 1.0)
	var seed_number := profile.value(&"seed_number_potential")
	if environment.water_stress > 0.65:
		var reduction := lerpf(0.40, 0.80, clampf((environment.water_stress - 0.65) / 0.35, 0.0, 1.0))
		seed_number -= profile.value(&"yld2_bonus") * reduction
	seed_number *= profile.value(&"fertility_factor")
	seed_number *= water_factor * heat_factor * disease_a_factor * disease_b_factor * season_factor * density_factor * environment.fertility_level
	observation.expected_yield_g = maxf(0.0, seed_number * shatter_factor * profile.value(&"seed_mass_mg") / 1000.0)
	observation.yield_g = observation.expected_yield_g
	observation.height_cm = profile.value(&"height_cm")
	observation.maturity_days = maturity_days
	observation.seed_mass_mg = profile.value(&"seed_mass_mg")
	observation.drought_score = drought
	observation.heat_score = heat
	var pressure_sum := environment.pathogen_a_pressure + environment.pathogen_b_pressure
	observation.disease_score = (resistance_a + resistance_b) * 0.5 if pressure_sum <= 0.0 else (resistance_a * environment.pathogen_a_pressure + resistance_b * environment.pathogen_b_pressure) / pressure_sum
	observation.quality_score = profile.value(&"quality_score")
	return observation

func observe_phenotype(
		profile: GeneticProfile,
		environment: EnvironmentDefinition,
		rng: RandomNumberGenerator,
) -> PhenotypeObservation:
	var observation := expected_phenotype(profile, environment)
	var noise_scale := environment.micro_noise_scale
	observation.yield_g = maxf(0.0, observation.expected_yield_g * (1.0 + rng.randfn(0.0, environment.sigma_yield_rel * noise_scale)))
	observation.height_cm += rng.randfn(0.0, environment.sigma_height_cm * noise_scale)
	observation.maturity_days = roundf(observation.maturity_days + rng.randfn(0.0, environment.sigma_maturity_days * noise_scale))
	observation.seed_mass_mg = maxf(0.1, observation.seed_mass_mg + rng.randfn(0.0, environment.sigma_seed_mass_mg * noise_scale))
	return observation
