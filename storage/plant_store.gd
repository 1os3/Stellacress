class_name PlantStore
extends RefCounted

var _plants: Dictionary = {}
var _ordered_ids: Array[int] = []
var next_plant_id: int = 1

func allocate_id() -> int:
	var plant_id := next_plant_id
	next_plant_id += 1
	return plant_id

func add(plant: PlantRecord) -> String:
	if plant.id <= 0 or _plants.has(plant.id):
		return "plant_id=%d 无效或已存在" % plant.id
	if plant.parent_a_id >= plant.id or plant.parent_b_id >= plant.id:
		return "plant_id=%d 的父母 ID 必须小于子代 ID" % plant.id
	_plants[plant.id] = plant
	_ordered_ids.append(plant.id)
	next_plant_id = maxi(next_plant_id, plant.id + 1)
	return ""

func get_plant(plant_id: int) -> PlantRecord:
	return _plants.get(plant_id) as PlantRecord

func all_plants() -> Array[PlantRecord]:
	var result: Array[PlantRecord] = []
	for plant_id: int in _ordered_ids:
		result.append(_plants[plant_id] as PlantRecord)
	return result

func size() -> int:
	return _ordered_ids.size()

func clear() -> void:
	_plants.clear()
	_ordered_ids.clear()
	next_plant_id = 1
