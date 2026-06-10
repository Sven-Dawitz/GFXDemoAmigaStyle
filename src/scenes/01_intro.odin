package scenes

import rl "vendor:raylib"
import "core:fmt"
import "core:math"

SceneData :: struct {
    nuskool_font: BitmapFont,
    digi_font:    BitmapFont,
    gold_font:    BitmapFont,
    
    scroller1_pos: f32,
    scroller2_pos: f32,
    time_passed:   f32,
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
    scenedata.scroller1_pos = 0.0
    scenedata.scroller2_pos = 0.0
    scenedata.time_passed = 0.0

    scenedata.nuskool_font = load_bitmap_font("../assets/fonts/nuskool_krome_64x64.png", 64.0)
    scenedata.digi_font    = load_bitmap_font("../assets/fonts/digifont_16x16.png", 16.0)
    scenedata.gold_font    = load_bitmap_font("../assets/fonts/gold_8x8.png", 8.0)
}

intro_update :: proc(state: ^DemoState) {
    scenedata.time_passed += state.dt

    // Scroller speeds
    scenedata.scroller1_pos += 450.0 * state.dt // Upper, faster
    scenedata.scroller2_pos += 250.0 * state.dt // Lower, slower (to take ~40 seconds for long text)

    // Exit Condition
    if rl.IsKeyPressed(.Q) || rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.ESCAPE) {
        state.scene_switch_requested = true
    }
}

intro_draw :: proc(state: ^DemoState) {
    // 1. Draw Raster Bars / Palette Shifting Background
    for y := 0; y < int(state.screen_height); y += 4 {
        // Create an Amiga-style copper background effect with sine waves
        val1 := math.sin(f32(y) * 0.01 + scenedata.time_passed * 4.0)
        val2 := math.cos(f32(y) * 0.015 - scenedata.time_passed * 2.5)
        
        // Map to deep retro colors (blues and purples)
        r := u8((val1 + 1.0) * 0.5 * 60.0) 
        g := u8((val2 + 1.0) * 0.5 * 30.0)
        b := u8((val1 + val2 + 2.0) * 0.25 * 100.0 + 40.0)
        
        rl.DrawRectangle(0, i32(y), state.screen_width, 4, rl.Color{r, g, b, 255})
    }

    // 2. Draw static text (like FPS)
    fps_text := fmt.ctprintf("FPS: %d | Res: %dx%d", rl.GetFPS(), state.screen_width, state.screen_height)
    rl.DrawText(fps_text, 10, 10, 20, rl.LIGHTGRAY)
    rl.DrawText("AMIGA RULEZ", 10, 40, 20, rl.DARKGRAY)

    // 3. Draw Upper Sine Scroller (Nuskool Font, big, repeating text)
    upper_text := "   ... ITGUY23 USING ODIN AND RAYLIB FOR AWESOMESAUCE DEMOS ...   "
    draw_sin_scroller(
        state, 
        scenedata.nuskool_font, 
        base_y        = f32(state.screen_height) * 0.2, // Upper area
        amplitude     = 85.0,
        frequency     = 0.0035,
        wave_speed    = 2.8,
        zoom          = 1.5,
        text_to_draw  = upper_text, 
        scroll_offset = scenedata.scroller1_pos, 
        time_passed   = scenedata.time_passed
    )

    // 4. Draw Lower Sine Scroller (Gold Font, long custom text > 40s)
    lower_text := "    ... WELCOME TO ANOTHER OLDSCHOOL DEMO. THIS TIME WE ARE EXPLORING THE POWER OF ODIN COMBINED WITH RAYLIB. A TRULY MAGICAL COMBINATION THAT BRINGS BACK THE GLORY DAYS OF THE AMIGA 500 AND COMMODORE 64.  ITGUY23 IS CODING LIKE A MADMAN IN NEOVIM, MULTIPLEXING TERMINALS WITH BYOBU, AND COMPILING AT BLAZING SPEEDS.  IF YOU ARE READING THIS, YOU PROBABLY REMEMBER THE SOUND OF A FLOPPY DISK DRIVE LOADING YOUR FAVORITE CRACKTRO.  GREETINGS TO ALL THE OLDSCENE MEMBERS AND MODERN RETRO CODERS KEEPING THE SPIRIT ALIVE.  STAY AWESOME AND KEEP CODING! ...    "
    draw_sin_scroller(
        state, 
        scenedata.gold_font, 
        base_y        = f32(state.screen_height) * 0.75, // Lower area
        amplitude     = 55.0,
        frequency     = 0.0075,
        wave_speed    = -1.9, // Wave moves in opposite direction and different speed
        zoom          = 4.0,  // Scale up the 8x8 font so it's readable
        text_to_draw  = lower_text, 
        scroll_offset = scenedata.scroller2_pos, 
        time_passed   = scenedata.time_passed
    )

    // 5. Draw a bouncing retro logo or text in the middle
    logo_text := "  CRACKED BY ITGUY23  "
    logo_zoom :: 3.0
    logo_width := f32(len(logo_text)) * scenedata.digi_font.char_size * logo_zoom
    max_x := f32(state.screen_width) - logo_width
    
    // Smooth ping-pong bounce between edges
    logo_x := (math.sin(scenedata.time_passed * 1.0) * 0.5 + 0.5) * max_x
    // Also bob up and down slightly for extra polish
    logo_y := f32(state.screen_height) * 0.5 - 30.0 + math.cos(scenedata.time_passed * 4.0) * 25.0
    
    draw_bitmap_text(state, scenedata.digi_font, logo_x, logo_y, logo_zoom, logo_text)
}

intro_deinit :: proc(state: ^DemoState) {
    unload_bitmap_font(&scenedata.nuskool_font)
    unload_bitmap_font(&scenedata.digi_font)
    unload_bitmap_font(&scenedata.gold_font)
}
