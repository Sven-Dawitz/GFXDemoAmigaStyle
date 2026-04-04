package main

import "core:fmt"
import "core:math/rand"
import "vendor:raylib"

NPC :: struct {
    x, y, dx, dy: i32,
    prev, next:   ^NPC,
}

NPC_List :: struct {
    head: ^NPC,
    tail: ^NPC,
}

// Allokiert einen NPC sicher über den Standard-Allocator
spawn_npc :: proc(list: ^NPC_List) {
    new_npc := new(NPC) // Nutzt context.allocator
    new_npc.x = rand.int31_max(800)
    new_npc.y = rand.int31_max(600)

    if list.head == nil {
        list.head = new_npc
    } else {
        list.tail.next = new_npc
        new_npc.prev = list.tail
    }
    list.tail = new_npc
}

main :: proc() {
    raylib.InitWindow(800, 600, "Odin Production Grade")
    defer raylib.CloseWindow()

    npcs: NPC_List
    for _ in 0..<25 do spawn_npc(&npcs)

    player_pos := raylib.Vector2{400, 300}
    
    raylib.SetTargetFPS(60)

    for !raylib.WindowShouldClose() {
        dt := raylib.GetFrameTime()
        move_speed : f32 = 200.0

        if raylib.IsKeyDown(.LEFT)  do player_pos.x -= move_speed * dt
        if raylib.IsKeyDown(.RIGHT) do player_pos.x += move_speed * dt
        if raylib.IsKeyDown(.UP)    do player_pos.y -= move_speed * dt
        if raylib.IsKeyDown(.DOWN)  do player_pos.y += move_speed * dt

        raylib.BeginDrawing()
        defer raylib.EndDrawing()
        
        raylib.ClearBackground(raylib.BLACK)

        for curr := npcs.head; curr != nil; curr = curr.next {
            raylib.DrawPixel(curr.x, curr.y, raylib.RED)
        }

        raylib.DrawText("@", i32(player_pos.x), i32(player_pos.y), 20, raylib.RAYWHITE)
    }
}