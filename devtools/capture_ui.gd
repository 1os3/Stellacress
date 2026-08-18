extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var app := root.get_node_or_null("AppController")
	if app == null:
		push_error("AppController autoload 不存在")
		quit(1)
		return
	var scene := load("res://scenes/main.tscn") as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	app.call("new_game", &"tasks", 20260817, 1, "界面预览")
	for _frame: int in 5:
		await process_frame
	instance.call("_show_candidate", 0)
	await process_frame
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_error("当前显示驱动不支持界面截图")
		quit(1)
		return
	var image := viewport_texture.get_image()
	if image == null:
		push_error("渲染器未返回截图图像")
		quit(1)
		return
	var error := image.save_png("res://tests/tmp/ui_preview.png")
	app.get("tutorial_service").call("close")
	instance.call("_refresh_tutorial")
	(instance.get("main_tabs") as TabContainer).current_tab = 3
	for _frame: int in 3:
		await process_frame
	var workshop_image := root.get_texture().get_image()
	var workshop_error := workshop_image.save_png("res://tests/tmp/genome_workshop.png")
	instance.call("_open_tutorial_center", &"genome_workshop")
	for _frame: int in 3:
		await process_frame
	var tutorial_image := root.get_texture().get_image()
	var tutorial_error := tutorial_image.save_png("res://tests/tmp/tutorial_center.png")
	print("UI capture: ", error, ", workshop: ", workshop_error, ", tutorial: ", tutorial_error, " size=", image.get_size())
	var final_error := error if error != OK else workshop_error
	quit(final_error if final_error != OK else tutorial_error)
