extends SceneTree
const Generator = preload("res://scripts/dungeon_generator.gd")
const Navigation = preload("res://scripts/navigation.gd")

func _initialize() -> void:
    var cycles := 0
    for seed_value in range(1000):
        var first: Dictionary = Generator.new().generate(seed_value)
        var second: Dictionary = Generator.new().generate(seed_value)
        assert(first == second, "Layout generation changed across identical seeds")
        assert(first.rooms.size() >= 5)
        cycles += int(first.links.size() >= first.rooms.size())
        for cell in first.floors:
            assert(first.floors[cell] >= -1 and first.floors[cell] < first.rooms.size())
        var navigation := Navigation.new()
        navigation.build(first)
        for room in first.rooms:
            var destination: Vector3 = Generator.world(room.center)
            var path: Array[Vector3] = navigation.route(Generator.world(Vector2i.ZERO), destination)
            assert(not path.is_empty() and path[-1].is_equal_approx(destination), "Unreachable destination")
            assert(navigation.has_floor(destination), "Destination has no floor")
    assert(cycles > 0, "No cyclic layouts were generated")
    print("Core validation passed: deterministic layouts, connectivity and routing across 1000 seeds")
    quit()
