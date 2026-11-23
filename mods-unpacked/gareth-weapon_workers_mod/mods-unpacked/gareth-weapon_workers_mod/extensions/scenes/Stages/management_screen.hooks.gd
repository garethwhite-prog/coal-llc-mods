extends Object

const CHART_SCRIPT := preload("res://mods-unpacked/gareth-weapon_workers_mod/scripts/weapon_workers_chart.gd")

func _ready(chain: ModLoaderHookChain) -> void:
    chain.execute_next([])
    var screen = chain.reference_object
    if not is_instance_valid(screen) or not ("tab_container" in screen) or not is_instance_valid(screen.tab_container):
        return
    if screen.tab_container.has_node("Weapon Workers"):
        return

    var chart := Control.new()
    chart.set_script(CHART_SCRIPT)
    screen.tab_container.add_child(chart)
