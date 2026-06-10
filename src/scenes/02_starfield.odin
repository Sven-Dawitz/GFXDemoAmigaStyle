package scenes

import rl "vendor:raylib"
import "core:math/rand"

Star :: struct {
    x: f32,
    y: f32,
    z: f32,
}

NUM_STARS :: 1500
@private stars: [NUM_STARS]Star
@private current_warp_speed: f32
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
    current_warp_speed = 10.0 // Start very slow (dots)
    
    for i in 0..<NUM_STARS {
        stars[i].x = rand.float32() * 2000.0 - 1000.0
        stars[i].y = rand.float32() * 2000.0 - 1000.0
        stars[i].z = rand.float32() * 990.0 + 10.0
    }
}

starfield_update :: proc(state: ^DemoState) {
    time_passed += state.dt

    // Increase speed slowly to warp speed
    current_warp_speed += 120.0 * state.dt
    if current_warp_speed > 3000.0 {
        current_warp_speed = 3000.0
    }

    if rl.IsKeyPressed(.Q) || rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.ESCAPE) {
        state.scene_switch_requested = true
    }

    for i in 0..<NUM_STARS {
        stars[i].z -= current_warp_speed * state.dt
        if stars[i].z <= 1.0 {
            stars[i].x = rand.float32() * 2000.0 - 1000.0
            stars[i].y = rand.float32() * 2000.0 - 1000.0
            stars[i].z = 1000.0 // reset back far away
        }
    }
}

starfield_draw :: proc(state: ^DemoState) {
    rl.ClearBackground(rl.BLACK)

    center_x := f32(state.screen_width) / 2.0
    center_y := f32(state.screen_height) / 2.0
    fov := f32(state.screen_width) * 0.8 // slightly adjust FOV to look better

    for i in 0..<NUM_STARS {
        z := stars[i].z
        if z <= 0.0 do continue

        sx := (stars[i].x / z) * fov + center_x
        sy := (stars[i].y / z) * fov + center_y

        prev_z := z + current_warp_speed * state.dt
        psx := (stars[i].x / prev_z) * fov + center_x
        psy := (stars[i].y / prev_z) * fov + center_y

        color_intensity := 1.0 - (z / 1000.0)
        if color_intensity < 0.0 do color_intensity = 0.0
        if color_intensity > 1.0 do color_intensity = 1.0
        
        c_val := u8(color_intensity * 255.0)
        color := rl.Color{c_val, c_val, c_val, 255}

        // Draw line with variable thickness
        thickness := max(1.0, 4.0 * color_intensity)
        
        dist_sq := (sx - psx)*(sx - psx) + (sy - psy)*(sy - psy)
        if dist_sq < 1.0 {
            rl.DrawCircleV({sx, sy}, thickness / 2.0, color)
        } else {
            rl.DrawLineEx({psx, psy}, {sx, sy}, thickness, color)
        }
    }
}

starfield_deinit :: proc(state: ^DemoState) {
}