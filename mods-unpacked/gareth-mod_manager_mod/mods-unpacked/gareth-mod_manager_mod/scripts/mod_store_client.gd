extends Node

signal repo_fetch_completed(repo_name: String, releases: Array)
signal mod_download_completed(mod_id: String, success: bool, msg: String)

var _http: HTTPRequest
var _request_queue: Array = []
var _is_requesting: bool = false

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(Callable(self, "_on_request_completed"))

func fetch_all_available_mods() -> void:
	var url = "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/mod_catalog.json?v=" + str(Time.get_unix_time_from_system())
	_queue_request(url, Callable(self, "_on_catalog_response"))

func _queue_request(url: String, callback: Callable) -> void:
	_request_queue.append({"url": url, "callback": callback})
	_process_queue()

func _process_queue() -> void:
	if _is_requesting or _request_queue.is_empty(): return
	_is_requesting = true
	var req = _request_queue.pop_front()
	_http.set_meta("current_callback", req.callback)
	_http.request(req.url)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_is_requesting = false
	var cb = _http.get_meta("current_callback")
	if cb and cb.is_valid():
		cb.call(result, response_code, headers, body)
	_process_queue()

func _on_catalog_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json = JSON.new()
		var err = json.parse(body.get_string_from_utf8())
		if err == OK:
			var data = json.get_data()
			if typeof(data) == TYPE_ARRAY:
				repo_fetch_completed.emit("Coal LLC Mods", data)
				return
	repo_fetch_completed.emit("Coal LLC Mods", [])

func download_mod(mod_id: String) -> void:
	var url = "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/downloaded_mods/%s.zip" % mod_id
	var save_path = OS.get_executable_path().get_base_dir().path_join("mods").path_join(mod_id + ".zip")
	_http.download_file = save_path
	_queue_request(url, Callable(self, "_on_download_completed").bind(mod_id))

func _on_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, mod_id: String) -> void:
	_http.download_file = ""
	if response_code == 200:
		mod_download_completed.emit(mod_id, true, "Installed successfully.")
	else:
		mod_download_completed.emit(mod_id, false, "Download failed.")
