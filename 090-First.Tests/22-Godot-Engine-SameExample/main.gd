extends Node2D

# --- KONFIGURATION ---
const NUM_BOUNCERS: int = 10
const CURSOR_SPEED: float = 500.0
const BOUNCER_SPEED_MIN: float = 100.0
const BOUNCER_SPEED_MAX: float = 300.0

# --- REFERENZEN ---
var cursor: Label
var bouncers: Array[Label] = []
var bouncer_velocities: Array[Vector2] = []
var screen_size: Vector2

func _ready() -> void:
    # 1. Fullscreen aktivieren
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    screen_size = get_viewport_rect().size

    # 2. "Hello World" Text oben links
    var hello_label: Label = Label.new()
    hello_label.text = "Hello World"
    hello_label.position = Vector2(20, 20)
    hello_label.add_theme_font_size_override("font_size", 32)
    add_child(hello_label)

    # 3. Den Spieler-Cursor erstellen
    cursor = Label.new()
    cursor.text = "@"
    cursor.add_theme_font_size_override("font_size", 48)
    cursor.add_theme_color_override("font_color", Color(0, 1, 0))
    cursor.position = screen_size / 2.0
    add_child(cursor)

    # 4. Die 10 springenden Buchstaben generieren
    for i in range(NUM_BOUNCERS):
        var bouncer: Label = Label.new()
        bouncer.text = String.chr(randi_range(65, 90))
        bouncer.add_theme_font_size_override("font_size", 32)

        bouncer.position = Vector2(
            randf_range(50, screen_size.x - 50),
            randf_range(50, screen_size.y - 50)
        )
        add_child(bouncer)
        bouncers.append(bouncer)

        var random_dir: Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
        var speed: float = randf_range(BOUNCER_SPEED_MIN, BOUNCER_SPEED_MAX)
        bouncer_velocities.append(random_dir * speed)

func _process(delta: float) -> void:
    screen_size = get_viewport_rect().size

    # --- CURSOR LOGIK ---
    var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    cursor.position += input_dir * CURSOR_SPEED * delta

    cursor.position.x = clamp(cursor.position.x, 0, screen_size.x - 40)
    cursor.position.y = clamp(cursor.position.y, 0, screen_size.y - 40)

    # --- BOUNCER LOGIK ---
    for i in range(NUM_BOUNCERS):
        var bouncer: Label = bouncers[i]
        var velocity: Vector2 = bouncer_velocities[i]

        bouncer.position += velocity * delta

        # Kollision mit dem Bildschirmrand
        if bouncer.position.x <= 0 or bouncer.position.x >= screen_size.x - 30:
            velocity.x *= -1.0
            bouncer.position.x = clamp(bouncer.position.x, 0, screen_size.x - 30)

        if bouncer.position.y <= 0 or bouncer.position.y >= screen_size.y - 30:
            velocity.y *= -1.0
            bouncer.position.y = clamp(bouncer.position.y, 0, screen_size.y - 30)

        bouncer_velocities[i] = velocity

    # --- EXIT LOGIK ---
    if Input.is_action_just_pressed("ui_cancel"):
        get_tree().quit()

