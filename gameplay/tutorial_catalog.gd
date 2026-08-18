class_name TutorialCatalog
extends RefCounted

## 教程百科是只读知识库；新手引导的操作步骤由 TutorialService 单独管理。
const TOPICS: Array[Dictionary] = [
	{
		"code": &"overview", "category": "入门", "title": "游戏目标与完整育种循环", "keywords": "入门 目标 流程 玩法",
		"content": "[font_size=24][color=#55d6a9]游戏目标[/color][/font_size]\n星芥不是收集所有‘好基因’的游戏。你的目标是在连锁、性状权衡与环境差异下，培育适合具体用途的稳定品系。\n\n[font_size=20]核心循环[/font_size]\n1. 选择亲本并决定杂交、自交或回交。\n2. 生成真实减数分裂产生的后代群体。\n3. 用硬门槛、目标权重和遗传多样性压缩候选。\n4. 阅读表型、基因型、染色体祖源和谱系。\n5. 在多个环境中做重复试验。\n6. 继续杂交或自交固定，最终命名稳定品系。\n\n任务模式提供三个标准难题；沙盒允许立即使用全部环境、QTL 和突变系统。"
	},
	{
		"code": &"genetics_basics", "category": "遗传概念", "title": "二倍体、等位基因与纯合/杂合", "keywords": "二倍体 等位基因 纯合 杂合 基因型",
		"content": "[font_size=24][color=#55d6a9]从 A/B 两个副本理解基因型[/color][/font_size]\n星芥是二倍体：每条染色体有两个同源副本，界面中记为 A 与 B。一个位点因此同时携带两个等位基因。\n\n• 两个等位基因相同，例如 YY、tt，称为纯合。\n• 两个等位基因不同，例如 Yy、Tt，称为杂合。\n• 剂量表示优势/效应等位基因出现 0、1 或 2 次。\n• 显性意味着杂合体不一定处在两个纯合体的正中间。\n\n四个默认创始系都是高度纯合材料，所以第一代杂交结果容易预测。后代通过分离与重组产生杂合和新的纯合组合。"
	},
	{
		"code": &"chromosome_map", "category": "遗传概念", "title": "染色体图谱、cM、连锁与重组", "keywords": "染色体 图谱 cM 连锁 重组 A B 祖源",
		"content": "[font_size=24][color=#55d6a9]如何读染色体图[/color][/font_size]\n每个 Chr 下面有 A/B 两根横条，表示两个同源副本。颜色表示创始祖源；颜色交界和白色竖线是重组边界；红点是突变。将鼠标停在图上可查看精确位置、祖源、最近位点和基因型。\n\n[font_size=20]cM 与连锁[/font_size]\ncM 是遗传距离，不是物理长度。距离越近，两个位点越不容易被一次重组拆开。YLD1 位于 41 cM，HGT 位于 47 cM，相距 6 cM；无干扰 Haldane 模型下重组率约 5.65%。\n\n如果某条配子在这 6 cM 区间内发生切换，就可能从 Y–T/ y–t 相位得到稀有的 Y–t 或 y–T。提高群体规模会提高找到稀有重组体的机会，但系统没有剧情保底。"
	},
	{
		"code": &"breeding_operations", "category": "育种玩法", "title": "杂交、自交与回交", "keywords": "杂交 自交 回交 F1 F2 BC1",
		"content": "[font_size=24][color=#55d6a9]三种育种操作[/color][/font_size]\n[font_size=20]杂交[/font_size]\n两个不同亲本各自独立产生一个配子，再结合为后代。F1、F2 只是谱系标签，不会改变遗传算法。\n\n[font_size=20]自交[/font_size]\n同一亲本独立产生两个配子。Aa 自交会自然产生约 1:2:1 的 AA:Aa:aa；连续自交和选择可提高纯合度。\n\n[font_size=20]回交[/font_size]\n把选中后代再次与轮回亲本杂交。它常用于保留供体的目标片段，同时逐代恢复商业背景。祖源视图能直接显示残留供体片段，而不是只显示理论家谱比例。"
	},
	{
		"code": &"genes_qtl", "category": "遗传概念", "title": "主效基因、QTL、显性与上位性", "keywords": "主效基因 QTL 显性 上位性 多效性",
		"content": "[font_size=24][color=#55d6a9]性状不由单个开关决定[/color][/font_size]\n18 个主效基因提供玩家容易识别的效果；30 个隐藏 QTL 让相同主效基因组合仍有连续差异。\n\n• 加性：等位基因剂量逐步改变性状。\n• 显性：杂合体额外偏离纯合体中点，例如 BRN 的杂合优势。\n• 上位性：两个位点共同出现时产生额外效果，例如 DRY×ROOT。\n• 多效性：一个位点同时影响多个性状，例如大粒可能降低种子数。\n\n任务模式中 QTL 会随试验证据逐步显示区间和标签；沙盒与基因组工坊可以直接查看全部位点。"
	},
	{
		"code": &"phenotype_environment", "category": "试验研究", "title": "表型、环境与 G×E", "keywords": "表型 环境 G×E 水分 热 病害 产量",
		"content": "[font_size=24][color=#55d6a9]基因型不等于一次观测值[/color][/font_size]\n系统先从 Genome 计算遗传潜力，再应用环境压力，最后加入微环境和测量噪声。\n\n产量由种子数潜力、结实率、水分、热、病害、季节、密度、落粒和单粒重共同决定。YLD2 在严重干旱下收益会折减；HOT 在无热胁迫时接近中性，在高热环境才体现价值。这就是基因型×环境互作（G×E）。\n\n因此不存在统治所有环境的唯一超级品种。比较品系时应关注多个环境的均值、标准误和排名，而不是一次最高值。"
	},
	{
		"code": &"selection", "category": "育种玩法", "title": "候选筛选、Pareto 与多样性", "keywords": "筛选 候选 Pareto 权重 门槛 多样性",
		"content": "[font_size=24][color=#55d6a9]为什么不展示全部 5000 株[/color][/font_size]\n底层会真实生成全部 Genome，但界面只展示压缩后的候选。\n\n1. 硬门槛先排除不满足成熟期、繁殖力等条件的个体。\n2. Pareto 筛选保留在产量、耐旱、品质间互不完全支配的方案。\n3. 目标权重决定综合排序偏好，不会修改真实表型。\n4. 多样性保护避免推荐列表全是几乎相同的兄弟株。\n\n门槛过严可能得到很少候选；权重只影响推荐顺序，不会让低产个体凭空增产。"
	},
	{
		"code": &"trials_research", "category": "试验研究", "title": "重复试验、误差与 QTL 研究", "keywords": "试验 重复 标准误 QTL 研究 置信度",
		"content": "[font_size=24][color=#55d6a9]用证据区分遗传与运气[/color][/font_size]\n一次观测包含噪声。重复次数增加后，可用均值和标准误判断差异是否稳定。\n\n任务模式中：\n• 至少 30 株、2 个环境会显示候选 QTL 区间。\n• 至少 100 株、3 个环境会进一步识别 QTL 标签、方向和置信度。\n• 命名稳定品系至少需要一次三重复试验。\n\n建议先在目标环境筛选，再用另一个压力环境检查代价；不要只根据 E0 的单次产量命名品系。"
	},
	{
		"code": &"pedigree_ancestry", "category": "谱系祖源", "title": "家谱、基因组祖源与 Segment", "keywords": "谱系 家谱 祖源 Segment 父母 片段",
		"content": "[font_size=24][color=#55d6a9]两种谱系必须分开[/color][/font_size]\n家谱回答‘父母和祖先是谁’，数据来自 PlantRecord 的父母 ID；基因组祖源回答‘某段染色体实际来自哪个创始材料’，数据来自 Segment。\n\n回交个体在家谱上可能有 25% 供体贡献，但经过选择后实际只保留 8% 供体片段。祖源比例按全部 6 条单倍型的遗传长度计算，总和应为 100%。\n\n自交时两条父母边指向同一株，但两个配子仍是独立生成，不能把遗传贡献当成只发生一次。"
	},
	{
		"code": &"standard_tasks", "category": "任务攻略", "title": "任务 A/B/C 的思路", "keywords": "任务 A B C 攻略 YLD1 HGT RES2 环境",
		"content": "[font_size=24][color=#55d6a9]标准任务不是固定答案[/color][/font_size]\n[font_size=20]任务 A[/font_size]\n金穗×沙叶后寻找 YLD1=Y 与 HGT=t 的重组染色体，再通过自交得到 YY/tt 稳定系。扩大 F2 群体比反复生成很小群体更有效。\n\n[font_size=20]任务 B[/font_size]\n用铁盾导入 RES2=B，并通过回交和片段筛选恢复 FRT=FF、SHAT=NN，把铁盾祖源压到 10% 以下。\n\n[font_size=20]任务 C[/font_size]\n分别为短季干旱 E1 和高温病害 E2 培育优势品系。两个环境的优胜者必须不同，体现 G×E。"
	},
	{
		"code": &"genome_workshop", "category": "工具指南", "title": "基因组工坊：创建纯合与杂合材料", "keywords": "基因组工坊 自定义 A B 纯合 杂合 Variant 基础祖源",
		"content": "[font_size=24][color=#55d6a9]基因组工坊完整用法[/color][/font_size]\n1. 输入材料名称并选择基础祖源。基础祖源决定未编辑区间的创始来源。\n2. 每个位点分别设置同源 A 与同源 B。A/B 相同是纯合，A/B 不同是杂合。\n3. ‘将 B 复制为 A’会把当前可见位点快速设为纯合。\n4. 点击创建后，新材料会加入亲本库，可用于杂交、自交、回交和试验。\n\n[font_size=20]信息可见性[/font_size]\n任务模式只允许编辑 18 个主效基因和已经研究确认的 QTL；沙盒显示全部 48 位点。\n\n[font_size=20]数据含义[/font_size]\n工坊不会篡改共享物种定义。材料以所选创始系作为 Segment 骨架，差异等位基因保存为 Variant Override，因此后代仍会真实重组，祖源、谱系和存档也保持可追踪。自定义材料是实验/沙盒工具，不代表自然创始系。"
	},
	{
		"code": &"mutations", "category": "遗传概念", "title": "突变与 Variant Override", "keywords": "突变 Variant 新生 QTL 稀疏",
		"content": "[font_size=24][color=#55d6a9]突变是惊喜，不是通关门槛[/color][/font_size]\n系统不模拟逐碱基 DNA，只记录具有玩法意义的稀疏突变。\n\n• 已知位点突变会改变现有位点的等位基因。\n• 新生 QTL 会携带固定模板中的小效应。\n• 突变附着在具体单倍型区间上，后续可随重组遗传或丢失。\n• MutationRecord 记录来源植物、世代和位置。\n\n标准任务关闭突变，确保统计教程稳定；沙盒默认以低概率启用。"
	},
	{
		"code": &"archives_determinism", "category": "系统说明", "title": "档案、确定性与删档", "keywords": "档案 存档 删除 确定性 seed 随机",
		"content": "[font_size=24][color=#55d6a9]为什么同一实验可以复现[/color][/font_size]\n每个后代使用 run seed、事件 ID、后代索引和随机流 ID 派生独立随机数。浏览界面、改变候选查看顺序或分批计算不会改变 Genome。\n\n档案数量不设上限；新游戏自动创建独立档案 ID。育种、试验、命名和任务推进后自动保存，也可手动保存。旧版三个槽位仍可读取。\n\n删除档案需要二次确认并永久删除对应目录；活动档案删除后不会被延迟自动保存重新创建。"
	},
	{
		"code": &"glossary", "category": "速查", "title": "术语速查", "keywords": "术语 genotype phenotype haplotype homolog QTL cM",
		"content": "[font_size=24][color=#55d6a9]常用术语[/color][/font_size]\n• Genome：一株植物完整的遗传事实。\n• Haplotype / 单倍型：一条同源染色体副本。\n• Homolog / 同源染色体：A/B 两个对应副本。\n• Segment：从某个 cM 开始的创始祖源片段。\n• Genotype / 基因型：位点上的两个等位基因组合。\n• Phenotype / 表型：遗传潜力经过环境和噪声后的表现。\n• QTL：影响连续性状的数量性状位点。\n• G×E：基因型与环境互作。\n• Pareto front：不存在所有目标都更优秀的另一个候选时，该候选位于前沿。\n• cM：遗传距离单位；100 cM 并不意味着两端位点必然 100% 重组。"
	}
]

static func topics(search_text: String = "") -> Array[Dictionary]:
	var query := search_text.strip_edges().to_lower()
	var result: Array[Dictionary] = []
	for topic: Dictionary in TOPICS:
		if query.is_empty() or String(topic["title"]).to_lower().contains(query) or String(topic["keywords"]).to_lower().contains(query) or String(topic["content"]).to_lower().contains(query):
			result.append(topic)
	return result

static func topic_by_code(code: StringName) -> Dictionary:
	for topic: Dictionary in TOPICS:
		if topic["code"] == code:
			return topic
	return {}
