/// scr_miracles
/// Faith-meter active abilities. Instant miracles keep the turn; clear miracles
/// consume the turn through the normal clear/cascade pipeline.

function miracles_init() {
    if (variable_global_exists("miracles_ready") && global.miracles_ready) return;

    global.miracles = [
        {
            name : "Grace",
            cost : 70,
            kind : "instant",
            effect : function(_gm, _hero, _level) {
                if (_hero != noone) _hero.hp = min(_hero.hp_max, _hero.hp + _level.rules.miracle_heal);
                return [];
            }
        },
        {
            name : "Manna",
            cost : 55,
            kind : "instant",
            effect : function(_gm, _hero, _level) {
                if (_gm != noone) _gm.reletter_random(_level.rules.manna_k);
                return [];
            }
        },
        {
            name : "Cleanse",
            cost : 130,
            kind : "clear",
            effect : function(_gm, _hero, _level) {
                if (_gm == noone) return [];
                return _gm.clear_color(_gm.most_common_color());
            }
        },
        {
            name : "Pentecost",
            cost : 80,
            kind : "instant",
            effect : function(_gm, _hero, _level) {
                if (_gm != noone) _gm.plant_fresh_divine();
                return [];
            }
        }
    ];

    global.miracles_ready = true;
}

function miracles_default_loadout() {
    miracles_init();
    return global.miracles;
}

function miracle_button_index_at(_gui_x, _gui_y) {
    miracles_init();
    var _button_w = 112;
    var _button_h = 30;
    var _gap = 10;
    var _x = 40;
    var _y = display_get_gui_height() - 72;

    for (var i = 0; i < array_length(global.miracles); i++) {
        var _left = _x + i * (_button_w + _gap);
        if (_gui_x >= _left && _gui_x <= _left + _button_w && _gui_y >= _y && _gui_y <= _y + _button_h) {
            return i;
        }
    }

    return -1;
}
