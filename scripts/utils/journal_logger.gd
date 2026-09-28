class_name JournalLogger
extends Logger
## Capte les erreurs du moteur et des scripts pour le journal de jeu (version 4.2.1). Le moteur
## peut l'appeler depuis n'importe quel fil : les erreurs attendent ici, sous verrou, que le
## journal les prenne (take) à l'image suivante. Les avertissements sont ignorés.

var _mutex := Mutex.new()
var _pending: Array[Dictionary] = []


func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	if error_type == ERROR_TYPE_WARNING:
		return
	var message: String = rationale if rationale != "" else code
	_push({"message": message.left(200), "file": file.get_file(), "line": line, "function": function, "type": error_type})


func _log_message(message: String, error: bool) -> void:
	if error:
		_push({"message": message.strip_edges().left(200), "file": "", "line": 0, "function": "", "type": -1})


## Les erreurs arrivées depuis le dernier appel.
func take() -> Array[Dictionary]:
	_mutex.lock()
	var taken: Array[Dictionary] = _pending.duplicate()
	_pending.clear()
	_mutex.unlock()
	return taken


func _push(error: Dictionary) -> void:
	_mutex.lock()
	if _pending.size() < 100:
		_pending.append(error)
	_mutex.unlock()
