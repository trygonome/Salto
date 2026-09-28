extends SceneTree
## Point d'entrée du robot joueur (voir tools/robot.sh) : attend que les autoloads soient prêts,
## puis lance RobotPlayer avec les options de la ligne de commande.


func _initialize() -> void:
	await process_frame
	var robot: Node = (load("res://tests/bot/robot_player.gd") as GDScript).new()
	robot.name = "Robot"
	root.add_child(robot)
	robot.call(&"run_all", OS.get_cmdline_user_args())
