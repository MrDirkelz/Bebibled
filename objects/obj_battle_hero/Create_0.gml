/// obj_battle_hero :: Create
/// Player stat holder. Receives damage from the boss; accumulates the word meter
/// from cleared letters. Pure data — no FSM.

hp_max      = 100;
hp          = hp_max;
word_charge = 0;
faith_max   = 240;
miracles    = [];

take_damage = function(_amount) {
    hp = max(0, hp - _amount);
};

add_faith = function(_amount) {
    word_charge = min(faith_max, word_charge + max(0, _amount));
};

spend_faith = function(_amount) {
    if (word_charge < _amount) return false;
    word_charge -= _amount;
    return true;
};

apply_level = function() {
    if (variable_global_exists("level")) faith_max = global.level.rules.faith_max;
    hp_max = 100;
    hp = hp_max;
    word_charge = 0;
    miracles = miracles_default_loadout();
};
