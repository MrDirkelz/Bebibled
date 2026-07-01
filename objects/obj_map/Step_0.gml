/// obj_map :: Step
/// Scroll (wheel + drag) and tap detection. A drag that barely moves is a tap.

gui_w = display_get_gui_width();
gui_h = display_get_gui_height();

var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _total = node_total();

if (locked_flash != 0 && !mouse_check_button(mb_left)) locked_flash = 0;

// wheel scrolling
if (mouse_wheel_up())   scroll_target -= MAP_NODE_SPACING;
if (mouse_wheel_down()) scroll_target += MAP_NODE_SPACING;

// drag scrolling
if (mouse_check_button_pressed(mb_left)) {
    drag_active       = true;
    moved             = false;
    press_mx          = _mx;
    press_my          = _my;
    drag_start_my     = _my;
    drag_start_scroll = scroll_target;
}

if (drag_active && mouse_check_button(mb_left)) {
    scroll_target = drag_start_scroll + (_my - drag_start_my);
    if (abs(_my - press_my) > 12 || abs(_mx - press_mx) > 12) moved = true;
}

if (mouse_check_button_released(mb_left)) {
    if (drag_active && !moved) handle_tap(_mx, _my);
    drag_active = false;
}

// clamp + smooth
var _smax = map_scroll_max(_total, gui_h);
scroll_target = clamp(scroll_target, 0, _smax);
scroll = lerp(scroll, scroll_target, 0.35);
