/// scr_enemy_archetypes
/// Deterministic enemy lookup for procedural levels.

function enemy_archetypes_init() {
    if (variable_global_exists("enemy_archetypes_ready") && global.enemy_archetypes_ready) return;

    global.enemy_archetypes = {};
    global.enemy_archetypes[$ "default"] = { name : "Adversary", sprite : "spr_pot", hp_mult : 1.0, potency : 1.0 };
    global.enemy_archetypes.serpent = { name : "Serpent", sprite : "spr_pot", hp_mult : 0.9, potency : 0.9 };
    global.enemy_archetypes.wanderer = { name : "Wanderer", sprite : "spr_pot", hp_mult : 1.0, potency : 1.0 };
    global.enemy_archetypes.raider = { name : "Raider", sprite : "spr_pot", hp_mult : 1.1, potency : 1.0 };
    global.enemy_archetypes.giant = { name : "Giant", sprite : "spr_pot", hp_mult : 1.35, potency : 0.9 };
    global.enemy_archetypes.tempter = { name : "Tempter", sprite : "spr_pot", hp_mult : 0.95, potency : 1.2 };
    global.enemy_archetypes.accuser = { name : "Accuser", sprite : "spr_pot", hp_mult : 1.15, potency : 1.1 };
    global.enemy_archetypes.idol = { name : "Idol", sprite : "spr_pot", hp_mult : 1.25, potency : 1.0 };
    global.enemy_archetypes.beast = { name : "Beast", sprite : "spr_pot", hp_mult : 1.3, potency : 1.15 };
    global.enemy_archetypes.legion = { name : "Legion", sprite : "spr_pot", hp_mult : 1.2, potency : 1.3 };
    global.enemy_archetypes.dragon = { name : "Dragon", sprite : "spr_pot", hp_mult : 1.5, potency : 1.35 };

    // thematic roster (sprites are placeholders until art lands)
    global.enemy_archetypes.taskmaster    = { name : "Taskmaster",     sprite : "spr_pot", hp_mult : 1.05, potency : 1.1 };
    global.enemy_archetypes.chariot       = { name : "Chariot",        sprite : "spr_pot", hp_mult : 1.2,  potency : 1.15 };
    global.enemy_archetypes.plague        = { name : "Plague",         sprite : "spr_pot", hp_mult : 1.0,  potency : 1.25 };
    global.enemy_archetypes.oppressor     = { name : "Oppressor",      sprite : "spr_pot", hp_mult : 1.15, potency : 1.05 };
    global.enemy_archetypes.philistine    = { name : "Philistine",     sprite : "spr_pot", hp_mult : 1.1,  potency : 1.0 };
    global.enemy_archetypes.betrayer      = { name : "Betrayer",       sprite : "spr_pot", hp_mult : 1.0,  potency : 1.2 };
    global.enemy_archetypes.usurper       = { name : "Usurper",        sprite : "spr_pot", hp_mult : 1.15, potency : 1.1 };
    global.enemy_archetypes.invader       = { name : "Invader",        sprite : "spr_pot", hp_mult : 1.25, potency : 1.05 };
    global.enemy_archetypes.schemer       = { name : "Schemer",        sprite : "spr_pot", hp_mult : 0.95, potency : 1.25 };
    global.enemy_archetypes.affliction    = { name : "Affliction",     sprite : "spr_pot", hp_mult : 1.1,  potency : 1.2 };
    global.enemy_archetypes.despair       = { name : "Despair",        sprite : "spr_pot", hp_mult : 1.0,  potency : 1.15 };
    global.enemy_archetypes.folly         = { name : "Folly",          sprite : "spr_pot", hp_mult : 0.9,  potency : 1.05 };
    global.enemy_archetypes.tyrant        = { name : "Tyrant",         sprite : "spr_pot", hp_mult : 1.35, potency : 1.2 };
    global.enemy_archetypes.storm         = { name : "Storm",          sprite : "spr_pot", hp_mult : 1.1,  potency : 1.3 };
    global.enemy_archetypes.leviathan     = { name : "Leviathan",      sprite : "spr_pot", hp_mult : 1.6,  potency : 1.2 };
    global.enemy_archetypes.locust        = { name : "Locust Swarm",   sprite : "spr_pot", hp_mult : 0.9,  potency : 1.4 };
    global.enemy_archetypes.false_prophet = { name : "False Prophet",  sprite : "spr_pot", hp_mult : 1.05, potency : 1.25 };
    global.enemy_archetypes.persecutor    = { name : "Persecutor",     sprite : "spr_pot", hp_mult : 1.1,  potency : 1.2 };
    global.enemy_archetypes.sin           = { name : "Sin",            sprite : "spr_pot", hp_mult : 1.2,  potency : 1.15 };
    global.enemy_archetypes.principality  = { name : "Principality",   sprite : "spr_pot", hp_mult : 1.4,  potency : 1.3 };
    global.enemy_archetypes.deceiver      = { name : "Deceiver",       sprite : "spr_pot", hp_mult : 1.0,  potency : 1.25 };
    global.enemy_archetypes.scoffer       = { name : "Scoffer",        sprite : "spr_pot", hp_mult : 0.95, potency : 1.1 };
    global.enemy_archetypes.antichrist    = { name : "Antichrist",     sprite : "spr_pot", hp_mult : 1.45, potency : 1.3 };
    global.enemy_archetypes.heresy        = { name : "Heresy",         sprite : "spr_pot", hp_mult : 1.05, potency : 1.2 };
    global.enemy_archetypes.darkness      = { name : "Darkness",       sprite : "spr_pot", hp_mult : 1.2,  potency : 1.2 };
    global.enemy_archetypes.pride         = { name : "Pride",          sprite : "spr_pot", hp_mult : 1.1,  potency : 1.15 };
    global.enemy_archetypes.famine        = { name : "Famine",         sprite : "spr_pot", hp_mult : 1.0,  potency : 1.1 };
    global.enemy_archetypes.legalist      = { name : "Legalist",       sprite : "spr_pot", hp_mult : 1.05, potency : 1.15 };

    global.enemy_archetypes_ready = true;
}

function enemy_pick_id(_pool, _seed) {
    if (!is_array(_pool) || array_length(_pool) <= 0) return "default";
    return _pool[abs(floor(_seed)) mod array_length(_pool)];
}

function enemy_get_archetype(_enemy_id, _difficulty = 1) {
    enemy_archetypes_init();
    var _id = variable_struct_exists(global.enemy_archetypes, _enemy_id) ? _enemy_id : "default";
    var _base = global.enemy_archetypes[$ _id];
    var _fallback_sprite = asset_get_index("spr_pot");
    var _sprite = asset_or_default(_base.sprite, _fallback_sprite);
    var _scale = max(0.1, _difficulty * _base.potency);

    return {
        id : _id,
        name : _base.name,
        sprite : _sprite,
        hp_mult : _base.hp_mult,
        abilities : boss_default_abilities(_scale)
    };
}
