extends Object

const CHART_SCRIPT_PATH := "res://mods-unpacked/gareth-weapon_workers_mod/scripts/weapon_workers_chart.gd"

func _ready(chain: ModLoaderHookChain) -> void:
    chain.execute_next([])
    var screen = chain.reference_object
    if not is_instance_valid(screen) or not ("tab_container" in screen) or not is_instance_valid(screen.tab_container):
        return

    var tc: TabContainer = screen.tab_container
    for idx in range(tc.get_tab_count()):
        if tc.get_tab_title(idx) == "Weapon Workers":
            return

    var chart_script: GDScript = load(CHART_SCRIPT_PATH)
    if not chart_script:
        ModLoaderLog.warning("Failed to load weapon_workers_chart.gd", "gareth-weapon_workers_mod")
        return

    var chart := Control.new()
    chart.name = "Weapon Workers"
    chart.set_script(chart_script)
    tc.add_child(chart)
    var new_idx: int = tc.get_tab_count() - 1
    tc.set_tab_title(new_idx, "Weapon Workers")
    tc.tab_changed.connect(func(tab: int):
        if tab == new_idx and is_instance_valid(chart) and chart.has_method("refresh_chart"):
            chart.call("refresh_chart")
    )
