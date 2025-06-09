## The editor main scnee.
class_name Main
extends Node

var _injector: Injector = null

## Construct the main scene.
func _ready() -> void:
	_injector = Injector.create(ApplicationInjectionContext.new())
	
	_load_editor_configuration()


## Preloads the editor configuration
func _load_editor_configuration() -> void:
	_injector.provide(EditorConfigurationSource).reload()
