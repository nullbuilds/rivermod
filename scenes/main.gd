class_name Main
extends Node
## The editor main scnee.

var _injector: Injector = null

## Construct the main scene.
func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	_injector = Injector.create(ApplicationInjectionContext.new())


## Handles incoming notifications.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_close_application(0)


## Close the application and return the given exit code.
func _close_application(exit_code: int) -> void:
	var config_service: EditorConfigurationService = _injector.provide(EditorConfigurationService)
	config_service.save()
	get_tree().quit(exit_code)
