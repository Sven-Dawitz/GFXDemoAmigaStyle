package scenes

import rl "vendor:raylib"
import "core:math"

// Represents a loaded bitmap font where characters start from ASCII 32 (Space)
BitmapFont :: struct {
    texture:   rl.Texture2D,
    char_size: f32,
}

// Loads a bitmap font texture and sets its character grid size
load_bitmap_font :: proc(path: cstring, char_size: f32) -> BitmapFont {
    return BitmapFont{
        texture   = rl.LoadTexture(path),
        char_size = char_size,
    }
}

// Unloads the font texture from GPU memory
unload_bitmap_font :: proc(font: ^BitmapFont) {
    if font.texture.id != 0 {
        rl.UnloadTexture(font.texture)
        font.texture.id = 0
    }
}

// Draws normal, non-scrolling text
draw_bitmap_text :: proc(state: ^DemoState, font: BitmapFont, x: f32, y: f32, zoom: f32, text_to_draw: string) {
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
            x = current_x,
            y = y,
            width = font.char_size * zoom,
            height = font.char_size * zoom,
        }

        rl.DrawTexturePro(font.texture, src_rec, dest_rec, rl.Vector2{0, 0}, 0.0, rl.WHITE)
        current_x += (font.char_size * zoom)
    }
}

// Draws a classic Amiga-style sine wave scroller that wraps around infinitely
draw_sin_scroller :: proc(state: ^DemoState, font: BitmapFont, base_y: f32, amplitude: f32, frequency: f32, wave_speed: f32, zoom: f32, text_to_draw: string, scroll_offset: f32, time_passed: f32) {
    if font.texture.id == 0 do return
    if len(text_to_draw) == 0 do return

    columns := f32(font.texture.width) / font.char_size
    char_width := font.char_size * zoom
    
    // Where are we in the text string?
    start_x := -math.mod(scroll_offset, char_width)
    first_char_idx := int(scroll_offset / char_width)

    current_x := start_x
    num_chars_to_draw := int(f32(state.screen_width) / char_width) + 2

    for i in 0..<num_chars_to_draw {
        char_idx := (first_char_idx + i) % len(text_to_draw)
        if char_idx < 0 {
            char_idx += len(text_to_draw)
        }
        char := text_to_draw[char_idx]

        ascii := int(char)
        if ascii >= 32 {
            index := f32(ascii - 32)
            col := f32(int(index) % int(columns))
            row := f32(int(index) / int(columns))

            src_rec := rl.Rectangle{
                x = col * font.char_size,
                y = row * font.char_size,
                width = font.char_size,
                height = font.char_size,
            }

            // Organic wave calculation combining multiple sine and cosine waves
            wave_val := math.sin(current_x * frequency + time_passed * wave_speed)
            wave_val += 0.35 * math.cos(current_x * (frequency * 2.3) + time_passed * (wave_speed * 1.5))
            wave_val += 0.15 * math.sin(current_x * (frequency * 4.7) - time_passed * (wave_speed * 2.8))
            
            y_offset := wave_val * amplitude

            dest_rec := rl.Rectangle{
                x = current_x,
                y = base_y + y_offset,
                width = font.char_size * zoom,
                height = font.char_size * zoom,
            }

            rl.DrawTexturePro(font.texture, src_rec, dest_rec, rl.Vector2{0, 0}, 0.0, rl.WHITE)
        }

        current_x += char_width
    }
}
