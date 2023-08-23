@tool
extends EditorPlugin


const ImportPlugin = preload("res://addons/godot-importer/import_plugin.gd")
var import_plugin = ImportPlugin.new()

func _enter_tree():
	add_import_plugin(import_plugin)


func _exit_tree():
	remove_import_plugin(import_plugin)
	import_plugin = null
