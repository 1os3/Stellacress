extends Control

const BACKGROUND: Color = Color("0b1219")
const PANEL: Color = Color("14232e")
const PANEL_LIGHT: Color = Color("1b3040")
const ACCENT: Color = Color("55d6a9")
const TEXT: Color = Color("e9f1ed")
const MUTED: Color = Color("98abb3")

var menu_root: Control
var workspace_root: Control
var new_name_edit: LineEdit
var archive_list: VBoxContainer
var delete_dialog: ConfirmationDialog
var pending_delete_archive_id: int = 0
var main_tabs: TabContainer
var parent_a_option: OptionButton
var parent_b_option: OptionButton
var operation_option: OptionButton
var population_option: OptionButton
var population_custom: SpinBox
var environment_option: OptionButton
var max_maturity_spin: SpinBox
var yield_weight_spin: SpinBox
var drought_weight_spin: SpinBox
var quality_weight_spin: SpinBox
var generate_button: Button
var progress_bar: ProgressBar
var candidate_list: ItemList
var detail_title: Label
var detail_metrics: RichTextLabel
var detail_genotypes: RichTextLabel
var chromosome_view: ChromosomeView
var trial_plant_option: OptionButton
var trial_environment_option: OptionButton
var trial_replicates: SpinBox
var trial_results: RichTextLabel
var research_results: RichTextLabel
var task_results: RichTextLabel
var line_name_edit: LineEdit
var line_status: Label
var tutorial_panel: PanelContainer
var tutorial_title: Label
var tutorial_text: RichTextLabel
var tutorial_progress: Label
var tutorial_center: PanelContainer
var tutorial_topic_list: ItemList
var tutorial_search: LineEdit
var tutorial_article_title: Label
var tutorial_article_body: RichTextLabel
var visible_tutorial_topics: Array[Dictionary] = []
var fullscreen_button: Button
var genome_base_option: OptionButton
var genome_name_edit: LineEdit
var genome_grid: GridContainer
var genome_rows: Dictionary = {}
var genome_status: Label
var selected_plant_id: int = 0

func _ready() -> void:
	RenderingServer.set_default_clear_color(BACKGROUND)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_theme()
	_build_menu()
	_build_workspace()
	_build_tutorial_panel()
	_build_tutorial_center()
	workspace_root.hide()
	tutorial_panel.hide()
	tutorial_center.hide()
	AppController.game_ready.connect(_on_game_ready)
	AppController.breeding_progress.connect(_on_breeding_progress)
	AppController.breeding_completed.connect(_on_breeding_completed)
	AppController.state_changed.connect(_refresh_all)
	AppController.research_updated.connect(_refresh_genome_designer)
	AppController.save_completed.connect(func(_slot: int) -> void: line_status.text = "已保存")
	AppController.save_failed.connect(func(message: String) -> void: line_status.text = "保存失败：" + message)
	get_window().size_changed.connect(_refresh_fullscreen_button)

func _build_theme() -> void:
	var app_theme := Theme.new()
	app_theme.default_font_size = 16
	app_theme.set_color("font_color", "Label", TEXT)
	app_theme.set_color("font_color", "Button", TEXT)
	app_theme.set_color("font_color", "LineEdit", TEXT)
	app_theme.set_color("font_color", "OptionButton", TEXT)
	app_theme.set_color("font_color", "TabContainer", TEXT)
	app_theme.set_color("font_color", "ItemList", TEXT)
	app_theme.set_color("font_selected_color", "ItemList", Color("07100d"))
	app_theme.set_color("font_hovered_color", "Button", Color.WHITE)
	app_theme.set_color("font_pressed_color", "Button", Color.WHITE)
	app_theme.set_color("font_hover_color", "Button", Color.WHITE)
	app_theme.set_stylebox("normal", "Button", _style(PANEL_LIGHT, 8, Color("294657")))
	app_theme.set_stylebox("hover", "Button", _style(Color("24465a"), 8, ACCENT))
	app_theme.set_stylebox("pressed", "Button", _style(Color("286852"), 8, ACCENT))
	app_theme.set_stylebox("normal", "LineEdit", _style(Color("0e1b24"), 7, Color("315064")))
	app_theme.set_stylebox("focus", "LineEdit", _style(Color("0e1b24"), 7, ACCENT))
	app_theme.set_stylebox("normal", "ItemList", _style(Color("0f1d26"), 7, Color("274353")))
	app_theme.set_stylebox("selected", "ItemList", _style(ACCENT, 6))
	app_theme.set_stylebox("panel", "TabContainer", _style(PANEL, 9, Color("274353")))
	theme = app_theme

func _build_menu() -> void:
	menu_root = Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_root)
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(background)
	var glow := ColorRect.new()
	glow.color = Color("142d33")
	glow.position = Vector2(0, 0)
	glow.size = Vector2(460, 900)
	menu_root.add_child(glow)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(PANEL, 16, Color("2c4a58")))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-300, -330)
	card.size = Vector2(600, 660)
	menu_root.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.add_theme_constant_override("margin_left", 32)
	card.add_child(content)
	var eyebrow := Label.new()
	eyebrow.text = "STELLACRESS  ·  遗传育种实验室"
	eyebrow.add_theme_color_override("font_color", ACCENT)
	eyebrow.add_theme_font_size_override("font_size", 15)
	content.add_child(eyebrow)
	var title := Label.new()
	title.text = "星芥"
	title.add_theme_font_size_override("font_size", 58)
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "从一段真实的重组开始，培育属于你的稳定品系。"
	subtitle.add_theme_color_override("font_color", MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(subtitle)
	content.add_child(HSeparator.new())
	new_name_edit = LineEdit.new()
	new_name_edit.placeholder_text = "新档案名称"
	new_name_edit.text = "我的星芥计划"
	new_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(new_name_edit)
	var task_button := Button.new()
	task_button.text = "开始引导任务"
	task_button.custom_minimum_size.y = 52
	task_button.pressed.connect(_start_new_game.bind(&"tasks"))
	content.add_child(task_button)
	var sandbox_button := Button.new()
	sandbox_button.text = "开始自由育种"
	sandbox_button.custom_minimum_size.y = 48
	sandbox_button.pressed.connect(_start_new_game.bind(&"sandbox"))
	content.add_child(sandbox_button)
	var encyclopedia_button := Button.new()
	encyclopedia_button.text = "查看教程百科"
	encyclopedia_button.pressed.connect(_open_tutorial_center)
	content.add_child(encyclopedia_button)
	var save_label := Label.new()
	save_label.text = "档案（数量不限）"
	save_label.add_theme_color_override("font_color", MUTED)
	content.add_child(save_label)
	var archive_scroll := ScrollContainer.new()
	archive_scroll.custom_minimum_size.y = 160
	archive_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(archive_scroll)
	archive_list = VBoxContainer.new()
	archive_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	archive_scroll.add_child(archive_list)
	delete_dialog = ConfirmationDialog.new()
	delete_dialog.title = "删除档案"
	delete_dialog.ok_button_text = "永久删除"
	delete_dialog.cancel_button_text = "取消"
	delete_dialog.confirmed.connect(_confirm_delete_archive)
	add_child(delete_dialog)
	_refresh_archive_list()

func _build_workspace() -> void:
	workspace_root = VBoxContainer.new()
	workspace_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	workspace_root.add_theme_constant_override("separation", 0)
	add_child(workspace_root)
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	workspace_root.add_child(background)
	background.show_behind_parent = true
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 70
	header.add_theme_constant_override("separation", 18)
	workspace_root.add_child(header)
	var brand := Label.new()
	brand.text = "  星芥  /  育种工作台"
	brand.add_theme_font_size_override("font_size", 24)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	var save_button := Button.new()
	save_button.text = "保存"
	save_button.pressed.connect(AppController.save_current)
	header.add_child(save_button)
	var tutorial_button := Button.new()
	tutorial_button.text = "新手引导"
	tutorial_button.pressed.connect(func() -> void:
		AppController.tutorial_service.reopen()
		_refresh_tutorial()
	)
	header.add_child(tutorial_button)
	var encyclopedia_button := Button.new()
	encyclopedia_button.text = "教程百科"
	encyclopedia_button.pressed.connect(_open_tutorial_center)
	header.add_child(encyclopedia_button)
	fullscreen_button = Button.new()
	fullscreen_button.tooltip_text = "切换全屏，也可按 F11"
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	header.add_child(fullscreen_button)
	_refresh_fullscreen_button()
	var menu_button := Button.new()
	menu_button.text = "主菜单  "
	menu_button.pressed.connect(_show_main_menu)
	header.add_child(menu_button)
	main_tabs = TabContainer.new()
	main_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_tabs.add_theme_constant_override("side_margin", 16)
	workspace_root.add_child(main_tabs)
	_build_breeding_tab(main_tabs)
	_build_trial_tab(main_tabs)
	_build_task_tab(main_tabs)
	_build_genome_tab(main_tabs)

func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_F11:
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()

func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
	_refresh_fullscreen_button.call_deferred()

func _refresh_fullscreen_button() -> void:
	if fullscreen_button == null:
		return
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	fullscreen_button.text = "退出全屏  F11" if is_fullscreen else "全屏  F11"

func _build_breeding_tab(tabs: TabContainer) -> void:
	var root := HSplitContainer.new()
	root.name = "育种与候选"
	root.split_offset = 380
	tabs.add_child(root)
	var left_scroll := ScrollContainer.new()
	left_scroll.custom_minimum_size.x = 360
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(left_scroll)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 360
	left.add_theme_constant_override("separation", 10)
	left_scroll.add_child(left)
	left.add_child(_section_label("育种设置"))
	parent_a_option = _labeled_option(left, "亲本 A")
	parent_b_option = _labeled_option(left, "亲本 B")
	operation_option = _labeled_option(left, "操作")
	for item: String in ["杂交", "自交", "回交"]: operation_option.add_item(item)
	population_option = _labeled_option(left, "群体规模")
	for amount: int in [100, 500, 1200, 5000]: population_option.add_item(str(amount), amount)
	population_option.add_item("自定义", 0)
	population_option.select(1)
	population_option.item_selected.connect(func(index: int) -> void: population_custom.visible = population_option.get_item_id(index) == 0)
	population_custom = SpinBox.new()
	population_custom.min_value = 1
	population_custom.max_value = 5000
	population_custom.value = 750
	population_custom.suffix = " 株"
	population_custom.visible = false
	left.add_child(population_custom)
	environment_option = _labeled_option(left, "筛选环境")
	var filter_grid := GridContainer.new()
	filter_grid.columns = 2
	left.add_child(filter_grid)
	var maturity_label := Label.new(); maturity_label.text = "最晚成熟"; maturity_label.add_theme_color_override("font_color", MUTED); filter_grid.add_child(maturity_label)
	max_maturity_spin = SpinBox.new(); max_maturity_spin.min_value = 35; max_maturity_spin.max_value = 80; max_maturity_spin.value = 60; max_maturity_spin.suffix = " 天"; filter_grid.add_child(max_maturity_spin)
	var weights_label := Label.new(); weights_label.text = "目标权重（产量 / 耐旱 / 品质）"; weights_label.add_theme_color_override("font_color", MUTED); left.add_child(weights_label)
	var weight_row := HBoxContainer.new(); left.add_child(weight_row)
	yield_weight_spin = _weight_spin(1.0); weight_row.add_child(yield_weight_spin)
	drought_weight_spin = _weight_spin(0.4); weight_row.add_child(drought_weight_spin)
	quality_weight_spin = _weight_spin(0.3); weight_row.add_child(quality_weight_spin)
	generate_button = Button.new()
	generate_button.text = "生成后代并筛选"
	generate_button.custom_minimum_size.y = 50
	generate_button.pressed.connect(_generate_population)
	left.add_child(generate_button)
	progress_bar = ProgressBar.new()
	progress_bar.max_value = 100
	progress_bar.show_percentage = true
	left.add_child(progress_bar)
	left.add_child(_section_label("推荐候选（最多 20）"))
	candidate_list = ItemList.new()
	candidate_list.custom_minimum_size.y = 190
	candidate_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	candidate_list.item_selected.connect(_show_candidate)
	left.add_child(candidate_list)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(detail_scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 12)
	detail_scroll.add_child(detail)
	detail_title = Label.new()
	detail_title.text = "选择候选"
	detail_title.add_theme_font_size_override("font_size", 28)
	detail.add_child(detail_title)
	detail_metrics = RichTextLabel.new()
	detail_metrics.bbcode_enabled = true
	detail_metrics.fit_content = true
	detail_metrics.custom_minimum_size.y = 130
	detail.add_child(detail_metrics)
	detail_genotypes = RichTextLabel.new()
	detail_genotypes.bbcode_enabled = true
	detail_genotypes.fit_content = true
	detail_genotypes.custom_minimum_size.y = 72
	detail.add_child(detail_genotypes)
	var chromosome_help := Label.new()
	chromosome_help.text = "染色体读法：每组 A/B 是两个同源副本；颜色表示创始祖源；交界线是重组点；红点是突变。将鼠标停在图上可查看位置和基因型。"
	chromosome_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chromosome_help.add_theme_color_override("font_color", MUTED)
	detail.add_child(chromosome_help)
	var chromosome_tutorial_button := Button.new()
	chromosome_tutorial_button.text = "打开教程：染色体图谱与连锁"
	chromosome_tutorial_button.pressed.connect(_open_tutorial_center.bind(&"chromosome_map"))
	detail.add_child(chromosome_tutorial_button)
	chromosome_view = ChromosomeView.new()
	detail.add_child(chromosome_view)

func _build_trial_tab(tabs: TabContainer) -> void:
	var root := HBoxContainer.new()
	root.name = "试验与研究"
	root.add_theme_constant_override("separation", 20)
	tabs.add_child(root)
	var controls := VBoxContainer.new()
	controls.custom_minimum_size.x = 360
	root.add_child(controls)
	controls.add_child(_section_label("多环境重复试验"))
	var trial_tutorial_button := Button.new()
	trial_tutorial_button.text = "打开教程：重复试验与 QTL 研究"
	trial_tutorial_button.pressed.connect(_open_tutorial_center.bind(&"trials_research"))
	controls.add_child(trial_tutorial_button)
	trial_plant_option = _labeled_option(controls, "候选植株")
	trial_environment_option = _labeled_option(controls, "环境")
	var replicate_label := Label.new(); replicate_label.text = "重复次数"; controls.add_child(replicate_label)
	trial_replicates = SpinBox.new(); trial_replicates.min_value = 1; trial_replicates.max_value = 20; trial_replicates.value = 3; controls.add_child(trial_replicates)
	var run_button := Button.new(); run_button.text = "运行试验"; run_button.custom_minimum_size.y = 48; run_button.pressed.connect(_run_trial); controls.add_child(run_button)
	trial_results = RichTextLabel.new(); trial_results.bbcode_enabled = true; trial_results.fit_content = true; trial_results.custom_minimum_size.y = 240; controls.add_child(trial_results)
	var research_panel := VBoxContainer.new(); research_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; root.add_child(research_panel)
	research_panel.add_child(_section_label("QTL 研究进展"))
	research_results = RichTextLabel.new(); research_results.bbcode_enabled = true; research_results.size_flags_vertical = Control.SIZE_EXPAND_FILL; research_panel.add_child(research_results)

func _build_task_tab(tabs: TabContainer) -> void:
	var root := VBoxContainer.new()
	root.name = "任务与品系"
	root.add_theme_constant_override("separation", 14)
	tabs.add_child(root)
	root.add_child(_section_label("标准育种任务"))
	task_results = RichTextLabel.new(); task_results.bbcode_enabled = true; task_results.fit_content = true; task_results.custom_minimum_size.y = 260; root.add_child(task_results)
	root.add_child(_section_label("命名稳定品系"))
	var row := HBoxContainer.new(); root.add_child(row)
	line_name_edit = LineEdit.new(); line_name_edit.placeholder_text = "输入品系名（当前详情候选）"; line_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(line_name_edit)
	var name_button := Button.new(); name_button.text = "命名品系"; name_button.pressed.connect(_name_line); row.add_child(name_button)
	line_status = Label.new(); line_status.add_theme_color_override("font_color", ACCENT); root.add_child(line_status)

func _build_genome_tab(tabs: TabContainer) -> void:
	var root := HBoxContainer.new()
	root.name = "基因组工坊"
	root.add_theme_constant_override("separation", 18)
	tabs.add_child(root)
	var controls := VBoxContainer.new()
	controls.custom_minimum_size.x = 330
	controls.add_theme_constant_override("separation", 10)
	root.add_child(controls)
	controls.add_child(_section_label("创建自定义遗传材料"))
	var explanation := Label.new()
	explanation.text = "四个默认创始系均为纯合子。这里可分别设置同源 A/B 的等位基因，因此能创建纯合或杂合材料。自定义差异以 Variant 保存，不会改写物种定义。"
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_color_override("font_color", MUTED)
	controls.add_child(explanation)
	var workshop_tutorial_button := Button.new()
	workshop_tutorial_button.text = "打开教程：基因组工坊完整用法"
	workshop_tutorial_button.pressed.connect(_open_tutorial_center.bind(&"genome_workshop"))
	controls.add_child(workshop_tutorial_button)
	genome_name_edit = LineEdit.new()
	genome_name_edit.placeholder_text = "材料名称"
	genome_name_edit.text = "自定义材料"
	controls.add_child(genome_name_edit)
	genome_base_option = _labeled_option(controls, "基础祖源")
	genome_base_option.item_selected.connect(func(_index: int) -> void: _load_genome_base())
	var homozygous_button := Button.new()
	homozygous_button.text = "将 B 复制为 A（快速纯合）"
	homozygous_button.pressed.connect(_make_designer_homozygous)
	controls.add_child(homozygous_button)
	var create_button := Button.new()
	create_button.text = "创建材料并加入亲本库"
	create_button.custom_minimum_size.y = 50
	create_button.pressed.connect(_create_custom_material)
	controls.add_child(create_button)
	genome_status = Label.new()
	genome_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	genome_status.add_theme_color_override("font_color", ACCENT)
	controls.add_child(genome_status)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	genome_grid = GridContainer.new()
	genome_grid.columns = 4
	genome_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	genome_grid.add_theme_constant_override("h_separation", 12)
	genome_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(genome_grid)

func _build_tutorial_panel() -> void:
	tutorial_panel = PanelContainer.new()
	tutorial_panel.z_index = 20
	tutorial_panel.add_theme_stylebox_override("panel", _style(Color("18313b"), 12, ACCENT))
	tutorial_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tutorial_panel.offset_left = -430.0
	tutorial_panel.offset_right = -20.0
	tutorial_panel.offset_top = 88.0
	tutorial_panel.offset_bottom = 335.0
	add_child(tutorial_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	tutorial_panel.add_child(content)
	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	tutorial_title = Label.new()
	tutorial_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_title.add_theme_font_size_override("font_size", 20)
	tutorial_title.add_theme_color_override("font_color", ACCENT)
	title_row.add_child(tutorial_title)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.pressed.connect(func() -> void: AppController.tutorial_service.close(); _refresh_tutorial())
	title_row.add_child(close_button)
	tutorial_text = RichTextLabel.new()
	tutorial_text.bbcode_enabled = true
	tutorial_text.fit_content = true
	tutorial_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(tutorial_text)
	var footer := HBoxContainer.new()
	content.add_child(footer)
	tutorial_progress = Label.new()
	tutorial_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_progress.add_theme_color_override("font_color", MUTED)
	footer.add_child(tutorial_progress)
	var previous_button := Button.new()
	previous_button.text = "上一步"
	previous_button.pressed.connect(func() -> void: AppController.tutorial_service.previous_step(); _refresh_tutorial(); AppController.autosave())
	footer.add_child(previous_button)
	var next_button := Button.new()
	next_button.text = "下一步"
	next_button.pressed.connect(func() -> void: AppController.tutorial_service.next_step(); _refresh_tutorial(); AppController.autosave())
	footer.add_child(next_button)

func _build_tutorial_center() -> void:
	tutorial_center = PanelContainer.new()
	tutorial_center.z_index = 40
	tutorial_center.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_center.add_theme_stylebox_override("panel", _style(Color("101f29"), 14, Color("3f6573")))
	tutorial_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_center.offset_left = 52.0
	tutorial_center.offset_right = -52.0
	tutorial_center.offset_top = 42.0
	tutorial_center.offset_bottom = -42.0
	add_child(tutorial_center)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	tutorial_center.add_child(root)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var title := Label.new()
	title.text = "教程百科"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", ACCENT)
	header.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "概念 · 玩法 · 工具 · 任务攻略"
	subtitle.add_theme_color_override("font_color", MUTED)
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(subtitle)
	tutorial_search = LineEdit.new()
	tutorial_search.placeholder_text = "搜索教程……"
	tutorial_search.custom_minimum_size.x = 260
	tutorial_search.text_changed.connect(_refresh_tutorial_topics)
	header.add_child(tutorial_search)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.pressed.connect(_close_tutorial_center)
	header.add_child(close_button)
	var split := HSplitContainer.new()
	split.split_offset = 300
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)
	tutorial_topic_list = ItemList.new()
	tutorial_topic_list.custom_minimum_size.x = 290
	tutorial_topic_list.item_selected.connect(_show_tutorial_topic)
	split.add_child(tutorial_topic_list)
	var article := VBoxContainer.new()
	article.add_theme_constant_override("separation", 10)
	split.add_child(article)
	tutorial_article_title = Label.new()
	tutorial_article_title.add_theme_font_size_override("font_size", 26)
	tutorial_article_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	article.add_child(tutorial_article_title)
	article.add_child(HSeparator.new())
	tutorial_article_body = RichTextLabel.new()
	tutorial_article_body.bbcode_enabled = true
	tutorial_article_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tutorial_article_body.scroll_active = true
	tutorial_article_body.custom_minimum_size.x = 650
	article.add_child(tutorial_article_body)
	_refresh_tutorial_topics("")

func _on_game_ready() -> void:
	menu_root.hide()
	workspace_root.show()
	_refresh_genome_designer()
	_refresh_all()

func _refresh_all() -> void:
	if not AppController.has_game:
		return
	_refresh_parent_options()
	_refresh_environment_options()
	_refresh_candidates()
	_refresh_trials_and_research()
	_refresh_tasks()
	_refresh_tutorial()

func _refresh_parent_options() -> void:
	var previous_a := _selected_id(parent_a_option)
	var previous_b := _selected_id(parent_b_option)
	for option: OptionButton in [parent_a_option, parent_b_option, trial_plant_option]: option.clear()
	var pool: Array[PlantRecord] = []
	for plant: PlantRecord in AppController.plant_store.all_plants():
		if plant.is_founder: pool.append(plant)
	for plant: PlantRecord in AppController.candidates:
		if not pool.has(plant): pool.append(plant)
	for plant: PlantRecord in pool:
		parent_a_option.add_item(plant.display_name, plant.id)
		parent_b_option.add_item(plant.display_name, plant.id)
		trial_plant_option.add_item(plant.display_name, plant.id)
	_select_id(parent_a_option, previous_a)
	_select_id(parent_b_option, previous_b if previous_b > 0 else 2)

func _refresh_environment_options() -> void:
	if environment_option.item_count > 0:
		return
	for environment: EnvironmentDefinition in AppController.species.environments:
		environment_option.add_item("%s · %s" % [environment.code, environment.display_name], environment.id)
		trial_environment_option.add_item("%s · %s" % [environment.code, environment.display_name], environment.id)

func _refresh_candidates() -> void:
	candidate_list.clear()
	for plant: PlantRecord in AppController.candidates:
		var genome := AppController.genome_store.get_genome(plant.genome_ref)
		var profile := AppController.genetics_engine.build_genetic_profile(genome)
		var phenotype := AppController.phenotype_engine.expected_phenotype(profile, AppController.species.environment_by_code(AppController.current_environment_code))
		candidate_list.add_item("#%d  产量 %.2fg  耐旱 %.0f" % [plant.id, phenotype.expected_yield_g, phenotype.drought_score])
		candidate_list.set_item_metadata(candidate_list.item_count - 1, plant.id)

func _refresh_trials_and_research() -> void:
	var identified := 0
	var intervals := 0
	for finding: ResearchFinding in AppController.research_service.findings.values():
		if finding.reveal_level == ResearchFinding.RevealLevel.IDENTIFIED: identified += 1
		elif finding.reveal_level == ResearchFinding.RevealLevel.INTERVAL: intervals += 1
	var text := "[color=#55d6a9]已定位 QTL：%d / 30[/color]\n候选区间：%d\n\n" % [identified, intervals]
	for finding: ResearchFinding in AppController.research_service.findings.values():
		if finding.reveal_level == ResearchFinding.RevealLevel.HIDDEN: continue
		var locus := AppController.species.locus_by_id(finding.locus_id)
		text += "%s · Chr%d %.1f–%.1f cM · 置信度 %.0f%%\n" % [locus.code if finding.reveal_level == ResearchFinding.RevealLevel.IDENTIFIED else "未知 QTL", locus.chromosome_id, finding.interval_start_cm, finding.interval_end_cm, finding.confidence * 100.0]
	research_results.text = text

func _refresh_tasks() -> void:
	var completed := AppController.task_service.completed
	task_results.text = "[color=%s]任务 A[/color]  拆开 YLD1–HGT 连锁：YY / tt 稳定品系\n\n[color=%s]任务 B[/color]  导入 RES2，同时恢复 FF / NN，铁盾祖源 ≤10%%\n\n[color=%s]任务 C[/color]  E1 与 E2 各有不同的优势稳定品系" % [_task_color(bool(completed["A"])), _task_color(bool(completed["B"])), _task_color(bool(completed["C"]))]

func _generate_population() -> void:
	if parent_a_option.item_count == 0: return
	generate_button.disabled = true
	progress_bar.value = 0
	var operation: StringName = [&"cross", &"self", &"backcross"][operation_option.selected]
	var environment := AppController.species.environments[environment_option.selected]
	AppController.current_environment_code = environment.code
	AppController.selection_filters = {"max_maturity": max_maturity_spin.value, "min_fertility": 0.5}
	AppController.selection_weights = {"yield": yield_weight_spin.value, "drought": drought_weight_spin.value, "quality": quality_weight_spin.value}
	var population_count := population_option.get_item_id(population_option.selected)
	if population_count == 0: population_count = int(population_custom.value)
	AppController.generate_population(_selected_id(parent_a_option), _selected_id(parent_b_option), population_count, operation)

func _on_breeding_progress(completed: int, total: int) -> void:
	progress_bar.value = 100.0 * float(completed) / float(total)

func _on_breeding_completed(_ids: Array[int]) -> void:
	generate_button.disabled = false
	_refresh_all()

func _show_candidate(index: int) -> void:
	selected_plant_id = int(candidate_list.get_item_metadata(index))
	var plant := AppController.plant_store.get_plant(selected_plant_id)
	var genome := AppController.genome_store.get_genome(plant.genome_ref)
	var profile := AppController.genetics_engine.build_genetic_profile(genome)
	var phenotype := AppController.phenotype_engine.expected_phenotype(profile, AppController.species.environment_by_code(AppController.current_environment_code))
	detail_title.text = "%s  ·  G%d" % [plant.display_name, plant.generation]
	detail_metrics.text = "[color=#55d6a9][font_size=24]%.2f g[/font_size][/color]  预期单株产量\n成熟 %.0f 天  ·  株高 %.1f cm  ·  单粒 %.2f mg\n耐旱 %.0f  ·  耐热 %.0f  ·  抗病 %.0f  ·  品质 %.0f\n纯合度 %.1f%%  ·  父母 #%d / #%d" % [phenotype.expected_yield_g, phenotype.maturity_days, phenotype.height_cm, phenotype.seed_mass_mg, phenotype.drought_score, phenotype.heat_score, phenotype.disease_score, phenotype.quality_score, AppController.genetics_engine.homozygosity(genome) * 100.0, plant.parent_a_id, plant.parent_b_id]
	var genotype_parts := PackedStringArray()
	for locus: LocusDefinition in AppController.species.loci:
		if locus.kind == LocusDefinition.Kind.MAJOR or AppController.research_service.reveal_level_for(locus.id) == ResearchFinding.RevealLevel.IDENTIFIED:
			genotype_parts.append("%s=%s" % [locus.code, AppController.genetics_engine.genotype_label(genome, locus)])
	var ancestors := AppController.pedigree_service.get_ancestors(plant.id, 10)
	var ancestry := AppController.pedigree_service.genome_ancestry(plant.id)
	var ancestry_parts := PackedStringArray()
	for founder_id: int in ancestry:
		var founder := AppController.species.founder_by_id(founder_id)
		ancestry_parts.append("%s %.1f%%" % [founder.display_name.get_slice(" ", 0), float(ancestry[founder_id]) * 100.0])
	detail_genotypes.text = "[color=#98abb3]已知位点[/color]  %s\n[color=#98abb3]10 代祖先[/color] %d  ·  %s" % ["  ".join(genotype_parts), ancestors.size(), " / ".join(ancestry_parts)]
	chromosome_view.show_plant(selected_plant_id)
	AppController.tutorial_service.advance_to(4)
	_refresh_tutorial()

func _run_trial() -> void:
	if trial_plant_option.item_count == 0: return
	var plant_id := _selected_id(trial_plant_option)
	var environment := AppController.species.environments[trial_environment_option.selected]
	var trial := AppController.run_trial_for([plant_id], environment.code, int(trial_replicates.value))
	if trial == null: return
	var summary := AppController.trial_service.summary_for(trial, plant_id)
	trial_results.text = "[color=#55d6a9]试验 #%d 完成[/color]\n环境：%s\n平均产量：%.3f g\n标准误：%.3f\n重复：%d" % [trial.id, environment.display_name, summary["mean_yield_g"], summary["standard_error"], summary["replicates"]]

func _name_line() -> void:
	if selected_plant_id <= 0:
		line_status.text = "请先在候选列表选择一株植株"
		return
	var error := AppController.name_line(selected_plant_id, line_name_edit.text)
	line_status.text = error if not error.is_empty() else "品系命名成功"

func _load_slot(slot_index: int) -> void:
	var error := AppController.load_game(slot_index)
	if not error.is_empty():
		push_error(error)

func _start_new_game(mode: StringName) -> void:
	var plan_name := new_name_edit.text.strip_edges()
	if plan_name.is_empty(): plan_name = "星芥育种计划"
	var slot_index := AppController.save_service.allocate_archive_id()
	var seed_offset := 1 if mode == &"sandbox" else 0
	AppController.new_game(mode, AppController.DEFAULT_RUN_SEED + seed_offset + slot_index * 100, slot_index, plan_name)
	AppController.save_current()

func _show_main_menu() -> void:
	workspace_root.hide()
	tutorial_panel.hide()
	tutorial_center.hide()
	menu_root.show()
	_refresh_archive_list()

func _refresh_archive_list() -> void:
	if archive_list == null:
		return
	for child: Node in archive_list.get_children():
		archive_list.remove_child(child)
		child.queue_free()
	var summaries := AppController.save_service.archive_summaries()
	if summaries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "尚无档案。新游戏会自动创建独立档案。"
		empty_label.add_theme_color_override("font_color", MUTED)
		archive_list.add_child(empty_label)
		return
	for summary: Dictionary in summaries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		archive_list.add_child(row)
		var archive_id := int(summary["slot"])
		var load_button := Button.new()
		load_button.text = "%s  ·  #%d" % [summary.get("name", "未命名档案"), archive_id]
		load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		load_button.pressed.connect(_load_slot.bind(archive_id))
		row.add_child(load_button)
		var delete_button := Button.new()
		delete_button.text = "删除"
		delete_button.pressed.connect(_request_delete_archive.bind(archive_id, String(summary.get("name", "未命名档案"))))
		row.add_child(delete_button)

func _request_delete_archive(archive_id: int, archive_name: String) -> void:
	pending_delete_archive_id = archive_id
	delete_dialog.dialog_text = "确定永久删除档案“%s”吗？此操作无法撤销。" % archive_name
	delete_dialog.popup_centered(Vector2i(460, 170))

func _confirm_delete_archive() -> void:
	var error := AppController.delete_archive(pending_delete_archive_id)
	if not error.is_empty():
		push_error(error)
	pending_delete_archive_id = 0
	_refresh_archive_list()

func _refresh_tutorial() -> void:
	if tutorial_panel == null or not AppController.has_game or AppController.tutorial_service == null:
		if tutorial_panel != null: tutorial_panel.hide()
		return
	var service := AppController.tutorial_service
	tutorial_panel.visible = service.enabled
	if not service.enabled:
		return
	var step := service.current_step()
	tutorial_title.text = String(step["title"])
	tutorial_text.text = String(step["text"])
	tutorial_progress.text = "新手引导 · 步骤 %d / %d" % [service.step_index + 1, TutorialService.STEPS.size()]
	main_tabs.current_tab = clampi(int(step.get("tab", 0)), 0, main_tabs.get_tab_count() - 1)

func _open_tutorial_center(topic_code: StringName = &"overview") -> void:
	tutorial_panel.hide()
	tutorial_center.show()
	tutorial_center.move_to_front()
	tutorial_search.text = ""
	_refresh_tutorial_topics("")
	var target_index := 0
	for index: int in tutorial_topic_list.item_count:
		if StringName(tutorial_topic_list.get_item_metadata(index)) == topic_code:
			target_index = index
			break
	if tutorial_topic_list.item_count > 0:
		tutorial_topic_list.select(target_index)
		_show_tutorial_topic(target_index)

func _close_tutorial_center() -> void:
	tutorial_center.hide()
	_refresh_tutorial()

func _refresh_tutorial_topics(search_text: String) -> void:
	if tutorial_topic_list == null:
		return
	tutorial_topic_list.clear()
	visible_tutorial_topics = TutorialCatalog.topics(search_text)
	for topic: Dictionary in visible_tutorial_topics:
		tutorial_topic_list.add_item("%s  ·  %s" % [topic["category"], topic["title"]])
		var index := tutorial_topic_list.item_count - 1
		tutorial_topic_list.set_item_metadata(index, topic["code"])
	if visible_tutorial_topics.is_empty():
		tutorial_article_title.text = "没有匹配的教程"
		tutorial_article_body.text = "请尝试搜索“染色体”、“QTL”、“基因组工坊”或“存档”。"
	else:
		tutorial_topic_list.select(0)
		_show_tutorial_topic(0)

func _show_tutorial_topic(index: int) -> void:
	if index < 0 or index >= tutorial_topic_list.item_count:
		return
	var code := StringName(tutorial_topic_list.get_item_metadata(index))
	var topic := TutorialCatalog.topic_by_code(code)
	if topic.is_empty():
		return
	tutorial_article_title.text = "%s · %s" % [topic["category"], topic["title"]]
	tutorial_article_body.text = String(topic["content"])
	tutorial_article_body.scroll_to_line(0)

func _refresh_genome_designer() -> void:
	if genome_grid == null or not AppController.has_game:
		return
	genome_base_option.clear()
	for founder: FounderDefinition in AppController.species.founders:
		genome_base_option.add_item(founder.display_name, founder.id)
	for child: Node in genome_grid.get_children():
		genome_grid.remove_child(child)
		child.queue_free()
	genome_rows.clear()
	for header_text: String in ["位点", "位置", "同源 A", "同源 B"]:
		var header := Label.new()
		header.text = header_text
		header.add_theme_color_override("font_color", ACCENT)
		genome_grid.add_child(header)
	var show_all_qtl := AppController.task_service.mode == &"sandbox"
	for locus: LocusDefinition in AppController.species.loci:
		if locus.kind == LocusDefinition.Kind.QTL and not show_all_qtl and AppController.research_service.reveal_level_for(locus.id) != ResearchFinding.RevealLevel.IDENTIFIED:
			continue
		var code_label := Label.new()
		code_label.text = String(locus.code)
		genome_grid.add_child(code_label)
		var position_label := Label.new()
		position_label.text = "Chr%d · %.1f cM" % [locus.chromosome_id, locus.position_cm]
		position_label.add_theme_color_override("font_color", MUTED)
		genome_grid.add_child(position_label)
		var allele_a := OptionButton.new()
		var allele_b := OptionButton.new()
		for allele_id: int in locus.allele_labels.size():
			allele_a.add_item(locus.allele_labels[allele_id], allele_id)
			allele_b.add_item(locus.allele_labels[allele_id], allele_id)
		genome_grid.add_child(allele_a)
		genome_grid.add_child(allele_b)
		genome_rows[locus.id] = [allele_a, allele_b]
	_load_genome_base()

func _load_genome_base() -> void:
	if genome_base_option == null or genome_base_option.item_count == 0:
		return
	var founder := AppController.species.founder_by_id(genome_base_option.get_item_id(genome_base_option.selected))
	for locus_id: int in genome_rows:
		var options: Array = genome_rows[locus_id]
		var allele_id := founder.allele_at(locus_id)
		(options[0] as OptionButton).select(allele_id)
		(options[1] as OptionButton).select(allele_id)

func _make_designer_homozygous() -> void:
	for options: Array in genome_rows.values():
		(options[1] as OptionButton).select((options[0] as OptionButton).get_item_id((options[0] as OptionButton).selected))

func _create_custom_material() -> void:
	var alleles_a: Dictionary = {}
	var alleles_b: Dictionary = {}
	for locus_id: int in genome_rows:
		var options: Array = genome_rows[locus_id]
		var option_a := options[0] as OptionButton
		var option_b := options[1] as OptionButton
		alleles_a[locus_id] = option_a.get_item_id(option_a.selected)
		alleles_b[locus_id] = option_b.get_item_id(option_b.selected)
	var result := AppController.create_custom_material(genome_name_edit.text, genome_base_option.get_item_id(genome_base_option.selected), alleles_a, alleles_b)
	var error := String(result.get("error", "未知错误"))
	if error.is_empty():
		genome_status.text = "材料已创建，可在亲本列表中选择。植株 ID：#%d" % int(result["plant_id"])
	else:
		genome_status.text = "创建失败：" + error

func _labeled_option(parent: VBoxContainer, label_text: String) -> OptionButton:
	var label := Label.new(); label.text = label_text; label.add_theme_color_override("font_color", MUTED); parent.add_child(label)
	var option := OptionButton.new(); option.custom_minimum_size.y = 38; parent.add_child(option); return option

func _section_label(text_value: String) -> Label:
	var label := Label.new(); label.text = text_value; label.add_theme_font_size_override("font_size", 20); label.add_theme_color_override("font_color", ACCENT); return label

func _selected_id(option: OptionButton) -> int:
	return option.get_item_id(option.selected) if option.selected >= 0 else 0

func _select_id(option: OptionButton, item_id: int) -> void:
	for index: int in option.item_count:
		if option.get_item_id(index) == item_id:
			option.select(index); return

func _task_color(done: bool) -> String:
	return "#55d6a9" if done else "#98abb3"

func _weight_spin(value: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = 0.0
	spin.max_value = 3.0
	spin.step = 0.1
	spin.value = value
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spin

func _style(color: Color, radius: int, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = color; style.border_color = border_color
	style.set_corner_radius_all(radius); style.set_border_width_all(1)
	style.content_margin_left = 12; style.content_margin_right = 12; style.content_margin_top = 9; style.content_margin_bottom = 9
	return style
