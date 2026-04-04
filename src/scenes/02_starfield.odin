package scenes

import rl "vendor:raylib"
import "core:math"

@private time_passed: f32

get_starfield_scene :: proc() -> Scene {
    return Scene{
        init   = starfield_init,
        update = starfield_update,
        draw   = starfield_draw,
        deinit = starfield_deinit,
    }
}

starfield_init :: proc(state: ^DemoState) {
    time_passed = 0.0
}

starfield_update :: proc(state: ^DemoState) {
    time_passed += state.dt

    if rl.IsKeyPressed(.Q) || rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.ESCAPE) {
        state.scene_switch_requested = true
    }
}

starfield_draw :: proc(state: ^DemoState) {
    rl.ClearBackground(rl.DARKBLUE)

    text: cstring = "hello world. this is the end"
    font_size: i32 = 40

    // Sinus-Bouncer
    center_y := f32(state.screen_height) / 2.0
    y_pos := center_y + math.sin(time_passed * 3.0) * 150.0
    
    text_width := f32(rl.MeasureText(text, font_size))
    x_pos := (f32(state.screen_width) / 2.0) - (text_width / 2.0)

    rl.DrawText(text, i32(x_pos), i32(y_pos), font_size, rl.YELLOW)
}

starfield_deinit :: proc(state: ^DemoState) {
}