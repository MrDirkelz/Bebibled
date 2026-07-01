/// obj_boss_base :: Create
/// Enemy actor. Picks an ability each boss turn and executes it against the board
/// through the grid manager's mutation API. Never touches the grid array directly.

hp_max = 300;
hp     = hp_max;

abilities = boss_default_abilities();
intent    = undefined;          // the ability chosen for the upcoming boss turn (telegraph)
enemy_name = "Adversary";

/// @desc Pick (telegraph) the next ability. Called at END_PLAYER_TURN.
choose_intent = function() {
    intent = abilities[irandom(array_length(abilities) - 1)];
};

/// @desc Execute the telegraphed ability against the grid / hero. Called in BOSS_ATTACK.
execute_intent = function(_grid_mgr, _hero) {
    if (intent != undefined) intent.effect(_grid_mgr, _hero);
};

apply_level = function() {
    if (!variable_global_exists("level")) return;

    enemy_name = global.level.enemy.name;
    hp_max = global.level.enemy_hp;
    hp = hp_max;
    abilities = global.level.enemy.abilities;
    intent = undefined;
    if (global.level.enemy.sprite >= 0) sprite_index = global.level.enemy.sprite;
};
