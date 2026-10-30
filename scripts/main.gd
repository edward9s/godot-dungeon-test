extends Node3D
const Generator = preload("res://scripts/dungeon_generator.gd")
const Navigation = preload("res://scripts/navigation.gd")

func _ready() -> void:
    var layout: Dictionary = Generator.new().generate(240927)
    var navigator := Navigation.new()
    navigator.build(layout)
    assert(not navigator.route(Vector3.ZERO, Generator.world(layout.rooms[-1].center)).is_empty())

    var block := BoxMesh.new()
    block.size = Vector3(3.8, 0.12, 3.8)
    var grid := MultiMesh.new()
    grid.transform_format = MultiMesh.TRANSFORM_3D
    grid.mesh = block
    grid.instance_count = layout.floors.size()
    var index := 0
    for cell in layout.floors:
        grid.set_instance_transform(index, Transform3D(Basis.IDENTITY, Generator.world(cell)))
        index += 1

    var display := MultiMeshInstance3D.new()
    display.multimesh = grid
    add_child(display)

    var ambient := WorldEnvironment.new()
    var settings := Environment.new()
    settings.background_mode = Environment.BG_COLOR
    settings.background_color = Color(0.07, 0.09, 0.12)
    ambient.environment = settings
    add_child(ambient)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55, 20, -15)
    add_child(light)

    var camera := Camera3D.new()
    add_child(camera)
    camera.position = Vector3(35, 95, 65)
    camera.look_at(Vector3.ZERO)
    camera.current = true
