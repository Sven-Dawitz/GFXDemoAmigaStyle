package main

import "core:fmt"
import "core:math"
import "core:mem"
import rl "vendor:raylib"

// Die Datenstruktur, die wir an den Audio-Thread übergeben
Oscillator :: struct {
    frequency: f32,
    phase:     f32,
    wave_type: int, // 0 = Sinus (weich), 1 = Rechteck (Retro C64)
}

// Der Audio-Callback: Läuft in einem eigenen Thread!
// Füllt den Audio-Buffer direkt mit Werten zwischen -1.0 und +1.0
audio_callback :: proc "c" (bufferData: rawptr, frames: u32) {
    // Hole unseren Oszillator aus dem globalen Kontext (Raylib Callback Limitierung)
    osc := (^Oscillator)(global_osc_ptr)
    
    // Konvertiere den rohen Pointer in ein f32-Slice (Wir nutzen 32-bit Float Audio)
    samples := mem.slice_ptr((^f32)(bufferData), int(frames))
    
    sample_rate := f32(44100.0)
    
    for i := 0; i < int(frames); i += 1 {
        // Phase pro Frame weiterbewegen
        osc.phase += (math.TAU * osc.frequency) / sample_rate
        if osc.phase > math.TAU {
            osc.phase -= math.TAU
        }

        val: f32 = 0.0
        if osc.wave_type == 0 {
            // Sinus-Welle (Weicher Ton)
            val = math.sin(osc.phase)
        } else {
            // Rechteck-Welle (Dreckiger C64/Gameboy Ton)
            // Wenn die Phase in der ersten Hälfte ist: 1.0, sonst -1.0
            if math.mod(osc.phase, math.TAU) < math.PI {
                val = 0.5
            } else {
                val = -0.5
            }
        }

        samples[i] = val // Wert in den Puffer schreiben
    }
}

// Globale Variable für den Callback (nur für dieses simple Demo nötig)
global_osc_ptr: rawptr

main :: proc() {
    // Tracking Allocator für Memory-Leak-Checks
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        if len(track.allocation_map) > 0 {
            fmt.eprintf("=== %v MEMORY LEAKS GEFUNDEN ===\n", len(track.allocation_map))
        }
        mem.tracking_allocator_destroy(&track)
    }

    // Fenster für Input initialisieren
    rl.InitWindow(400, 200, "Prozeduraler Synth (C64 Style)")
    defer rl.CloseWindow()

    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()

    // Oszillator initialisieren (440 Hz = Kammer-A)
    osc := Oscillator{frequency = 440.0, phase = 0.0, wave_type = 1}
    global_osc_ptr = &osc

    // Wir erstellen einen leeren AudioStream (44100 Hz, 32-bit Float, Mono)
    rl.SetAudioStreamBufferSizeDefault(4096)
    stream := rl.LoadAudioStream(44100, 32, 1)
    defer rl.UnloadAudioStream(stream)

    // Callback registrieren
    rl.SetAudioStreamCallback(stream, audio_callback)
    rl.PlayAudioStream(stream)

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        // --- INPUT HANDLING ---
        if rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.Q) || rl.IsKeyPressed(.ESCAPE) {
            break // Beendet das Programm sauber
        }

        if rl.IsKeyPressed(.W) {
            osc.wave_type = 1 - osc.wave_type // Toggelt zwischen 0 und 1
        }

        // --- DRAWING ---
        rl.BeginDrawing()
        defer rl.EndDrawing()
        
        rl.ClearBackground(rl.BLACK)
        
        text_wave := osc.wave_type == 0 ? "SINUS (Weich)" : "RECHTECK (Retro C64)"
        color_wave := osc.wave_type == 0 ? rl.SKYBLUE : rl.GREEN
        
        rl.DrawText("Prozeduraler Audio-Generator", 10, 10, 20, rl.LIGHTGRAY)
        rl.DrawText(fmt.ctprintf("Aktuelle Welle: %s", text_wave), 10, 50, 20, color_wave)
        rl.DrawText("Drücke 'W' um Wellenform zu ändern", 10, 90, 10, rl.GRAY)
        rl.DrawText("Drücke SPACE, Q oder ESC zum Beenden", 10, 170, 10, rl.DARKGRAY)
    }
}