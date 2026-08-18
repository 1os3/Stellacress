class_name TutorialService
extends RefCounted

signal step_changed(step_index: int)

const STEPS: Array[Dictionary] = [
	{"title":"欢迎来到星芥育种室","text":"你不需要先掌握遗传学。教程会带你完成一次杂交、筛选、读图、试验和自交固定。四个初始品系都是纯合子，因此第一代结果容易观察。","tab":0},
	{"title":"第一步：选择亲本","text":"选择“金穗”和“沙叶”。金穗携带高产 Y 与高秆 T 的连锁片段，沙叶携带低产 y 与矮秆 t。","tab":0},
	{"title":"第二步：生成杂交后代","text":"操作选择“杂交”，群体规模可先用 500。点击“生成后代并筛选”，系统会真实执行两次减数分裂。","tab":0},
	{"title":"第三步：查看候选","text":"候选列表不是随机推荐：系统先应用成熟期门槛，再综合产量、耐旱、品质和遗传多样性。点击任意候选查看详情。","tab":0},
	{"title":"第四步：读懂染色体图","text":"每条染色体有 A/B 两根横条，表示两个同源副本。颜色是创始祖源；颜色交界是重组点；红点是突变；位点下方标有 cM 坐标。尝试寻找 YLD1 与 HGT 之间发生切换的个体。","tab":0},
	{"title":"第五步：做重复试验","text":"切换到“试验与研究”，选择候选、环境和至少 3 次重复。多环境证据会逐步显示隐藏 QTL 区间。","tab":1},
	{"title":"第六步：自交固定","text":"把理想候选作为亲本，操作改为“自交”。每次自交仍独立生成两个配子；连续选择可提高纯合度。纯合度达到 90% 且完成三重复试验后即可命名品系。","tab":0},
	{"title":"新手引导完成","text":"你已经掌握完整循环：选亲本 → 生成后代 → 看候选 → 读染色体 → 多环境试验 → 自交固定。任务页会继续引导三个标准育种目标；概念和全部工具说明请打开“教程百科”。","tab":2}
]

var enabled: bool = true
var completed: bool = false
var step_index: int = 0

func start(p_enabled: bool = true) -> void:
	enabled = p_enabled
	completed = false
	step_index = 0
	step_changed.emit(step_index)

func current_step() -> Dictionary:
	return STEPS[clampi(step_index, 0, STEPS.size() - 1)]

func next_step() -> void:
	if step_index < STEPS.size() - 1:
		step_index += 1
	else:
		completed = true
		enabled = false
	step_changed.emit(step_index)

func previous_step() -> void:
	step_index = maxi(0, step_index - 1)
	step_changed.emit(step_index)

func close() -> void:
	enabled = false
	step_changed.emit(step_index)

func reopen() -> void:
	enabled = true
	step_changed.emit(step_index)

func advance_to(minimum_step: int) -> void:
	if not completed and step_index < minimum_step:
		step_index = mini(minimum_step, STEPS.size() - 1)
		step_changed.emit(step_index)

func state() -> Dictionary:
	return {"enabled": enabled, "completed": completed, "step_index": step_index}

func restore(data: Dictionary) -> void:
	enabled = bool(data.get("enabled", true))
	completed = bool(data.get("completed", false))
	step_index = clampi(int(data.get("step_index", 0)), 0, STEPS.size() - 1)
