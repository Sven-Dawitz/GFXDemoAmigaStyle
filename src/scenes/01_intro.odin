package scenes

import rl "vendor:raylib"
import "core:fmt"

// Szene-spezifischer Speicher (privat für diese Datei)
@private cursor_x: f32
@private cursor_y: f32

get_intro_scene :: proc() -> Scene {
    return Scene{
        init   = intro_init,
        update = intro_update,
        draw   = intro_draw,
        deinit = intro_deinit,
    }
}

intro_init :: proc(state: ^DemoState) {
    cursor_x = f32(state.screen_width) / 2.0
    cursor_y = f32(state.screen_height) / 2.0
}

intro_update :: proc(state: ^DemoState) {
    speed: f32 = 400.0 * state.dt

    if rl.IsKeyDown(.LEFT)  do cursor_x -= speed
    if rl.IsKeyDown(.RIGHT) do cursor_x += speed
    if rl.IsKeyDown(.UP)    do cursor_y -= speed
    if rl.IsKeyDown(.DOWN)  do cursor_y += speed

    // Exit Condition für die Scene
    if rl.IsKeyPressed(.Q) || rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.ESCAPE) {
        state.scene_switch_requested = true
    }
}

intro_draw :: proc(state: ^DemoState) {
    rl.ClearBackground(rl.BLACK)

    // Odins geniale Temp-Allocation in Action
    fps_text := fmt.ctprintf("FPS: %d | Res: %dx%d", rl.GetFPS(), state.screen_width, state.screen_height)
    
    rl.DrawText("hello world", 10, 10, 20, rl.WHITE)
    rl.DrawText(fps_text, 10, 40, 20, rl.DARKGRAY)

    // Cursor zeichnen
    rl.DrawRectangle(i32(cursor_x), i32(cursor_y), 20, 20, rl.RED)
}

intro_deinit :: proc(state: ^DemoState) {
    // Hier räumen wir später Texturen oder Shader ab
}