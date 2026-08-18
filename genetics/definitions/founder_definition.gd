class_name FounderDefinition
extends Resource

@export var id: int
@export var code: StringName
@export var display_name: String
@export_multiline var description: String
@export var color: Color = Color.WHITE
## locus_id -> allele_id。创始材料为纯系，两个同源副本相同。
@export var alleles: Dictionary = {}

func allele_at(locus_id: int) -> int:
	return int(alleles.get(locus_id, 0))
