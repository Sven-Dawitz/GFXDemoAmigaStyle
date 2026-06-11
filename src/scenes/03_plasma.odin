package scenes

import rl "vendor:raylib"
import "core:c"
import "core:math"

// ============================================================================
//  Scene 03 : Plasma + Chiptune
//
//  A classic Amiga/C64 style palette-cycling plasma effect, accompanied by a
//  procedurally synthesized oldschool chiptune (square-wave bass, bubbly
//  C64-style arpeggio lead, four-on-the-floor kick + noise hats) and the
//  obligatory sine-wave greetings scroller.
//
//  The plasma is computed into a small CPU buffer and upscaled to fullscreen
//  with nearest-neighbour filtering -> chunky retro pixels for free.
//  The music is real synthesis on a streamed audio callback, so there is no
//  sample/MOD file to ship.
// ============================================================================

// --- Plasma configuration ---------------------------------------------------
PLASMA_W :: 256   // low-res buffer width  (upscaled to fullscreen)
PLASMA_H :: 160   // low-res buffer height

PlasmaData :: struct {
    pixels:     []rl.Color,
    texture:    rl.Texture2D,
    palette:    [256]rl.Color,
    font:       BitmapFont,
    scroll_pos: f32,
    time:       f32,
    stream:     rl.AudioStream,
    audio_ok:   bool,
}
@private pdata: PlasmaData

// --- Synth state (read from the audio thread, so keep it dumb) ---------------
Synth :: struct {
    sample_rate: f32,
    t:           u64,        // running sample index, drives everything
    bass_phase:  f32,
    lead_phase:  f32,
    kick_phase:  f32,
    rng:         u32,
    note_freq:   [128]f32,   // MIDI note -> Hz, precomputed in init
}
@private synth: Synth

// Am - F - C - G  (the timeless vi-IV-I-V), 8 steps each = 32-step loop
@private chord_root := [4]int{ 45, 41, 48, 43 }   // A2, F2, C3, G2
@private chord_kind := [4]int{ 0, 1, 1, 1 }       // 0 = minor, 1 = major
@private triad_minor := [3]int{ 0, 3, 7 }
@private triad_major := [3]int{ 0, 4, 7 }

SEQ_STEPS       :: 32
STEPS_PER_CHORD :: 8
BPM             :: 125.0

get_03_plasma_scene :: proc() -> Scene {
    return Scene{
        init   = plasma_init,
        update = plasma_update,
        draw   = plasma_draw,
        deinit = plasma_deinit,
    }
}

plasma_init :: proc(state: ^DemoState) {
    pdata.time       = 0.0
    pdata.scroll_pos = 0.0

    // Smooth, seamlessly-looping rainbow palette (RGB at 120 deg phase offsets).
    for i in 0..<256 {
        a := f32(i) / 256.0 * math.PI * 2.0
        r := u8((math.sin(a)           * 0.5 + 0.5) * 255.0)
        g := u8((math.sin(a + 2.09439) * 0.5 + 0.5) * 255.0)
        b := u8((math.sin(a + 4.18879) * 0.5 + 0.5) * 255.0)
        pdata.palette[i] = rl.Color{ r, g, b, 255 }
    }

    // CPU pixel buffer + a GPU texture we keep re-uploading each frame.
    pdata.pixels  = make([]rl.Color, PLASMA_W * PLASMA_H)
    img := rl.GenImageColor(PLASMA_W, PLASMA_H, rl.BLACK)
    pdata.texture = rl.LoadTextureFromImage(img)
    rl.UnloadImage(img)
    rl.SetTextureFilter(pdata.texture, .POINT) // nearest-neighbour = crisp pixels

    // Bold font reads well over the bright plasma.
    pdata.font = load_bitmap_font("../assets/fonts/nuskool_krome_64x64.png", 64.0)

    // --- Audio: build the chiptune on a streamed callback -------------------
    synth = Synth{}
    synth.sample_rate = 44100.0
    synth.rng = 0x1337beef
    for n in 0..<128 {
        synth.note_freq[n] = f32(440.0 * math.pow(2.0, f64(n - 69) / 12.0))
    }

    // 16-bit, mono, 44.1 kHz. (rl.InitAudioDevice() is done once in main.odin.)
    pdata.stream = rl.LoadAudioStream(u32(synth.sample_rate), 16, 1)
    rl.SetAudioStreamCallback(pdata.stream, plasma_audio_callback)
    rl.SetAudioStreamVolume(pdata.stream, 0.65)
    rl.PlayAudioStream(pdata.stream)
    pdata.audio_ok = true
}

plasma_update :: proc(state: ^DemoState) {
    pdata.time       += state.dt
    pdata.scroll_pos += 220.0 * state.dt

    if rl.IsKeyPressed(.Q) || rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.ESCAPE) {
        state.scene_switch_requested = true
    }
}

plasma_draw :: proc(state: ^DemoState) {
    t := pdata.time

    // A slowly orbiting plasma centre keeps the field swirling.
    cx := f32(PLASMA_W) * 0.5 + math.sin(t * 0.6) * f32(PLASMA_W) * 0.25
    cy := f32(PLASMA_H) * 0.5 + math.cos(t * 0.5) * f32(PLASMA_H) * 0.25
    shift := int(t * 40.0) // palette-cycle offset

    for y in 0..<PLASMA_H {
        fy  := f32(y)
        row := y * PLASMA_W
        for x in 0..<PLASMA_W {
            fx := f32(x)

            v := math.sin(fx * 0.040 + t * 1.1)
            v += math.sin(fy * 0.032 - t * 1.3)
            v += math.sin((fx + fy) * 0.024 + t * 0.7)
            dx := fx - cx
            dy := fy - cy
            v += math.sin(math.sqrt(dx*dx + dy*dy) * 0.060 - t * 1.7)

            // v is in [-4, 4]; map to a palette index, add the cycle, wrap.
            idx := int((v * 0.125 + 0.5) * 255.0) + shift
            idx &= 255
            pdata.pixels[row + x] = pdata.palette[idx]
        }
    }

    rl.UpdateTexture(pdata.texture, raw_data(pdata.pixels))

    rl.ClearBackground(rl.BLACK)
    src := rl.Rectangle{ 0, 0, f32(PLASMA_W), f32(PLASMA_H) }
    dst := rl.Rectangle{ 0, 0, f32(state.screen_width), f32(state.screen_height) }
    rl.DrawTexturePro(pdata.texture, src, dst, rl.Vector2{0, 0}, 0.0, rl.WHITE)

    // Obligatory greetings scroller across the lower third.
    scroll_text := "      ... SCENE 03 :: PLASMA + CHIPTUNE ...      GREETINGS TO EVERYONE STILL KEEPING THE OLDSCHOOL DEMO SPIRIT ALIVE !      CODED IN ODIN , RENDERED WITH RAYLIB , ALL SOUND SYNTHESIZED ON THE FLY .      PRESS SPACE TO CONTINUE THE SHOW ...      "
    draw_sin_scroller(
        state,
        pdata.font,
        base_y        = f32(state.screen_height) * 0.78,
        amplitude     = 60.0,
        frequency     = 0.0045,
        wave_speed    = 2.2,
        zoom          = 1.1,
        text_to_draw  = scroll_text,
        scroll_offset = pdata.scroll_pos,
        time_passed   = pdata.time,
    )
}

plasma_deinit :: proc(state: ^DemoState) {
    if pdata.audio_ok {
        rl.StopAudioStream(pdata.stream)
        rl.UnloadAudioStream(pdata.stream)
        pdata.audio_ok = false
    }
    unload_bitmap_font(&pdata.font)
    if pdata.texture.id != 0 {
        rl.UnloadTexture(pdata.texture)
        pdata.texture.id = 0
    }
    if pdata.pixels != nil {
        delete(pdata.pixels)
        pdata.pixels = nil
    }
}

// ----------------------------------------------------------------------------
//  Audio callback. Runs on raylib's audio thread => "c" calling convention,
//  no Odin context, no allocations. Only contextless math + global reads.
// ----------------------------------------------------------------------------
@private plasma_audio_callback :: proc "c" (buffer_data: rawptr, frames: c.uint) {
    samples := cast([^]i16)buffer_data
    n  := int(frames)
    sr := synth.sample_rate

    sec_per_step := 60.0 / f32(BPM) / 2.0   // a "step" = one 8th note
    sps := u64(sr * sec_per_step)
    if sps == 0 do sps = 1
    arp_len := u64(sr * 0.05)               // fast C64-style arpeggio note length
    if arp_len == 0 do arp_len = 1
    quarter  := sps * 2                      // 1/4 note = 2 steps
    kick_len := u64(sr * 0.11)
    hat_len  := u64(sr * 0.025)
    vib_mod  := u64(sr * 4.0)               // bounds the vibrato LFO phase (f32 precision)
    fade_len := u64(sr / 5.0)               // 0.2 s startup fade -> no click

    master :: f32(0.22)

    for i in 0..<n {
        t := synth.t

        step  := int(t / sps) % SEQ_STEPS
        ci    := step / STEPS_PER_CHORD
        root  := chord_root[ci]
        triad := chord_kind[ci] == 0 ? triad_minor : triad_major

        // --- Bass: square wave on the chord root, plucked each step ---------
        bass_freq := synth.note_freq[clamp(root, 0, 127)]
        step_frac := f32(t % sps) / f32(sps)
        bass_env  := 1.0 - step_frac
        bass_env  *= bass_env
        synth.bass_phase += bass_freq / sr
        if synth.bass_phase >= 1.0 do synth.bass_phase -= 1.0
        bass := (synth.bass_phase < 0.5 ? f32(1.0) : f32(-1.0)) * bass_env

        // --- Lead: bubbly arpeggio two octaves up, 25% pulse, light vibrato -
        sub       := int(t / arp_len) % 3
        lead_note := clamp(root + 24 + triad[sub], 0, 127)
        lead_freq := synth.note_freq[lead_note]
        lfo       := math.sin(f32(t % vib_mod) / sr * 5.0 * math.PI * 2.0)
        vib       := 1.0 + lfo * 0.006
        arp_frac  := f32(t % arp_len) / f32(arp_len)
        lead_env  := 1.0 - arp_frac
        lead_env  *= lead_env
        synth.lead_phase += lead_freq * vib / sr
        if synth.lead_phase >= 1.0 do synth.lead_phase -= 1.0
        lead := (synth.lead_phase < 0.25 ? f32(1.0) : f32(-1.0)) * lead_env

        // --- Kick: sine with a fast pitch + amp drop, every 1/4 note --------
        kick := f32(0.0)
        qpos := t % quarter
        if qpos < kick_len {
            ke := 1.0 - f32(qpos) / f32(kick_len)
            kf := 45.0 + 130.0 * ke * ke
            synth.kick_phase += kf / sr
            if synth.kick_phase >= 1.0 do synth.kick_phase -= 1.0
            kick = math.sin(synth.kick_phase * math.PI * 2.0) * ke
        }

        // --- Hat: short noise burst on the off-beat -------------------------
        hat  := f32(0.0)
        hpos := (t + sps) % quarter  // offset one step => lands off the kick
        if hpos < hat_len {
            synth.rng = synth.rng * 1664525 + 1013904223
            noise := f32(synth.rng >> 16) / 32768.0 - 1.0
            he := 1.0 - f32(hpos) / f32(hat_len)
            hat = noise * he * 0.5
        }

        fade := f32(min(t, fade_len)) / f32(fade_len)
        mix  := (bass * 0.55 + lead * 0.40 + kick * 0.9 + hat * 0.25) * master * fade
        if mix >  1.0 do mix =  1.0
        if mix < -1.0 do mix = -1.0

        samples[i] = i16(mix * 32767.0)
        synth.t += 1
    }
}
