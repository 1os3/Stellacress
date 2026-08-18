# Stellacress 文档索引

- [开发规范](开发规范.md)：代码、数据、存档、测试与资源的强制约定。
- [遗传技术设计](../Stellacress_Genetics_Technical_Design.md)：物种、遗传模型、性状公式、谱系和完成定义。
- [平衡参数](平衡参数.md)：首版补齐的基因、QTL、创始系和环境数值原则。
- [存档格式](存档格式.md)：格式版本 1 的文件组成与兼容策略。
- [测试说明](测试说明.md)：自动化回归与性能基准运行方式。
- [新手指南](新手指南.md)：交互教程、染色体图谱读法与基因组工坊。
- [教程百科](教程百科.md)：概念、玩法、工具和任务教程的覆盖范围。

## 重要入口

- `res://scenes/main.tscn`：游戏主场景。
- `res://autoload/app_controller.gd`：唯一应用级协调器。
- `res://data/species/stellacress.json`：首版物种与平衡参数唯一数据源。
- `res://tests/test_runner.gd`：headless 自动化回归入口。
