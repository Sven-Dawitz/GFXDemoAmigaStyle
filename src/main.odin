package main

import "core:fmt"
import rl "vendor:raylib"
import "scenes"

main :: proc() {
    demoInit()
    defer demoExit()

    // Hier fügst du später einfach scenes.get_03_parallax_scene() etc. hinzu
    all_scenes := [?]scenes.Scene{
        scenes.get_intro_scene(),
        scenes.get_starfield_scene(),
    }

    state := scenes.DemoState{
        screen_width           = rl.GetScreenWidth(),
        screen_height          = rl.GetScreenHeight(),
        current_scene_index    = 0,
        scene_switch_requested = false,
    }

    // Erste Szene initialisieren
    if len(all_scenes) > 0 {
        all_scenes[state.current_scene_index].init(&state)
    }

    for !rl.WindowShouldClose() {
        // WICHTIG: Temp-Speicher jeden Frame zurücksetzen!
        free_all(context.temp_allocator)

        state.dt = rl.GetFrameTime()

        // Scene Management Logik
        if state.scene_switch_requested {
            all_scenes[state.current_scene_index].deinit(&state)
            
            state.current_scene_index += 1
            if state.current_scene_index >= len(all_scenes) {
                break // Demo beenden, wenn letzte Szene durch ist
            }
            
            all_scenes[state.current_scene_index].init(&state)
            state.scene_switch_requested = false
        }

        // Aktuelle Szene updaten
        all_scenes[state.current_scene_index].update(&state)

        // Rendering
        rl.BeginDrawing()
        all_scenes[state.current_scene_index].draw(&state)
        rl.EndDrawing()
        
    }

    // Letzte aktive Szene beim harten Beenden sauber abräumen
    if state.current_scene_index < len(all_scenes) {
        all_scenes[state.current_scene_index].deinit(&state)
    }
}

demoInit :: proc() {
    rl.InitWindow(0, 0, "Odin Raylib Demo")
    
    // Borderless Window Setup (Auflösung vom aktuellen Monitor abgreifen)
    monitor := rl.GetCurrentMonitor()
    w := rl.GetMonitorWidth(monitor)
    h := rl.GetMonitorHeight(monitor)
    
    rl.SetWindowSize(w, h)
    rl.SetWindowState({.WINDOW_UNDECORATED})
    rl.SetTargetFPS(60)
    
    // Mauszeiger ausblenden fürs Demo-Feeling
    rl.HideCursor()
}

demoExit :: proc() {
    rl.CloseWindow()
}