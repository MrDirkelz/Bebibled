/// obj_game_boot :: Create
/// Persistent boot guard + first-launch redirect to the level-select map.
/// Controllers also call game_boot_once(), so room order can change safely.

// singleton: a persistent boot instance already exists -> drop this duplicate
if (variable_global_exists("boot_inst") && instance_exists(global.boot_inst) && global.boot_inst != id) {
    instance_destroy();
    exit;
}
global.boot_inst = id;

game_boot_once();

// on the very first launch, jump to the map (Room1 is the battle room)
if (!variable_global_exists("app_started")) {
    global.app_started   = true;
    global.pending_level = undefined;
    global.map_return    = undefined;
    room_goto(rm_map);
}
