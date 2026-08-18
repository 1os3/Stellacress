class_name ChromosomeView
extends Control

const TRACK_HEIGHT: float = 14.0
const TRACK_GAP: float = 10.0
const LEFT_MARGIN: float = 78.0
const RIGHT_MARGIN: float = 24.0
const BLOCK_HEIGHT: float = 128.0
const BLOCK_START_Y: float = 30.0

var plant_id: int = 0

func _ready() -> void:
	custom_minimum_size = Vector2(760.0, 475.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "移动到位点或祖源片段上查看说明"

func show_plant(p_plant_id: int) -> void:
	plant_id = p_plant_id
	queue_redraw()

func _draw() -> void:
	if plant_id <= 0 or not AppController.has_game:
		draw_string(get_theme_default_font(), Vector2(20, 40), "请选择候选植株查看染色体祖源", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("9aacb8"))
		return
	var plant := AppController.plant_store.get_plant(plant_id)
	if plant == null:
		return
	var genome := AppController.genome_store.get_genome(plant.genome_ref)
	var width := size.x - LEFT_MARGIN - RIGHT_MARGIN
	var y := BLOCK_START_Y
	for chromosome: ChromosomeDefinition in AppController.species.chromosomes:
		draw_string(get_theme_default_font(), Vector2(12, y + 31), String(chromosome.code), HORIZONTAL_ALIGNMENT_LEFT, 58, 15, Color("dbe8e2"))
		if chromosome.id == 1:
			var linked_x0 := LEFT_MARGIN + width * 41.0 / chromosome.length_cm
			var linked_x1 := LEFT_MARGIN + width * 47.0 / chromosome.length_cm
			draw_rect(Rect2(linked_x0, y + 14, linked_x1 - linked_x0, 2.0 * TRACK_HEIGHT + TRACK_GAP + 8.0), Color(0.95, 0.35, 0.28, 0.12), true)
		for homolog_index: int in 2:
			var haplotype := genome.haplotype_for(chromosome.id, homolog_index == 0)
			var track_y := y + 16.0 + float(homolog_index) * (TRACK_HEIGHT + TRACK_GAP)
			draw_string(get_theme_default_font(), Vector2(LEFT_MARGIN - 23, track_y + 11), "A" if homolog_index == 0 else "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("8097a3"))
			draw_rect(Rect2(LEFT_MARGIN, track_y, width, TRACK_HEIGHT), Color("243747"), true)
			for segment_index: int in haplotype.segments.size():
				var segment := haplotype.segments[segment_index]
				var end_cm := haplotype.segments[segment_index + 1].start_cm if segment_index + 1 < haplotype.segments.size() else chromosome.length_cm
				var x0 := LEFT_MARGIN + width * segment.start_cm / chromosome.length_cm
				var x1 := LEFT_MARGIN + width * end_cm / chromosome.length_cm
				var founder := AppController.species.founder_by_id(segment.founder_haplotype_id)
				var color := founder.color if founder != null else Color.MAGENTA
				draw_rect(Rect2(x0, track_y, maxf(1.0, x1 - x0), TRACK_HEIGHT), color, true)
				if segment_index > 0:
					draw_line(Vector2(x0, track_y - 2), Vector2(x0, track_y + TRACK_HEIGHT + 2), Color.WHITE, 1.0)
			for variant: VariantOverride in haplotype.variants:
				var variant_x := LEFT_MARGIN + width * variant.position_cm / chromosome.length_cm
				draw_circle(Vector2(variant_x, track_y + TRACK_HEIGHT * 0.5), 3.0, Color("ff6b6b"))
		var locus_y := y + 65.0
		var visible_locus_index := 0
		for locus_id: int in chromosome.locus_ids_sorted:
			var locus := AppController.species.locus_by_id(locus_id)
			if locus.kind == LocusDefinition.Kind.QTL and AppController.research_service.reveal_level_for(locus.id) == ResearchFinding.RevealLevel.HIDDEN:
				continue
			var locus_x := LEFT_MARGIN + width * locus.position_cm / chromosome.length_cm
			var color := Color("67d5b5") if locus.kind == LocusDefinition.Kind.MAJOR else Color("bf9cf5")
			draw_line(Vector2(locus_x, y + 12), Vector2(locus_x, locus_y), color, 1.0)
			var label_y := locus_y + 15.0 + float(visible_locus_index % 2) * 15.0
			draw_string(get_theme_default_font(), Vector2(locus_x - 18, label_y), String(locus.code), HORIZONTAL_ALIGNMENT_CENTER, 36, 11, color)
			visible_locus_index += 1
		var scale_y := y + 112.0
		draw_line(Vector2(LEFT_MARGIN, scale_y - 9), Vector2(LEFT_MARGIN + width, scale_y - 9), Color("365160"), 1.0)
		for fraction: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var tick_x := LEFT_MARGIN + width * fraction
			draw_line(Vector2(tick_x, scale_y - 12), Vector2(tick_x, scale_y - 6), Color("6f8792"), 1.0)
			var coordinate := chromosome.length_cm * fraction
			draw_string(get_theme_default_font(), Vector2(tick_x - 20, scale_y + 4), "%.0f" % coordinate, HORIZONTAL_ALIGNMENT_CENTER, 40, 10, Color("78909a"))
		draw_string(get_theme_default_font(), Vector2(LEFT_MARGIN + width + 4, scale_y + 4), "cM", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("78909a"))
		y += BLOCK_HEIGHT
	_draw_legend(Vector2(LEFT_MARGIN, size.y - 18.0))

func _draw_legend(origin: Vector2) -> void:
	var x := origin.x
	for founder: FounderDefinition in AppController.species.founders:
		draw_rect(Rect2(x, origin.y - 10, 12, 12), founder.color, true)
		draw_string(get_theme_default_font(), Vector2(x + 17, origin.y), founder.display_name.get_slice(" ", 0), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("b9c7ce"))
		x += 125.0
	draw_string(get_theme_default_font(), Vector2(12, origin.y - 18.0), "颜色=创始祖源  │  白线=重组边界  │  红点=突变  │  A/B=同源染色体", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("78909a"))

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion or plant_id <= 0 or not AppController.has_game:
		return
	var mouse := (event as InputEventMouseMotion).position
	var chromosome_index := int(floor((mouse.y - BLOCK_START_Y) / BLOCK_HEIGHT))
	if chromosome_index < 0 or chromosome_index >= AppController.species.chromosomes.size():
		tooltip_text = "移动到位点或祖源片段上查看说明"
		return
	var chromosome: ChromosomeDefinition = AppController.species.chromosomes[chromosome_index]
	var width := size.x - LEFT_MARGIN - RIGHT_MARGIN
	if mouse.x < LEFT_MARGIN or mouse.x > LEFT_MARGIN + width:
		return
	var position_cm := clampf((mouse.x - LEFT_MARGIN) / width * chromosome.length_cm, 0.0, chromosome.length_cm)
	var nearest_locus: LocusDefinition
	var nearest_distance := 3.0
	for locus_id: int in chromosome.locus_ids_sorted:
		var locus := AppController.species.locus_by_id(locus_id)
		if locus.kind == LocusDefinition.Kind.QTL and AppController.research_service.reveal_level_for(locus.id) == ResearchFinding.RevealLevel.HIDDEN:
			continue
		var distance := absf(locus.position_cm - position_cm)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_locus = locus
	var local_y := mouse.y - (BLOCK_START_Y + float(chromosome_index) * BLOCK_HEIGHT)
	var use_a := local_y < 16.0 + TRACK_HEIGHT + TRACK_GAP * 0.5
	var founder_id := AppController.pedigree_service.founder_at(plant_id, chromosome.id, use_a, position_cm)
	var founder := AppController.species.founder_by_id(founder_id)
	var text := "%s · %s 同源 · %.2f cM · 祖源：%s" % [chromosome.code, "A" if use_a else "B", position_cm, founder.display_name if founder != null else "未知"]
	if nearest_locus != null:
		var plant := AppController.plant_store.get_plant(plant_id)
		var genome := AppController.genome_store.get_genome(plant.genome_ref)
		text += "\n位点 %s（%.1f cM），基因型 %s" % [nearest_locus.code, nearest_locus.position_cm, AppController.genetics_engine.genotype_label(genome, nearest_locus)]
		if nearest_locus.code == &"YLD1" or nearest_locus.code == &"HGT":
			text += "\nYLD1–HGT 相距 6 cM，是教程中的紧密连锁区。"
	tooltip_text = text
