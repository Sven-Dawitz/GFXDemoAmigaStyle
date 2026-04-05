package scenes

import rl "vendor:raylib"
import "core:fmt"

// Szene-spezifischer Speicher (privat für diese Datei)
BitmapFont :: struct {
    texture:   rl.Texture2D,
    char_size: f32
}

SceneData :: struct {
    // font related
    nuskool_font: BitmapFont,
    digi_font:    BitmapFont,
    gold_font:    BitmapFont,
    scrollPos:    f32,
}
@private scenedata: SceneData

get_intro_scene :: proc() -> Scene {
    return Scene{
        init   = intro_init,
        update = intro_update,
        draw   = intro_draw,
        deinit = intro_deinit,
    }
}

intro_init :: proc(state: ^DemoState) {
    scenedata.scrollPos = 0.0
    scenedata.nuskool_font = BitmapFont{
        texture   = rl.LoadTexture("../assets/fonts/nuskool_krome_64x64.png"),
        char_size = 64.0,
    }

    scenedata.digi_font = BitmapFont{
        texture   = rl.LoadTexture("../assets/fonts/digifont_16x16.png"),
        char_size = 16.0,
    }

    scenedata.gold_font = BitmapFont{
        texture   = rl.LoadTexture("../assets/fonts/gold_8x8.png"),
        char_size = 8.0,
    }
}

intro_update :: proc(state: ^DemoState) {
    speed: f32 = 400.0 * state.dt

    // Exit Condition für die Scene
    if rl.IsKeyPressed(.Q) || rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.ESCAPE) {
        state.scene_switch_requested = true
    }
    scenedata.scrollPos += 2.0
}

intro_draw :: proc(state: ^DemoState) {
    rl.ClearBackground(rl.BLACK)

    // Odins geniale Temp-Allocation in Action
    fps_text := fmt.ctprintf("FPS: %d | Res: %dx%d", rl.GetFPS(), state.screen_width, state.screen_height)

    rl.DrawText("hello world", 10, 10, 20, rl.WHITE)
    rl.DrawText(fps_text, 10, 40, 20, rl.DARKGRAY)

    // Nuskool unskaliert
    font_draw_text(state, scenedata.nuskool_font, 10.0, 50.0, 1.0, "NUSKOOL 64")

    // Digi skaliert (x2)
    font_draw_text(state, scenedata.digi_font, 10.0, 150.0, 2.0, "DIGI FONT 16")

    // Gold stark skaliert (x4)
    font_draw_text(state, scenedata.gold_font, 10.0, 200.0, 4.0, "GOLD 8X8 CHUNKY")
}

intro_deinit :: proc(state: ^DemoState) {
    // Hier räumen wir später Texturen oder Shader ab
    rl.UnloadTexture(scenedata.nuskool_font.texture)
    rl.UnloadTexture(scenedata.digi_font.texture)
    rl.UnloadTexture(scenedata.gold_font.texture)
}

// 4. Die universelle Draw-Funktion für unsere Custom-Fonts
font_draw_text :: proc(state: ^DemoState, font: BitmapFont, x: f32, y: f32, zoom: f32, text_to_draw: string) {
    if font.texture.id == 0 do return

    columns := f32(font.texture.width) / font.char_size
    current_x := x

    for char in text_to_draw {
        ascii := int(char)

        if ascii < 32 do continue

        index := f32(ascii - 32)

        col := f32(int(index) % int(columns))
        row := f32(int(index) / int(columns))

        src_rec := rl.Rectangle{
            x = col * font.char_size,
            y = row * font.char_size,
            width = font.char_size,
            height = font.char_size,
        }

        dest_rec := rl.Rectangle{
            x = f32(state.screen_width) - current_x - scenedata.scrollPos,
            y = y,
            width = font.char_size * zoom,
            height = font.char_size * zoom,
        }

        rl.DrawTexturePro(font.texture, src_rec, dest_rec, rl.Vector2{0, 0}, 0.0, rl.WHITE)

        current_x += (font.char_size * zoom)
    }
}
