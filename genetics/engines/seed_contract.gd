class_name SeedContract
extends RefCounted

const ALGORITHM_VERSION: int = 1
const MIX_A: int = 6364136223846793005
const MIX_B: int = 1442695040888963407
const MIX_C: int = 3935559000370003845

## 版本化的 64 位种子合同。所有乘法依赖 GDScript 的有符号 64 位环绕语义。
static func hash_v1(run_seed: int, event_id: int, item_index: int, stream_id: int) -> int:
	var value := run_seed ^ (event_id * MIX_A)
	value = value ^ (item_index * MIX_B)
	value = value ^ (stream_id * MIX_C)
	value = value ^ (value >> 21)
	value *= MIX_A
	value = value ^ (value >> 29)
	value *= MIX_B
	return value ^ (value >> 32)

static func make_rng(run_seed: int, event_id: int, item_index: int, stream_id: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash_v1(run_seed, event_id, item_index, stream_id)
	return rng
