class_name ModStoreClient
extends Node

signal repo_fetch_completed(repo_name: String, releases: Array)
signal mod_download_completed(mod_id: String, success: bool)

const DEFAULT_REPOS := [
	"garethwhite-prog/coal-llc-mods",
	"Der-Floh/coal-llc-mods"
]

var http_client: HTTPRequest

func _ready() -> void:
	http_client = HTTPRequest.new()
	add_child(http_client)

func fetch_all_available_mods() -> void:
	var repos = _load_repo_list()
	for r in repos:
		_fetch_repo_releases(r)

func _load_repo_list() -> Array:
	var list := DEFAULT_REPOS.duplicate()
	var path := "user://mod_store_repos.json"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f:
			var data = JSON.parse_string(f.get_as_text())
			if data is Array:
				for custom_r in data:
					if not custom_r in list:
						list.append(custom_r)
	return list

func _fetch_repo_releases(repo: String) -> void:
	var url := "https://api.github.com/repos/%s/releases" % repo
	var headers := ["User-Agent: Coal-LLC-Mod-Store/1.0"]
	http_client.request(url, headers)
	var result = await http_client.request_completed
	if result[1] == 200:
		var json = JSON.parse_string(result[3].get_string_from_utf8())
		if json is Array:
			repo_fetch_completed.emit(repo, json)

func download_mod_zip(download_url: String, target_filename: String) -> void:
	var dl_http = HTTPRequest.new()
	add_child(dl_http)
	var local_repo_dir := OS.get_executable_path().get_base_dir().path_join("mods_repository")
	var dest_path := local_repo_dir.path_join(target_filename)
	dl_http.download_file = dest_path
	dl_http.request(download_url, ["User-Agent: Coal-LLC-Mod-Store/1.0"])
	var res = await dl_http.request_completed
	dl_http.queue_free()
	mod_download_completed.emit(target_filename, res[1] == 200)
