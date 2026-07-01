/// scr_boss_abilities
/// Boss ability definitions. Each ability is a struct with a telegraph string and an
/// `effect(grid_manager, hero)` method that talks ONLY to the grid manager's mutation
/// API (lock/freeze/transform/destroy) plus hero.take_damage — never the array directly.

/// @desc Default ability set for the base boss.
/// Each ability stores its damage as a struct member (`hero_damage`): the effect
/// method's `self` is the ability struct, so it can't read enclosing `var` locals.
function boss_default_abilities(_scale = 1) {
    return [
        {
            name        : "Bind",
            telegraph   : "Locks 2 tiles",
            hero_damage : round(8 * _scale),
            effect : function(_gm, _hero) {
                var _cells = _gm.get_random_cells(2);
                for (var i = 0; i < array_length(_cells); i++) {
                    _gm.lock_tile(_cells[i].col, _cells[i].row, 2);
                }
                if (_hero != noone) _hero.take_damage(hero_damage);
            }
        },
        {
            name        : "Frost",
            telegraph   : "Freezes 3 tiles",
            hero_damage : round(5 * _scale),
            effect : function(_gm, _hero) {
                var _cells = _gm.get_random_cells(3);
                for (var i = 0; i < array_length(_cells); i++) {
                    _gm.freeze_tile(_cells[i].col, _cells[i].row, 2);
                }
                if (_hero != noone) _hero.take_damage(hero_damage);
            }
        },
        {
            name        : "Corrupt",
            telegraph   : "Spawns junk",
            hero_damage : round(6 * _scale),
            effect : function(_gm, _hero) {
                var _cells = _gm.get_random_cells(1);
                if (array_length(_cells) > 0) {
                    _gm.transform_tile(_cells[0].col, _cells[0].row, COLOR.PURPLE, TILE_TYPE.BLOCKER);
                }
                if (_hero != noone) _hero.take_damage(hero_damage);
            }
        },
        {
            name        : "Smash",
            telegraph   : "Heavy attack",
            hero_damage : round(18 * _scale),
            effect : function(_gm, _hero) {
                if (_hero != noone) _hero.take_damage(hero_damage);
            }
        }
    ];
}
