<div align="center">
  <img src="icon.svg" width="112" alt="Stellacress 图标">
  <h1>Stellacress · 星芥</h1>
  <p>基于真实遗传重组、数量性状与环境互作的 2D 植物育种模拟项目。</p>
</div>

## 项目简介

Stellacress 是使用 Godot 4.7.1 与 GDScript 2.0 开发的 Windows 桌面育种游戏。玩家从四个纯合创始系出发，通过杂交、自交、回交、群体筛选和多环境试验，将目标等位基因与有利 QTL 重组到稳定品系中。

项目不模拟逐碱基 DNA，而以染色体区间、遗传距离和祖源片段表达二倍体基因组。所有后代都由确定性减数分裂模型生成，同一种子与事件索引会得到相同结果。

## 核心内容

- 3 条染色体、18 个主效基因与 30 个 QTL。
- Goldspike、Sandleaf、Ironshield、Whitepearl 四个纯合创始系。
- E0–E3 四种环境，以及水分、热、病害、季节和 G×E 表型模型。
- 杂交、自交、回交与最多 5000 株的批量后代生成。
- 硬筛选、Pareto 前沿、48 位点 IBS 多样性保护与罕见重组展示。
- 祖源片段、重组边界、基因位点和 A/B 单倍型染色体图谱。
- 多重复环境试验、均值与标准误、跨环境排名和 QTL 研究解锁。
- 三项渐进任务、稳定品系命名、谱系追踪和突变记录。
- 基因组工坊：可分别编辑 A/B 单倍型，创建纯合或杂合自定义材料。
- 新手引导与可搜索的教程百科。
- 数量不限的本地档案、安全删档与自动保存。
- 可缩放窗口、响应式布局，以及按钮或 `F11` 全屏切换。

## 开始运行

### 环境要求

- Windows 10/11 x64
- [Godot Engine 4.7.1](https://godotengine.org/download/archive/4.7.1-stable/)

项目仅使用 GDScript，无第三方插件。克隆仓库后，在 Godot 项目管理器中导入根目录的 `project.godot`，然后运行主场景即可。

```powershell
git clone https://github.com/1os3/Stellacress.git
cd Stellacress
godot --editor --path .
```

如果 `godot` 不在 PATH 中，请将命令替换为本机 Godot 可执行文件的完整路径。

## 自动化测试

项目包含无第三方测试框架的 headless 回归套件：

```powershell
godot --headless --path . --script res://tests/test_runner.gd
```

当前套件覆盖定义加载、孟德尔分离、Haldane 重组率、跨染色体独立分配、祖源不变量、确定性、表型、研究、教程、基因组工坊、任务、档案和场景实例化。

性能基准：

```powershell
godot --headless --path . --script res://devtools/benchmark.gd
```

## Windows 导出

仓库已经提供 `export_presets.cfg`。在 Godot 中安装对应版本的 Windows 导出模板后，可使用编辑器导出，或从命令行生成发布版：

```powershell
godot --headless --path . --export-release "Windows Desktop" "Publish/Stellacress.exe"
```

`Publish/` 与本地 Godot 编辑器不会提交到源码仓库，适合通过 GitHub Releases 分发构建产物。

## 项目结构

```text
autoload/               应用协调器与页面状态
data/species/           物种定义和平衡数据
gameplay/               任务、新手引导与教程内容
genetics/definitions/   只读遗传定义
genetics/engines/       减数分裂、育种、表型、筛选等核心服务
genetics/runtime/       Genome、Haplotype、Segment 等运行时数据
storage/                档案、植物和基因组持久化
ui/                     主界面与程序化染色体图谱
tests/                  Headless 回归测试
devtools/               性能与视觉验收工具
Doc/                    开发、平衡、存档、测试和教程文档
```

## 设计与文档

- [文档索引](Doc/Index.md)
- [遗传系统技术设计](Stellacress_Genetics_Technical_Design.md)
- [开发规范](Doc/开发规范.md)
- [平衡参数](Doc/平衡参数.md)
- [存档格式](Doc/存档格式.md)
- [测试说明](Doc/测试说明.md)
- [新手指南](Doc/新手指南.md)
- [教程百科](Doc/教程百科.md)

## 许可证

本项目采用 [Apache License 2.0](LICENSE)。
