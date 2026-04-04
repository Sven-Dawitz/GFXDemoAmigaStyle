package main

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

// --- KONFIGURATION ---
NUM_BOUNCERS :: 10
CURSOR_SPEED :: 500.0
BOUNCER_SPEED_MIN :: 100.0
BOUNCER_SPEED_MAX :: 300.0

// Struct, um die Daten der herumspringenden Buchstaben sauber zu verwalten
Bouncer :: struct {
    pos: rl.Vector2,
    vel: rl.Vector2,
    char_str: cstring,
}

main :: proc() {
    // --- 1. System & Fenster Initialisierung ---
    // Startet ein Dummy-Fenster, holt die Monitorauflösung und schaltet auf Fullscreen
    rl.InitWindow(800, 600, "Odin Raylib Demo")
    monitor := rl.GetCurrentMonitor()
    screen_w := f32(rl.GetMonitorWidth(monitor))
    screen_h := f32(rl.GetMonitorHeight(monitor))

    rl.SetWindowSize(i32(screen_w), i32(screen_h))
    rl.ToggleFullscreen()
    rl.SetTargetFPS(60)

    // --- 2. Speicher-Allokation und Startwerte ---
    cursor_pos := rl.Vector2{screen_w / 2.0, screen_h / 2.0}
    bouncers: [NUM_BOUNCERS]Bouncer

    // Raylib erwartet rohe C-Strings für den Draw-Call
    letters := [26]cstring{"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}

    for i in 0..<NUM_BOUNCERS {
        // Startposition (mit Abstand zum Rand)
        bouncers[i].pos = rl.Vector2{
            rand.float32_range(50.0, screen_w - 50.0),
            rand.float32_range(50.0, screen_h - 50.0),
        }

        // Zufällige Richtung manuell berechnen und normalisieren (Länge = 1)
        dir_x := rand.float32_range(-1.0, 1.0)
        dir_y := rand.float32_range(-1.0, 1.0)
        length := math.sqrt(dir_x * dir_x + dir_y * dir_y)
        if length > 0 {
            dir_x /= length
            dir_y /= length
        }

        // Geschwindigkeit auf den Vektor anwenden
        speed := rand.float32_range(BOUNCER_SPEED_MIN, BOUNCER_SPEED_MAX)
        bouncers[i].vel = rl.Vector2{dir_x * speed, dir_y * speed}

        // Einen Buchstaben von A-Z ziehen
        bouncers[i].char_str = letters[rand.int_max(26)]
    }

    // --- 3. Die Game-Loop ---
    // WindowShouldClose() fängt den Input der ESC-Taste nativ ab
    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()

        // --- CURSOR LOGIK ---
        input_dir := rl.Vector2{0, 0}
        // Odin's `do` Syntax macht einzeilige if-Abfragen extrem lesbar
        if rl.IsKeyDown(.LEFT)  do input_dir.x -= 1
        if rl.IsKeyDown(.RIGHT) do input_dir.x += 1
        if rl.IsKeyDown(.UP)    do input_dir.y -= 1
        if rl.IsKeyDown(.DOWN)  do input_dir.y += 1

        // Verhindert, dass man bei diagonalem Laufen (z.B. Oben + Rechts) schneller ist
        length := math.sqrt(input_dir.x * input_dir.x + input_dir.y * input_dir.y)
        if length > 0 {
            input_dir.x /= length
            input_dir.y /= length
        }

        // Position updaten
        cursor_pos.x += input_dir.x * CURSOR_SPEED * dt
        cursor_pos.y += input_dir.y * CURSOR_SPEED * dt

        // Im Bildschirm einklemmen
        cursor_pos.x = math.clamp(cursor_pos.x, 0, screen_w - 40)
        cursor_pos.y = math.clamp(cursor_pos.y, 0, screen_h - 40)

        // --- BOUNCER LOGIK ---
        for i in 0..<NUM_BOUNCERS {
            // Pointer nutzen, um das Struct direkt im Array zu manipulieren
            b := &bouncers[i]
            b.pos.x += b.vel.x * dt
            b.pos.y += b.vel.y * dt

            // Reflexion am Bildschirmrand (Kollision)
            if b.pos.x <= 0 || b.pos.x >= screen_w - 30 {
                b.vel.x *= -1.0
                b.pos.x = math.clamp(b.pos.x, 0, screen_w - 30)
            }
            if b.pos.y <= 0 || b.pos.y >= screen_h - 30 {
                b.vel.y *= -1.0
                b.pos.y = math.clamp(b.pos.y, 0, screen_h - 30)
            }
        }

        // --- 4. RENDERING ---
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        rl.DrawText("Hello World", 20, 20, 32, rl.WHITE)

        // Der grüne Spieler-Cursor (Raylib verlangt hier i32 für die Koordinaten)
        rl.DrawText("@", i32(cursor_pos.x), i32(cursor_pos.y), 48, rl.GREEN)

        // Bouncer zeichnen
        for i in 0..<NUM_BOUNCERS {
            b := bouncers[i]
            rl.DrawText(b.char_str, i32(b.pos.x), i32(b.pos.y), 32, rl.WHITE)
        }

        rl.EndDrawing()
    }

    // --- 5. CLEANUP ---
    // Manuelles Freigeben der GPU-Ressourcen
    rl.CloseWindow()
}
