package scenes

import rl "vendor:raylib"

// Der globale State, der an jeden Frame übergeben wird
DemoState :: struct {
    screen_width:           i32,
    screen_height:          i32,
    dt:                     f32,
    current_scene_index:    int,
    scene_switch_requested: bool,
}

// Das C-Style Function-Pointer Interface für unsere Szenen
Scene :: struct {
    init:   proc(state: ^DemoState),
    update: proc(state: ^DemoState),
    draw:   proc(state: ^DemoState),
    deinit: proc(state: ^DemoState),
}