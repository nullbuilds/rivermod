class_name ExternalToolsService
extends Object
## Service for managing external tools.

const _MAP_VIEWER_EXECUTABLE: String = "map-viewer.exe"
const _MODEL_VIEWER_EXECUTABLE: String = "model-viewer.exe"

var _config_service: EditorConfigurationService = null
var _map_viewer_pid: int = -1
var _model_viewer_pid: int = -1

## Constructs a new external tools service instance.
func _init(config_service: EditorConfigurationService) -> void:
	assert(config_service != null, "config_service must not be null")
	_config_service = config_service


## Stops the service and cleans-up any resources.
func stop() -> void:
	if _map_viewer_pid != -1 and OS.is_process_running(_map_viewer_pid):
		OS.kill(_map_viewer_pid)
	
	if _model_viewer_pid != -1 and OS.is_process_running(_model_viewer_pid):
		OS.kill(_model_viewer_pid)


## Launches the external map viewer application.
func launch_map_viewer() -> void:
	_map_viewer_pid = _launch_tool(_MAP_VIEWER_EXECUTABLE, _map_viewer_pid)


## Launches the external model viewer application.
func launch_model_viewer() -> void:
	_model_viewer_pid = _launch_tool(_MODEL_VIEWER_EXECUTABLE, _model_viewer_pid)


## Launches a given tool and returns its PID.
func _launch_tool(executable: String, pid: int) -> int:
	if pid != -1 and OS.is_process_running(pid):
		return pid
	
	var path: String = _get_tool_path(executable)
	var game_directory: String = _config_service.get_game_install_directory()
	return OS.create_process(path, ["--", "--game-directory=%s" % game_directory ])


## Returns the path to a given external tool
func _get_tool_path(executable: String) -> String:
	var directory: String = ProjectSettings.get_setting_with_override("rivermod/external_tools_directory")
	return directory.path_join(executable)
