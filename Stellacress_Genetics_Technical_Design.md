# 星芥（Stellacress）遗传育种游戏

## 完整系统与底层算法设计

> 虚构自交植物 · 完整谱系 · 染色体重组 · QTL · 环境响应

**目标：让普通玩家只做少量直觉决策，同时让底层遗传真正成立。**

---

# 0. 文档摘要

本设计定义一个专为育种游戏服务的虚构二倍体自交植物“星芥”。物种具有 3 对染色体、18 个主要可认知基因、30 个隐藏 QTL、可配置的环境压力与完整谱系追踪。底层不复制完整 DNA 序列，而使用“创始单倍型 + 祖源片段 + 稀疏变异”表示基因组；减数分裂按遗传图谱产生交叉点，真实生成重组单倍型；性状由主效基因、QTL、显性、上位性、环境与 G×E 共同决定。

设计重点不是追求科研级拟真，而是保证以下现象由同一套底层规则自然产生：F1 杂合、F2 分离、自交固定、连锁拖累、罕见重组、回交导入、隐性缺陷、性状权衡、环境适应与多代祖源可追溯。玩家界面可以隐藏绝大多数参数，仅在需要时展开染色体和谱系。

> **核心技术结论：第一版无需模拟碱基序列。只要保存染色体上的祖源分段和少数变异，就可以同时支持完整遗传谱系、真实重组、基因/QTL 查询和十万级个体模拟。**

## 0.1 交付范围

- 物种与染色体规范：3 条染色体、18 个主效基因、30 个隐藏 QTL。
- 基因组数据结构：创始单倍型、祖源 Segment、Variant Override、PlantRecord。
- 完整算法：减数分裂、交叉互换、配子生成、杂交、自交、回交、突变、等位基因查询。
- 完整表型模型：主要性状、显性、上位性、多效性、环境压力、G×E、试验噪声。
- 完整谱系算法：父母关系、祖先查询、祖源百分比、染色体片段来源与历史事件。
- Godot 模块划分、推荐类接口、GDScript 伪代码、存档格式、性能策略。
- 验证方案：孟德尔比例、重组率、祖源覆盖、确定性随机数、性能与回归测试。

## 0.2 不在第一版实现的内容

- 逐碱基 DNA、真实转录组/蛋白组、表观遗传。
- 复杂多倍体、染色体结构变异、非整倍体。
- 科研级 crossover interference、gene conversion、真实物理 Mb 坐标。
- 无限个基因。第一版的遗传空间由 18 个主要基因 + 30 个 QTL + 稀疏突变构成。
- 强制把所有底层参数展示给玩家。默认 UI 只展示结果、风险和少量可解释遗传信息。

# 1. 设计目标与设计原则

## 1.1 四个不可妥协目标

1. 遗传一致性：同一套染色体规则必须自然产生分离、连锁、固定和回交结果，禁止针对 F2、F3 等世代写硬编码“剧情概率”。
2. 可解释性：任何重要后代都能解释“来自哪个亲本、哪段染色体、哪个基因/QTL、在哪一代发生过关键重组”。
3. 玩家低门槛：底层可以复杂，但核心操作必须仍是“选亲本 → 生成后代 → 看候选 → 留种/继续杂交”。
4. 工程可扩展：添加新基因、新环境、新病原或新创始品系时，不应修改核心减数分裂与谱系算法。

## 1.2 设计哲学：规则真实，参数虚构

星芥不是现实物种，因此不需要为每个基因寻找现实同源基因，也不需要让数值精确对应某种作物。真实性集中在遗传规则层：二倍体、减数分裂、重组、连锁、显隐性、自交、回交、上位性与环境响应都按照一致的数学模型计算。参数则完全服务于游戏节奏。

## 1.3 玩家信息分层

| 层级 | 默认对象 | 展示内容 |
| --- | --- | --- |
| 基础层 | 所有玩家 | 产量、成熟、株高、种子大小、耐旱、抗病；用星级/数值与一句话解释。 |
| 进阶层 | 主动展开 | 估计值、置信区间、家系均值、是否稳定、已知主效基因。 |
| 遗传层 | 硬核玩家 | 3 条染色体、相位、祖源片段、重组点、QTL 区间、完整谱系。 |

# 2. 物种规范：星芥 Stellacress

| 项目 | 规范 |
| --- | --- |
| 倍性 | 二倍体，2n = 6；3 对同源染色体。 |
| 繁殖 | 雌雄同花；允许自交、人工杂交和回交。 |
| 世代 | 一年生快速世代；游戏中 1 个育种周期可压缩为数秒到数十秒。 |
| 创始材料 | 默认 4 个纯合创始品系；后续可增加野生材料。 |
| 遗传坐标 | 使用 cM（centiMorgan）作为唯一重组坐标；不要求物理 Mb。 |
| 主要基因 | 18 个；玩家最终可识别。 |
| 隐藏 QTL | 30 个；多数不直接命名，负责连续分布与遗传背景效应。 |
| 突变 | 稀疏事件；只记录产生游戏意义的变异。 |

## 2.1 染色体地图

```text
Chr 1 (100 cM)  生长 / 产量 / 生命周期
0----FLR(12)----BRN(25)------YLD1(41)--HGT(47)---------------CLR(76)------DOR(91)--100

Chr 2 (95 cM)   环境适应 / 种子 / 品质
0---DRY(10)--ROOT(18)---SIZ(27)-----------YLD2(48)---------QLT(67)------------HOT(88)--95

Chr 3 (95 cM)   病害 / 繁殖 / 农业性状
0---RES1(11)--------RES2(30)----------FRT(47)---SHAT(55)----------MAT(72)---------ANT(90)-95
```

遗传位置直接决定连锁强度。例如 YLD1 与 HGT 相距 6 cM，理论重组率约 5.65%（无干扰、Haldane 模型），因此可以稳定地产生“高产与高秆难以拆开”的早期育种难题。

# 3. 18 个主要基因的完整定义

主要基因并非简单的“好/坏按钮”。每个位点至少承担一个玩法角色：主效性状、性状权衡、环境特异性、标记作用或连锁难题。内部等位基因 ID 采用大写为改良型/特殊型、小写为基础型只是编码约定，不意味着大写一定更好。

| 基因 | cM | 等位基因 | 主效 | 规则与玩法 |
| --- | --- | --- | --- | --- |
| Chr1: FLR | 12 | L / e | 开花/成熟 | LL: 成熟 +6 d、种子数潜力 +8%；Le: +2 d、+3%；ee: -2 d、产量上限略低。长季节偏好 L，短季节偏好 e。 |
| Chr1: BRN | 25 | B / b | 分枝 | BB 分枝多、潜在种子数 +12% 但成熟离散度增加；Bb +10% 且离散度较小；bb 基准。形成杂合优势示例。 |
| Chr1: YLD1 | 41 | Y / y | 种子数 | 每个 Y 使潜在种子数约 +180；同时轻微增加水分需求。与 HGT 紧密连锁。 |
| Chr1: HGT | 47 | T / t | 株高 | 每个 T 约 +5.5 cm；高秆略增生物量但高密度/强风环境有惩罚。早期高产品系携带 Y-T 连锁。 |
| Chr1: CLR | 76 | C / c | 种皮颜色 | CC 深色、Cc 斑驳/中间、cc 浅色。几乎中性，作为肉眼遗传标记。 |
| Chr1: DOR | 91 | D / d | 种子休眠 | 每个 D 增加休眠；强休眠防潮湿提前萌发，但出苗更慢。 |
| Chr2: DRY | 10 | A / a | 保水 | A 提高耐旱；正常湿润环境下轻微降低最大生长速度。 |
| Chr2: ROOT | 18 | R / r | 根系深度 | R 提高深层取水能力；幼苗阶段消耗资源。A 与 R 同时存在时产生正上位性。 |
| Chr2: SIZ | 27 | S / s | 种子大小 | 每个 S 使种子质量约 +0.35 mg，同时种子数潜力约 -5%。大粒不等于高总产。 |
| Chr2: YLD2 | 48 | E / e | 同化效率 | 每个 E 使潜在种子数 +140；在严重缺水时收益缩小，形成 G×E。 |
| Chr2: QLT | 67 | Q / q | 品质 | 每个 Q 提高品质评分约 +12，但轻微降低种子数。高端市场价值高。 |
| Chr2: HOT | 88 | H / h | 耐热 | H 只在高温胁迫时显著降低结实损失；无热胁迫时近似中性。 |
| Chr3: RES1 | 11 | A / a | 病原 A 抗性 | A 提高病原 A 抗性；AA 有小幅常态生长成本。 |
| Chr3: RES2 | 30 | B / b | 病原 B 抗性 | B 提高病原 B 抗性；与 RES1 同时存在时形成广谱防御但成本略叠加。 |
| Chr3: FRT | 47 | F / f | 繁殖力 | FF 1.00；Ff 0.95；ff 0.65 的结实倍率。优秀野生抗病材料可故意携带 ff。 |
| Chr3: SHAT | 55 | N / s | 不落粒 | NN 不易落粒，Ns 中等，ss 易落粒。靠近 FRT，方便形成回交与重组难题。 |
| Chr3: MAT | 72 | M / m | 成熟整齐度 | M 提高群体成熟同步性，减少机械收获损失；对单株潜力影响很小。 |
| Chr3: ANT | 90 | P / p | 花青素 | PP 紫色明显，Pp 中等，pp 绿色/无紫。近中性，可作为可视标记。 |

## 3.1 明确的基因互作规则

| 规则 ID | 条件 | 额外效果 |
| --- | --- | --- |
| EPI_DRY_ROOT | DRY 至少 1 个 A 且 ROOT 至少 1 个 R | 耐旱评分额外 +14；双纯合 AA/RR 再 +4。 |
| EPI_RES12 | RES1 含 A 且 RES2 含 B | 两类病原防御各 +6，但潜在种子数 -3%。 |
| EPI_BRANCH_HGT | BRN=BB 且 HGT 含 T | 高密度时额外倒伏/竞争惩罚；正常密度影响很小。 |
| GXE_YLD2_DRY | YLD2 含 E 且水分胁迫 > 0.65 | YLD2 的种子数增益按 40%~80% 折减。 |
| GXE_HOT | HOT 含 H 且热胁迫 > 0 | 热胁迫导致的结实损失显著降低。 |

# 4. 隐藏 QTL 设计

QTL 的作用是让同样的主要基因组合仍出现连续差异，避免游戏退化成“收集 18 个正确等位基因”。QTL 默认都是双等位位点，采用加性效应为主、少量显性与多效性。玩家早期只看到“某一区段与性状有关”；进阶研究后才可显示 QTL 标签。

| ID | Chr | cM | 主性状 | 加性效应 | 显性 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| Q01 | 1 | 5 | 种子数 | +90 | - | 早熟背景中效应稍弱 |
| Q02 | 1 | 18 | 成熟期 | +1.8 d | - | 长季节中性 |
| Q03 | 1 | 32 | 株高 | +2.4 cm | - | - |
| Q04 | 1 | 36 | 种子数 | +70 | +20 het | 靠近 YLD1 |
| Q05 | 1 | 53 | 耐旱 | +5 | - | 轻度多效：株高 -0.8 cm |
| Q06 | 1 | 58 | 种子数 | +65 | - | - |
| Q07 | 1 | 64 | 品质 | +5 | - | 种子数 -25 |
| Q08 | 1 | 70 | 成熟期 | -1.2 d | - | - |
| Q09 | 1 | 83 | 休眠 | +8 | - | - |
| Q10 | 1 | 97 | 种子数 | +55 | - | - |
| Q11 | 2 | 4 | 耐旱 | +6 | - | - |
| Q12 | 2 | 14 | 根系/耐旱 | +4 | - | 与 DRY/ROOT 同区域 |
| Q13 | 2 | 22 | 种子质量 | +0.18 mg | - | 种子数 -20 |
| Q14 | 2 | 34 | 种子数 | +80 | - | - |
| Q15 | 2 | 39 | 成熟期 | +1.0 d | - | - |
| Q16 | 2 | 55 | 种子数 | +85 | +15 het | 水分胁迫下折减 |
| Q17 | 2 | 60 | 耐热 | +5 | - | - |
| Q18 | 2 | 73 | 品质 | +6 | - | - |
| Q19 | 2 | 79 | 种子质量 | +0.15 mg | - | - |
| Q20 | 2 | 93 | 耐热 | +7 | - | - |
| Q21 | 3 | 5 | 病原A抗性 | +6 | - | - |
| Q22 | 3 | 17 | 病原A抗性 | +5 | - | 潜在种子数 -20 |
| Q23 | 3 | 24 | 病原B抗性 | +6 | - | - |
| Q24 | 3 | 37 | 繁殖力 | +0.03 | - | 倍率增益 |
| Q25 | 3 | 43 | 成熟整齐 | +6 | - | - |
| Q26 | 3 | 61 | 不落粒 | +8 | - | - |
| Q27 | 3 | 66 | 种子数 | +60 | - | - |
| Q28 | 3 | 77 | 成熟整齐 | +7 | - | - |
| Q29 | 3 | 84 | 品质 | +5 | - | 花青素背景轻微增强 |
| Q30 | 3 | 94 | 种子数 | +50 | - | - |

## 4.1 QTL 基因型计分

对于一个双等位 QTL，令替代等位基因剂量 dosage ∈ {0,1,2}。设加性效应 a、杂合显性偏离 d，则该位点对某性状的贡献为：

```text
effect = a * (dosage - 1) + d * I(dosage == 1)
```

这样 0/1/2 剂量分别得到 -a、d、+a。若希望以基础等位基因为 0 而不是以中点为 0，也可以在数据导入阶段把常数平移进 trait baseline；核心算法不需要变化。

# 5. 基因组数据表示：创始单倍型 + 祖源片段 + 稀疏变异

## 5.1 为什么不保存完整基因组

对游戏而言，真正需要回答的问题只有两个：某个位置现在携带哪个等位基因；某一段染色体来自哪个祖先。逐碱基序列对这两个问题都不是必要条件。采用 Segment 表示后，一条单倍型只需保存“从哪个 cM 开始切换到哪个创始单倍型”。

```text
Haplotype Chr1:
  [0.0,  37.2) -> FounderHap 2
  [37.2, 61.8) -> FounderHap 7
  [61.8,100.0] -> FounderHap 2

Variant overrides:
  44.6 cM -> Mutation #M1042
```

## 5.2 核心数据结构

```gdscript
class Segment:
    var start_cm: float
    var founder_haplotype_id: int

class VariantOverride:
    var position_cm: float
    var locus_id: int          # -1 表示新生 QTL/突变位点
    var allele_id: int
    var mutation_id: int

class Haplotype:
    var chromosome_id: int
    var segments: Array[Segment]        # 按 start_cm 升序；0.0 必须存在
    var variants: Array[VariantOverride]# 按 position_cm 升序

class Genome:
    var homolog_a: Array[Haplotype]     # 3 条
    var homolog_b: Array[Haplotype]     # 3 条

class PlantRecord:
    var id: int
    var parent_a_id: int
    var parent_b_id: int
    var generation: int
    var birth_event_id: int
    var genome_ref: int
    var phenotype_summary_ref: int
```

## 5.3 创始单倍型表

每个创始纯系提供 2 条相同的单倍型/染色体，因此 4 个创始品系 × 3 条染色体 = 12 个逻辑创始单倍型（也可以给父/母副本分别编号，但纯系时内容相同）。创始单倍型表直接保存所有主要基因和 QTL 的等位基因。后代无需复制这些 allele arrays，只通过祖源片段查回。

## 5.4 等位基因查询算法

1. 输入 chromosome_id、haplotype、locus_position。
2. 在 haplotype.segments 中二分查找最后一个 start_cm ≤ locus_position 的 Segment。
3. 得到 founder_haplotype_id，并从 FounderGenomeTable[founder_haplotype_id][locus_id] 读取基础等位基因。
4. 在 variants 中查找同一位置/同一 locus 的 override；若存在，以突变等位基因覆盖基础等位基因。
5. 二倍体基因型查询分别对 homolog_a 与 homolog_b 执行一次。

```gdscript
func get_allele(hap: Haplotype, locus: LocusDef) -> int:
    var seg_idx = upper_bound_segment(hap.segments, locus.position_cm) - 1
    var founder_id = hap.segments[seg_idx].founder_haplotype_id
    var allele = founder_table.get_allele(founder_id, locus.id)
    var ov = find_variant_override(hap.variants, locus.id, locus.position_cm)
    return ov.allele_id if ov != null else allele
```

# 6. 减数分裂与重组算法

## 6.1 MVP 模型：Haldane/Poisson 重组过程

每条染色体使用遗传长度 L（Morgan）直接控制一条配子染色体上的重组开关次数。若染色体长度为 100 cM，则 L=1.0。第一版采用无 crossover interference 的 Poisson 过程：

```text
N_crossovers ~ Poisson(L_morgan)
```

然后在 [0, chromosome_length_cM) 上均匀采样 N 个交叉位置并排序。随机选择起始同源染色体，沿染色体每经过一个交叉点就在 homolog A/B 之间切换。该过程直接生成一个重组配子单倍型。

## 6.2 伪代码

```gdscript
func make_gamete_chromosome(pair: ChromosomePair, chr_def: ChromosomeDef, rng) -> Haplotype:
    var lambda = chr_def.length_cm / 100.0
    var n = rng.poisson(lambda)
    var cuts: Array[float] = []
    for i in n:
        cuts.append(rng.uniform(0.0, chr_def.length_cm))
    cuts.sort()

    var use_a = rng.bernoulli(0.5)
    var boundaries = [0.0] + cuts + [chr_def.length_cm]
    var out = Haplotype.new(chr_def.id)

    for i in range(boundaries.size() - 1):
        var left = boundaries[i]
        var right = boundaries[i + 1]
        var source = pair.a if use_a else pair.b
        append_interval(out, source, left, right)
        use_a = !use_a

    merge_adjacent_equal_segments(out.segments)
    copy_variants_from_selected_intervals(out, pair.a, pair.b, boundaries)
    return out
```

## 6.3 Segment 拼接算法

append_interval(out, source, left, right) 不复制完整 source，而是遍历 source 在该区间覆盖的 Segment，将边界裁剪到 left/right 后追加。随后若新 Segment 与前一个 Segment 的 founder_haplotype_id 相同，则合并，避免片段数无意义增长。

```gdscript
func append_interval(out, source, left, right):
    for seg in source.overlapping_segments(left, right):
        var clipped_start = max(left, seg.start_cm)
        if out.segments.is_empty() or out.segments[-1].founder_haplotype_id != seg.founder_haplotype_id:
            out.segments.append(Segment(clipped_start, seg.founder_haplotype_id))
    for v in source.variants_in_range(left, right):
        out.variants.append(v)
```

## 6.4 理论验证值

无干扰 Haldane 映射下，两个位点相距 d Morgan 的重组率：

```text
r = 0.5 * (1 - exp(-2 * d))
```

| 间距 | d (Morgan) | 理论 r |
| --- | --- | --- |
| 6 cM | 0.06 | 0.0565 ≈ 5.65% |
| 10 cM | 0.10 | 0.0906 ≈ 9.06% |
| 25 cM | 0.25 | 0.1967 ≈ 19.67% |
| 50 cM | 0.50 | 0.3161 ≈ 31.61% |
| 100 cM | 1.00 | 0.4323 ≈ 43.23% |

## 6.5 可选升级：crossover interference

如果后续希望让交叉点更均匀而不是 Poisson 聚集，可以把交叉点间距改成 Gamma renewal process。令间距 X ~ Gamma(shape=ν, scale=1/ν)，平均仍为 1 Morgan；ν=1 回到 Poisson，ν≈2~4 会产生明显干扰。第一版不建议启用，因为玩家几乎无法感知，而测试成本会增加。

## 6.6 配子生成

```gdscript
func make_gamete(parent: Genome, rng) -> Gamete:
    var g = Gamete.new()
    for chr_id in 3:
        var pair = ChromosomePair(parent.homolog_a[chr_id], parent.homolog_b[chr_id])
        g.chromosomes.append(make_gamete_chromosome(pair, species.chromosomes[chr_id], rng.split(chr_id)))
    maybe_apply_mutations(g, rng.split(100))
    return g
```

# 7. 杂交、自交与回交

## 7.1 杂交

```gdscript
func cross(parent_a: PlantRecord, parent_b: PlantRecord, offspring_index: int) -> PlantRecord:
    var rng_a = seeded_rng(hash64(run_seed, cross_event_id, offspring_index, 0))
    var rng_b = seeded_rng(hash64(run_seed, cross_event_id, offspring_index, 1))
    var gamete_a = make_gamete(load_genome(parent_a), rng_a)
    var gamete_b = make_gamete(load_genome(parent_b), rng_b)
    return create_plant(parent_a.id, parent_b.id, gamete_a, gamete_b)
```

## 7.2 自交

自交不是“复制自己再随机减半杂合度”。必须对同一亲本独立执行两次 make_gamete()，再受精。这样 Aa 位点会自然产生 1:2:1，多个连锁位点会自然保留相位和重组结构。

```gdscript
func self_cross(parent: PlantRecord, offspring_index: int) -> PlantRecord:
    # 两个 RNG 流必须独立
    return cross_with_same_parent_but_independent_meiosis(parent, offspring_index)
```

## 7.3 回交

回交无需专门遗传算法：BC1 = cross(F1_or_selected, recurrent_parent)。回交代数只作为 pedigree metadata 计算或显示。因为祖源 Segment 被保留，系统可以直接计算每条染色体中受体亲本与供体亲本的残留比例。

## 7.4 世代标签

F1/F2/BC1 等标签不应决定遗传计算，只用于 UI。推荐记录 mating_event.type（CROSS/SELF/BACKCROSS）并根据父母事件关系生成显示标签。这样复杂谱系、三亲杂交或中间自交不会破坏算法。

# 8. 稀疏突变系统

突变只在“会产生游戏意义”时记录。不要模拟每次 DNA 复制的无效点突变。系统提供两类突变：已知位点新等位基因、以及新生 QTL。

| 类型 | 触发 | 保存内容 | 玩法 |
| --- | --- | --- | --- |
| Known-locus mutation | 极低概率落在 18 个主要基因/30 QTL | locus_id、新 allele_id、origin plant | 产生新颜色、早熟、抗性或缺陷等。 |
| Novel QTL | 更低概率事件/剧情研究 | chr、cM、trait effect vector、dominance | 出现可定位的新性状来源。 |

```gdscript
class MutationRecord:
    var id: int
    var chromosome_id: int
    var position_cm: float
    var origin_plant_id: int
    var origin_generation: int
    var locus_id: int          # -1 => novel QTL
    var new_allele_id: int
    var trait_effects: Dictionary
    var dominance_effects: Dictionary
```

当发生突变时，只把 VariantOverride 添加到当前配子对应的 Haplotype。以后重组时，该变异像普通遗传标记一样随所在区间复制或丢失。

# 9. 表型与性状计算模型

## 9.1 性状分成“遗传潜力”和“环境实现值”

每个个体先从基因型计算 GeneticProfile，再把它放进 Environment 中生成一次观察表型。这样同一基因型在不同地点/年份会得到不同结果，并且可以支持重复试验和“可信度”机制。

```text
Genotype -> GeneticProfile
         -> Environment modifiers
         -> Deterministic expected phenotype
         -> Micro-environment / measurement noise
         -> Observed phenotype
```

## 9.2 GeneticProfile 字段

| 字段 | 单位/范围 | 说明 |
| --- | --- | --- |
| seed_number_potential | 粒/株 | 隐藏中间变量；YLD1/YLD2/BRN/QTL 主要作用于此。 |
| seed_mass_mg | mg/粒 | 玩家可见；SIZ/QTL 决定。 |
| maturity_days | 天 | 玩家可见；FLR/QTL 决定。 |
| height_cm | cm | 玩家可见；HGT/QTL 决定。 |
| drought_score | 0..100 | 玩家可见；DRY/ROOT/QTL/上位性。 |
| heat_score | 0..100 | 内部/可选显示；HOT/QTL。 |
| resistance_A/B | 0..100 | 病原特异抗性。UI 可汇总为“抗病”。 |
| fertility_factor | 0..1.1 | FRT/QTL；乘到结实数。 |
| shatter_resistance | 0..100 | SHAT/QTL；决定延迟收获损失。 |
| maturity_uniformity | 0..100 | MAT/QTL；决定群体收获效率。 |
| quality_score | 0..100 | QLT/QTL；市场与任务使用。 |
| color/anthocyanin | 类别/0..100 | CLR、ANT；视觉标记。 |

## 9.3 推荐基础值

| 性状 | 基础值 |
| --- | --- |
| seed_number_potential | 1500 粒/株 |
| seed_mass_mg | 2.8 mg |
| maturity_days | 42 d |
| height_cm | 24 cm |
| drought_score | 45 |
| heat_score | 45 |
| resistance_A/B | 35 / 35 |
| fertility_factor | 1.00 |
| shatter_resistance | 65 |
| maturity_uniformity | 60 |
| quality_score | 50 |

## 9.4 基因型到 GeneticProfile

1. 初始化全部基础值。
2. 遍历 18 个主效基因，根据二倍体 genotype 执行 genotype-effect table。
3. 遍历 30 个 QTL，按 additive + dominance 公式叠加。
4. 执行 EpistasisRules，例如 DRY×ROOT。
5. 执行 pleiotropy（同一位点同时改多个字段）。
6. 最后 clamp 到允许范围，但尽量避免在中间步骤频繁 clamp，以免改变遗传加性关系。

## 9.5 环境模型

```gdscript
class EnvironmentDef:
    var season_length_days: float     # 例如 46
    var water_stress: float           # 0..1
    var heat_stress: float            # 0..1
    var pathogen_A_pressure: float    # 0..1
    var pathogen_B_pressure: float    # 0..1
    var harvest_delay: float          # 0..1
    var density_stress: float         # 0..1
    var fertility_level: float        # 0.5..1.2
    var micro_noise_scale: float      # 0..1
```

## 9.6 环境倍率

以下公式不是为了生理学精确，而是为了保持单调性、可解释性和可调参。所有 multiplier 最终 clamp 到合理区间。

```text
water_factor = 1.0 - water_stress * (0.75 - 0.0065 * drought_score)
heat_factor  = 1.0 - heat_stress  * (0.65 - 0.0055 * heat_score)

disease_A_factor = 1.0 - pathogen_A_pressure * (0.65 - 0.0055 * resistance_A)
disease_B_factor = 1.0 - pathogen_B_pressure * (0.65 - 0.0055 * resistance_B)

if maturity_days <= season_length_days:
    season_factor = 1.0
else:
    season_factor = max(0.20, 1.0 - 0.06 * (maturity_days - season_length_days))

shatter_factor = 1.0 - harvest_delay * (1.0 - shatter_resistance / 100.0) * 0.60
```

## 9.7 产量计算

```text
effective_seed_number = seed_number_potential
    * fertility_factor
    * water_factor
    * heat_factor
    * disease_A_factor
    * disease_B_factor
    * season_factor
    * density_factor

retained_seed_number = effective_seed_number * shatter_factor
expected_yield_g = retained_seed_number * seed_mass_mg / 1000.0
```

这样“种子大”与“种子多”成为两条不同路线；SIZ 可以增加单粒重却降低种子数，而 YLD1/YLD2 主要增加种子数。玩家看到的总产量是二者乘积，不存在简单的单一“产量基因”。

## 9.8 观察噪声与重复试验

每次种植都生成 micro-environment noise。建议产量使用相对噪声，形态性状使用绝对噪声：

```text
observed_yield = max(0, expected_yield * (1 + Normal(0, sigma_yield_rel)))
observed_height = expected_height + Normal(0, sigma_height_cm)
observed_maturity = round(expected_maturity + Normal(0, sigma_maturity_days))
```

默认 sigma_yield_rel=0.08~0.15，height=1.0~2.0 cm，maturity=0.8~1.5 d。多地点/重复试验只是在不同 Environment/RNG 下重复 phenotype()；均值和标准误由 TrialService 计算。

# 10. 四个创始纯系

所有默认创始品系均高度纯合，使第一轮杂交与 F1 结果容易理解。隐藏 QTL 的等位基因通过预制 FounderGenomeTable 固定，不在开局随机生成，以保证教程与回归测试可重复。

| 品系 | 定位 | 关键优势 | 关键缺陷/连锁 |
| --- | --- | --- | --- |
| 金穗 Goldspike | 高产骨架 | YLD1=YY、YLD2=EE、SIZ=SS；种子数与粒重高。 | Chr1 为 Y-T 连锁：高产同时高秆；耐旱差。 |
| 沙叶 Sandleaf | 旱地适应 | DRY=AA、ROOT=RR、HOT=HH；早熟、矮秆。 | 种子小、YLD1/YLD2 基础型，品质一般。 |
| 铁盾 Ironshield | 抗病供体 | RES1=AA、RES2=BB；部分抗病 QTL 优秀。 | FRT=ff、SHAT=ss；低繁殖力且易落粒。 |
| 白珠 Whitepearl | 品质/大粒 | SIZ=SS、QLT=QQ、MAT=MM；浅色标记明显。 | 抗病弱、耐旱普通、种子数中等。 |

## 10.1 建议关键相位

```text
Goldspike Chr1:  ... YLD1=Y ----6cM---- HGT=T ...   # 不良连锁
Sandleaf  Chr1:  ... YLD1=y ----6cM---- HGT=t ...

Ironshield Chr3: RES2=B -------- FRT=f --8cM-- SHAT=s
Goldspike  Chr3: RES2=b -------- FRT=F ------- SHAT=N

目标 1：找到 Y - t 重组体（高产 + 矮秆）
目标 2：把 B 导入优良背景，同时去掉 f 与 s
```

# 11. 完整谱系与祖源追踪

## 11.1 两种“谱系”必须分开

| 类型 | 回答的问题 | 数据来源 |
| --- | --- | --- |
| Genealogical pedigree | 这株的父母/祖父母是谁？ | PlantRecord.parent_a_id / parent_b_id |
| Genomic ancestry | Chr2 这 12 cM 到底来自哪个创始品系？ | Haplotype.segments + Founder registry |

家谱比例与实际基因组祖源可以不同。例如理论家谱上某供体占 25%，但经过选择与重组后实际保留可能只有 8%。游戏应优先把这种差异作为硬核奖励展示。

## 11.2 祖先查询

```gdscript
func get_ancestors(plant_id: int, max_depth: int) -> Dictionary:
    var result = {} # ancestor_id -> minimum depth / path count
    var queue = [(plant_id, 0)]
    while not queue.is_empty():
        var current = queue.pop_front()
        if current.depth >= max_depth: continue
        var p = plant_store.get(current.id)
        for parent_id in [p.parent_a_id, p.parent_b_id]:
            if parent_id <= 0: continue
            update_result(result, parent_id, current.depth + 1)
            queue.push_back((parent_id, current.depth + 1))
    return result
```

注意自交时 parent_a_id == parent_b_id。显示谱系图时可以合并同一节点的两条边，但遗传贡献计算不能因此假设“只贡献一次”；实际贡献仍由两个独立配子决定。

## 11.3 基因组祖源百分比

对一株二倍体植物，所有 6 条单倍型的总遗传长度为 2 × Σ chromosome_length。遍历每个 Segment，按“区间长度 × founder_id”累加即可。

```text
total_length = 2.0 * sum(chr.length_cm)
for hap in all_6_haplotypes:
    for each segment interval [start, end):
        ancestry[segment.founder_id] += end - start
for founder in ancestry:
    ancestry[founder] /= total_length
```

## 11.4 关键历史事件

为了让谱系有叙事价值，建议额外记录 BreedingEvent：CROSS、SELF、BACKCROSS、TRIAL、SELECTION、MUTATION_DISCOVERY、RECOMBINATION_DISCOVERY。事件只记录引用，不改变遗传计算。UI 可以因此显示“这个抗病片段在第 7 年由铁盾导入；第 10 年通过一次重组摆脱落粒位点”。

# 12. 群体生成、筛选与候选压缩

## 12.1 计算和 UI 分离

玩家点击“生成 1200 株 F2”时，底层可以真的生成 1200 个 Genome/PlantRecord，但 UI 不应迫使玩家逐株检查。SelectionService 先应用任务门槛、Pareto 排序或自定义育种指数，展示 10~30 个候选。被淘汰个体仍可保留简化谱系记录，是否保留完整 Genome 由存档策略决定。

## 12.2 推荐候选算法

1. Hard filter：淘汰明显不满足硬条件的个体，例如成熟 > 50 d、繁殖力 < 0.5。
2. Pareto front：在产量、耐旱、品质等目标上保留互不完全支配的个体。
3. Diversity guard：避免 20 个候选全部是几乎同一基因型；按遗传距离聚类，每簇保留若干。
4. Novelty boost：罕见重组、新突变、新的双优组合获得展示加权，但不直接改变真实表型。
5. 最终只把有限候选交给玩家。

## 12.3 遗传距离（低成本版本）

无需全基因组 SNP。可在 18 主要基因 + 30 QTL 共 48 个位点上计算简单 IBS 距离：

```text
distance(i,j) = mean_locus( abs(dosage_i - dosage_j) / 2.0 )
```

如果后期希望更准确，可在固定的 200 个中性 marker 上计算，不影响遗传核心。

# 13. Godot 工程架构

## 13.1 数据定义层（Resource/只读）

```text
SpeciesDefinition
  ChromosomeDefinition[3]
  LocusDefinition[48+]
  TraitDefinition[]
  EpistasisRule[]
  EnvironmentDefinition[]
  FounderDefinition[4]

这些内容在游戏运行中应视为 immutable definition data。
```

## 13.2 运行时服务层

| 服务 | 职责 |
| --- | --- |
| GeneticsEngine | 基因型查询、等位基因剂量、QTL effect、遗传 profile。 |
| MeiosisEngine | Poisson crossover、Segment 重组、Variant 继承、配子生成。 |
| BreedingEngine | cross/self/backcross、批量后代、事件与 ID 分配。 |
| PhenotypeEngine | GeneticProfile + Environment -> expected/observed phenotype。 |
| TrialService | 重复试验、均值、方差、置信区间、排名。 |
| SelectionService | 硬筛、Pareto、育种指数、遗传多样性、候选压缩。 |
| PedigreeService | 家谱、祖源百分比、片段来源、事件追溯。 |
| PlantStore | PlantRecord 索引与批量读写。 |
| GenomeStore | 压缩基因组 blob；只把当前需要的 Genome materialize 到对象。 |
| SaveService | 版本化存档、定义版本、随机种子与增量 checkpoint。 |

## 13.3 推荐目录结构

```text
res://
  genetics/
    defs/
      species_definition.gd
      chromosome_definition.gd
      locus_definition.gd
      environment_definition.gd
    runtime/
      genome.gd
      haplotype.gd
      segment.gd
      plant_record.gd
    engines/
      meiosis_engine.gd
      genetics_engine.gd
      phenotype_engine.gd
      breeding_engine.gd
      pedigree_service.gd
      selection_service.gd
  data/
    stellacress_species.tres
    loci/*.tres
    environments/*.tres
    founders/*.tres
  storage/
    plant_store.gd
    genome_store.gd
    save_service.gd
  tests/
    test_mendelian.gd
    test_recombination.gd
    test_pedigree.gd
    test_phenotype.gd
```

## 13.4 不要把每株植物做成 Node

> **性能原则：Plant 是数据，不是场景节点。数千或数万株不能对应数千 Node。UI 只为当前查看的少量个体创建控件；模拟层使用普通数据对象或 PackedArray/二进制存储。**

# 14. 性能与存储设计

## 14.1 对象层与归档层分离

GDScript 对象适合开发和小规模原型，但大量 Segment 对象会有显著对象开销。建议两阶段实现：

| 阶段 | 实现 |
| --- | --- |
| MVP | Haplotype/Segment 使用 RefCounted class；每代 500~5000 株。便于调试。 |
| 优化版 | GenomeStore 使用扁平 PackedInt32/PackedFloat32 或自定义二进制 blob；只 materialize 候选。 |

## 14.2 压缩 Segment 编码

染色体长度不到 100 cM，可把位置量化为 1/100 cM，使用 uint16 保存 0..10000。founder_haplotype_id 若少于 65535 也可 uint16。一个无突变 Segment 只需约 4 字节核心数据。

```text
Packed segment (conceptual):
  start_cm_x100 : uint16
  founder_id    : uint16

Haplotype blob:
  segment_count : uint16
  segments[]
  variant_count : uint16
  variants[]
```

即使经过 20 代后每条单倍型平均约 15~25 个片段，单株 6 条单倍型的核心祖源数据仍可控制在几百字节到约 1 KB 量级。真正需要警惕的是 GDScript 对象开销，而不是理论数据本身。

## 14.3 片段增长控制

- 每次重组后立即 merge 相邻 founder_id 相同的 Segment。
- 对非常接近的 crossover（例如量化后同一点）去重。
- 不保存“end”；end 由下一 Segment.start 或染色体长度推导。
- Founder ancestry 与 mutation 分离，不因突变产生新的 Founder Segment。
- 存档可按 cohort 分块压缩；读取当前世代时不加载全部历史基因组。

## 14.4 PlantRecord 扁平索引

```text
plant_id -> row index
parent_a_ids: PackedInt64Array
parent_b_ids: PackedInt64Array
generation: PackedInt32Array
birth_event_ids: PackedInt64Array
genome_offsets: PackedInt64Array
phenotype_summary_offsets: PackedInt64Array
```

这样完整家谱关系可以长期常驻内存，而历史 Genome blob 按需从磁盘加载。

# 15. 随机数与可重现性

育种模拟必须可重现，否则 bug 极难定位。每次 mating event 分配 event_id，后代第 i 株的两个配子使用独立派生种子。不要让结果依赖“循环顺序”或 UI 是否提前查询某个随机值。

```text
seed_gamete_a = Hash64(run_seed, event_id, offspring_index, 0)
seed_gamete_b = Hash64(run_seed, event_id, offspring_index, 1)
seed_env       = Hash64(run_seed, trial_id, plant_id, replicate_id)
seed_mutation  = Hash64(run_seed, event_id, offspring_index, 99)
```

MVP 可以用 Godot RandomNumberGenerator 并固定 state；如果要求跨 Godot 版本、跨平台长期严格重放，建议以后内置一个明确版本的 PRNG，并把 prng_algorithm_version 写入存档。

# 16. 关键算法接口（GDScript 风格伪代码）

## 16.1 基因型剂量

```gdscript
func allele_dosage(genome: Genome, locus: LocusDef, target_allele: int) -> int:
    var a = get_allele(genome.homolog_a[locus.chr], locus)
    var b = get_allele(genome.homolog_b[locus.chr], locus)
    return int(a == target_allele) + int(b == target_allele)
```

## 16.2 QTL effect

```gdscript
func qtl_effect(dosage: int, additive: float, dominance: float) -> float:
    var z = float(dosage - 1)
    return additive * z + (dominance if dosage == 1 else 0.0)
```

## 16.3 GeneticProfile 构建

```gdscript
func build_genetic_profile(genome: Genome) -> GeneticProfile:
    var p = species.base_profile.duplicate()

    for locus in species.major_loci:
        var gt = get_genotype_code(genome, locus)
        apply_major_effect_table(p, locus, gt)

    for qtl in species.qtl_loci:
        var dose = allele_dosage(genome, qtl, qtl.effect_allele)
        for trait_id in qtl.additive_effects:
            p[trait_id] += qtl_effect(
                dose,
                qtl.additive_effects[trait_id],
                qtl.dominance_effects.get(trait_id, 0.0)
            )

    for rule in species.epistasis_rules:
        if rule.matches(genome):
            rule.apply(p)

    return finalize_profile_ranges(p)
```

## 16.4 表型计算

```gdscript
func phenotype(profile: GeneticProfile, env: EnvironmentDef, rng) -> Phenotype:
    var water = clamp(1.0 - env.water_stress * (0.75 - 0.0065 * profile.drought_score), 0.20, 1.05)
    var heat  = clamp(1.0 - env.heat_stress  * (0.65 - 0.0055 * profile.heat_score), 0.25, 1.05)
    var dis_a = clamp(1.0 - env.pathogen_A_pressure * (0.65 - 0.0055 * profile.resistance_A), 0.25, 1.0)
    var dis_b = clamp(1.0 - env.pathogen_B_pressure * (0.65 - 0.0055 * profile.resistance_B), 0.25, 1.0)

    var season = 1.0
    if profile.maturity_days > env.season_length_days:
        season = max(0.20, 1.0 - 0.06 * (profile.maturity_days - env.season_length_days))

    var shatter = 1.0 - env.harvest_delay * (1.0 - profile.shatter_resistance / 100.0) * 0.60

    var seeds = profile.seed_number_potential * profile.fertility_factor * water * heat * dis_a * dis_b * season
    var expected_yield = seeds * shatter * profile.seed_mass_mg / 1000.0

    var out = Phenotype.new()
    out.yield_g = max(0.0, expected_yield * (1.0 + rng.normal(0.0, env.sigma_yield_rel)))
    out.height_cm = profile.height_cm + rng.normal(0.0, env.sigma_height_cm)
    out.maturity_days = round(profile.maturity_days + rng.normal(0.0, env.sigma_maturity_days))
    out.seed_mass_mg = max(0.1, profile.seed_mass_mg + rng.normal(0.0, env.sigma_seed_mass_mg))
    out.drought_score = profile.drought_score
    out.disease_score = weighted_disease_display(profile, env)
    return out
```

## 16.5 祖源区间查询

```gdscript
func ancestry_at(hap: Haplotype, position_cm: float) -> int:
    var lo = 0
    var hi = hap.segments.size()
    while lo < hi:
        var mid = (lo + hi) >> 1
        if hap.segments[mid].start_cm <= position_cm:
            lo = mid + 1
        else:
            hi = mid
    return hap.segments[max(0, lo - 1)].founder_haplotype_id
```

# 17. 存档格式与版本管理

不要直接序列化 Godot 对象图作为长期存档格式。建议存档按“定义版本 + 索引表 + genome blob + event log”组织。

```text
save_root/
  manifest.json
  plants.bin
  genomes.bin
  events.bin
  trials.bin
  mutations.bin

manifest:
  save_format_version
  species_definition_version
  prng_algorithm_version
  run_seed
  next_plant_id
  next_event_id
  active_cohort_ids[]
```

- species_definition_version 必须固定；若平衡补丁修改基因效果，应提供迁移策略或把旧定义嵌入存档。
- Plant ID 永不复用。删除 UI 对象不代表删除历史记录。
- Genome blob 使用 offset 索引，便于随机读取。
- 事件日志只保存玩家/系统重要事件，不依赖它重建基因组；Genome 是事实源。
- 自动保存使用临时文件 + 原子替换，避免中断造成整档损坏。

# 18. 验证与自动化测试

## 18.1 遗传正确性测试

| 测试 | 构造 | 通过标准 |
| --- | --- | --- |
| T1 单位点 F1 | AA × aa，1000 后代 | 100% Aa（突变关闭）。 |
| T2 自交分离 | Aa 自交，100k 后代 | AA:Aa:aa 接近 1:2:1；卡方/误差阈值通过。 |
| T3 6 cM 重组 | 相位 AB/ab，位点距 6 cM，100k 配子 | 重组型约 5.65%，允许统计误差。 |
| T4 不连锁 | 两个不同染色体位点 | 配子组合接近独立，r≈0.5。 |
| T5 纯合自交 | 所有位点纯合 | 无突变时所有后代 genotype 相同。 |
| T6 Segment 覆盖 | 随机重组 100k 次 | 每个 haplotype 从 0 到 chr length 无缝覆盖，无重叠/空洞。 |
| T7 Variant 继承 | 突变位点位于已知区间 | 只有继承该区间的配子携带 mutation。 |
| T8 祖源和 | 任意个体 | 所有 founder ancestry 比例总和 = 1 ± 数值误差。 |

## 18.2 表型测试

| 测试 | 通过标准 |
| --- | --- |
| 环境单调性 | 同一 genotype，water_stress 增加时平均产量不应上升；高 drought_score 的下降斜率更小。 |
| HOT G×E | 无热时 H/h 差异接近 0；高热时 H 明显优于 h。 |
| FRT | ff 的平均 seed set 接近 FF 的 65%，其余因素相同。 |
| SIZ 权衡 | S 提高单粒重但降低 seed_number；总产结果依背景而定。 |
| 噪声 | 重复 10k 次，观测均值接近 expected；标准差接近配置值。 |

## 18.3 确定性测试

- 同一 run_seed + event_id + offspring_index 必须生成完全相同 Genome。
- 改变 UI 浏览顺序不应改变后续后代。
- 批量并行/分批处理如果未来加入，也不得改变每个 offspring_index 的结果。
- 保存/读取后继续同一事件，结果必须一致。

## 18.4 性能基准

| 规模 | 目标 |
| --- | --- |
| 5,000 株 F2 | 普通 PC 上可即时或接近即时生成；UI 不创建 5,000 个节点。 |
| 50,000 配子 | 用于遗传测试/后台筛选，内存稳定，无 Segment 泄漏。 |
| 100,000 历史 PlantRecord | 谱系父母索引可常驻；Genome 按需加载。 |
| 20 代连续自交/杂交 | 平均 Segment 数受 merge 控制，不出现指数增长。 |

# 19. 实施顺序（MVP → 完整版）

## 19.1 MVP-0：只验证重组是否“好玩”

- 3 条染色体。
- 只实现 8 个主要基因：YLD1、HGT、DRY、ROOT、RES2、FRT、SHAT、CLR。
- 2 个创始纯系。
- cross/self、Segment、祖源视图。
- 任务：从 Y-T 相位中找到 Y-t 重组体。
- 暂时不做 QTL、环境噪声和突变。

## 19.2 MVP-1：育种循环

- 扩充到 18 个主要基因 + 12 个 QTL。
- 4 创始品系、3 种环境。
- 完整 phenotype()、候选筛选、家系记录。
- F1→F2→选择→自交固定→品系试验。

## 19.3 MVP-2：研究与探索

- 扩充到 30 QTL。
- QTL 区间发现、marker、置信度。
- 回交导入抗病片段。
- 突变 registry。
- 完整 pedigree + chromosome ancestry 时间线。

## 19.4 暂缓功能

- 真实物理基因组坐标。
- 多倍体。
- 结构变异。
- 复杂 crossover interference。
- 复杂机器学习育种值预测。
- 把 1000 株都可视化成场景对象。

# 20. 三个用于验证系统深度的标准育种任务

## 20.1 任务 A：拆开高产-高秆连锁

亲本金穗携带 Y-T，沙叶携带 y-t。F1 相位为 YT/yt。玩家自交产生 F2，系统在 YLD1 与 HGT 之间发生约 5.65% 的配子重组。玩家要找到 Y-t 染色体并进一步自交固定。

- 验证点：连锁、重组、相位、F2 分离、自交固定。
- 玩家奖励：发现“关键重组”事件；染色体视图明确显示 crossover 位于 41~47 cM。
- 无作弊要求：不存在“第 3 代保底”；结果来自正常重组，可通过提高群体规模增加机会。

## 20.2 任务 B：从铁盾导入抗病，同时去掉落粒

铁盾 Chr3 携带 RES2=B，同时带 FRT=f、SHAT=s。玩家把铁盾与商业背景杂交，再连续回交。目标是保留包含 B 的最小供体片段，并恢复 F、N。

- 验证点：回交、供体片段缩短、祖源比例、连锁拖累。
- 玩家奖励：商业品系最终可能只有 5%~10% 铁盾祖源，但关键 RES2 片段保留。
- 谱系价值：可精确显示抗病片段首次由哪次杂交导入。

## 20.3 任务 C：同一品种无法统治所有环境

设置三种环境：长季湿润、短季干旱、高温病害。让 FLR、DRY/ROOT、HOT、RES1/RES2 的价值发生明显变化。玩家会自然形成多个品种，而不是追求唯一超级基因型。

| 环境 | 压力 | 偏好 |
| --- | --- | --- |
| 温润长季 | 低水分/低热/低病 | 晚熟高产、品质型；耐旱基因收益低。 |
| 短季干旱 | 高水分压力、季节短 | 早熟 + DRY/ROOT；极晚熟会直接减产。 |
| 高温病害 | 热 + 病原 A/B | HOT + RES 组合；高产但无抗性材料表现崩溃。 |

# 21. 平衡参数与调参原则

- 主效基因应该“能被玩家感知”，单个位点对目标性状的影响通常应大于一次环境噪声的标准差。
- QTL 单个效应应小于主效基因，但 5~10 个 QTL 叠加足以改变排名。
- 紧密连锁难题建议 4~10 cM；低于 2 cM 会要求过大群体，超过 15 cM 则很快拆开。
- 重要负面性状不要纯粹做惩罚：它们应与某个优势材料/连锁片段绑定，从而产生明确育种目标。
- 不要把突变设为必要通关条件；突变适合作为惊喜和长线内容。
- 玩家单次操作后应快速看到候选，不应真实等待多代；“时间成本”由资源与选择压力表达，而不是现实等待。

# 22. 核心不变量（实现时必须断言）

```text
Genome invariants:
1. 每条 Haplotype 至少 1 个 Segment，segments[0].start_cm == 0。
2. Segment.start_cm 严格递增。
3. 相邻 Segment 的 founder_haplotype_id 不相同（已 merge）。
4. 所有 start_cm 在 [0, chromosome_length) 内。
5. Variant.position_cm 在 [0, chromosome_length] 内且排序。
6. Genome 每条染色体恰好 2 条 homolog。

Pedigree invariants:
7. plant_id 单调递增且永不复用。
8. parent_id < child_id（创始材料 parent=0）。
9. 自交允许 parent_a == parent_b。

Simulation invariants:
10. 相同 seed contract => 相同 Genome。
11. phenotype deterministic part 不使用全局 RNG。
12. definition data 在一次存档生命周期内不可静默变化。
```

# 附录 A：推荐数据 Schema

```gdscript
LocusDefinition:
  id: int
  code: StringName
  chromosome_id: int
  position_cm: float
  kind: MAJOR | QTL | MARKER
  allele_ids: PackedInt32Array
  effect_allele: int
  additive_effects: Dictionary[TraitId, float]
  dominance_effects: Dictionary[TraitId, float]
  genotype_effect_table: Dictionary[int, EffectBundle] # major loci
  hidden_until_researched: bool

ChromosomeDefinition:
  id: int
  code: StringName
  length_cm: float
  locus_ids_sorted: PackedInt32Array

FounderDefinition:
  id: int
  name: String
  founder_haplotype_ids: PackedInt32Array # 3 chr
  visible_description: String

TraitDefinition:
  id: int
  code: StringName
  display_name: String
  unit: String
  display_min/max: float
  player_visible: bool
  noise_model: ...
```

# 附录 B：建议环境预设

| 环境 | season | water | heat | path A | path B | delay | 用途 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E0 温润标准 | 52 | 0.15 | 0.10 | 0.05 | 0.05 | 0.10 | 基础筛选/教程 |
| E1 短季干旱 | 43 | 0.80 | 0.25 | 0.05 | 0.05 | 0.15 | DRY/ROOT/FLR |
| E2 高温病害 | 48 | 0.35 | 0.80 | 0.60 | 0.45 | 0.10 | HOT/RES1/RES2 |
| E3 延迟收获 | 52 | 0.20 | 0.15 | 0.05 | 0.05 | 0.85 | SHAT/MAT |

# 附录 C：第一版完成定义（Definition of Done）

- 可以从 4 个创始纯系生成任意杂交、自交、回交后代。
- F2 单位点比例与 6 cM 重组率通过统计测试。
- 任何候选个体可打开 3 条染色体，看到两个 homolog 的 founder 祖源分段。
- 任何候选个体可查询父母并向上追溯至少 10 代。
- YLD1-HGT 与 RES2-FRT-SHAT 两个连锁难题确实可以通过真实 crossover 拆解。
- 同一 genotype 在 E0/E1/E2 中产生明显不同的排名。
- 批量 5000 株不会创建 Node，不发生明显 UI 卡顿或内存失控。
- 保存/读取后继续自交，使用同一随机种子合同能复现实验结果。
- 玩家可以最终命名一个稳定品系，并在品系详情看到真实谱系与染色体祖源。

# 附录 D：开发决策摘要

| 问题 | 决定 |
| --- | --- |
| 是否模拟碱基序列？ | 否。使用遗传坐标 + founder segments + sparse variants。 |
| 是否硬编码 F2/F3？ | 否。全部由两次减数分裂 + 受精自然产生。 |
| 重组模型？ | MVP 使用 Poisson/Haldane；将来可升级 Gamma interference。 |
| QTL 数量？ | 首发 30，玩家无需全部知道。 |
| 谱系是否完整？ | 是：所有 PlantRecord 保留父母 ID；Genome 可按存档策略压缩归档。 |
| Godot 是否足够？ | 足够。关键是数据导向存储，而不是把植物实例化为 Node。 |
| 最先验证什么？ | YLD1-HGT 罕见重组是否能给玩家形成强烈“这是我育出来的”反馈。 |

> **推荐的第一行代码：先实现 Segment/Haplotype + make_gamete_chromosome()，再写 6 cM 重组率自动测试。只要这层正确，后面的自交、回交、谱系和性状都会建立在稳定核心上。**
