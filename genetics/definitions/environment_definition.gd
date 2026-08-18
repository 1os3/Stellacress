class_name EnvironmentDefinition
extends Resource

@export var id: int
@export var code: StringName
@export var display_name: String
@export var season_length_days: float = 52.0
@export_range(0.0, 1.0) var water_stress: float
@export_range(0.0, 1.0) var heat_stress: float
@export_range(0.0, 1.0) var pathogen_a_pressure: float
@export_range(0.0, 1.0) var pathogen_b_pressure: float
@export_range(0.0, 1.0) var harvest_delay: float
@export_range(0.0, 1.0) var density_stress: float = 0.2
@export_range(0.5, 1.2) var fertility_level: float = 1.0
@export_range(0.0, 1.0) var micro_noise_scale: float = 1.0
@export var sigma_yield_rel: float = 0.10
@export var sigma_height_cm: float = 1.2
@export var sigma_maturity_days: float = 1.0
@export var sigma_seed_mass_mg: float = 0.08

func validate_definition() -> String:
	if id < 0 or code.is_empty() or display_name.is_empty():
		return "环境 id/code/display_name 无效"
	if season_length_days <= 0.0:
		return "%s.season_length_days 必须大于 0" % code
	return ""
