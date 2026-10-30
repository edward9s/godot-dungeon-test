class_name GridLayoutGenerator
extends RefCounted
## Pure data. Integer 4 m sockets; geometry and physics belong to DungeonView.
const CELL := 4.0
const SIDES := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
const THEMES := ["grove", "river", "cavern", "ruins", "temple"]

func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rooms: Array[Dictionary] = []
	var floors: Dictionary = {}
	var links: Array[Vector2i] = []
	var main := {"id": 0, "center": Vector2i.ZERO, "half": Vector2i(2, 2), "theme": "sanctuary"}
	rooms.append(main)
	_carve(main, floors)
	var count := rng.randi_range(6, 7)
	for attempt in range(200):
		if rooms.size() == count:
			break
		var parent: Dictionary = rooms[rng.randi_range(0, rooms.size() - 1)]
		var side: Vector2i = SIDES[rng.randi_range(0, 3)]
		if parent.id == 0 and side == Vector2i.UP:
			continue # preserve the sanctuary's focal wall
		var half := Vector2i(rng.randi_range(2, 3), rng.randi_range(2, 3))
		var gap := rng.randi_range(2, 3)
		var reach: Vector2i = parent.half + half + Vector2i.ONE * gap
		var center: Vector2i = parent.center + side * reach
		var bounds := Rect2i(center - half - Vector2i.ONE, half * 2 + Vector2i.ONE * 3)
		var occupied := false
		for cell in floors:
			if bounds.has_point(cell):
				occupied = true
		if occupied:
			continue
		var corridor: Array[Vector2i] = []
		var cursor: Vector2i = parent.center + side * ((parent.half.x if side.x else parent.half.y) + 1)
		var end: Vector2i = center - side * ((half.x if side.x else half.y) + 1)
		while true:
			if floors.has(cursor):
				occupied = true
			corridor.append(cursor)
			if cursor == end:
				break
			cursor += side
		if occupied:
			continue
		var id := rooms.size()
		var theme: String = THEMES[(id + posmod(seed_value, THEMES.size())) % THEMES.size()]
		var room := {"id": id, "center": center, "half": half, "theme": theme}
		rooms.append(room)
		_carve(room, floors)
		for cell in corridor:
			floors[cell] = -1
		links.append(Vector2i(parent.id, id))
	assert(rooms.size() >= 5, "Unable to place enough chambers")
	# Extra routes connect parallel aligned chambers when the corridor is unobstructed.
	for a in rooms:
		for b in rooms:
			if a.id >= b.id or a.center.x != b.center.x or a.center.y >= b.center.y:
				continue
			if a.id == 0:
				continue
			var start: Vector2i = a.center + Vector2i(0, a.half.y + 1)
			var end: Vector2i = b.center - Vector2i(0, b.half.y + 1)
			if end.y <= start.y or end.y - start.y > 10:
				continue
			var clear := true
			for y in range(start.y, end.y + 1):
				if floors.has(Vector2i(start.x, y)):
					clear = false
			if clear:
				for y in range(start.y, end.y + 1):
					floors[Vector2i(start.x, y)] = -1
				links.append(Vector2i(a.id, b.id))
	# Join the closest unlinked pair to guarantee an optional cycle in every dungeon.
	var pair := Vector2i(-1, -1)
	var best := 100000
	for a in rooms:
		for b in rooms:
			if a.id >= b.id or links.has(Vector2i(a.id,b.id)):
				continue
			var dist: int = absi(a.center.x-b.center.x)+absi(a.center.y-b.center.y)
			if dist < best:
				best = dist
				pair = Vector2i(a.id,b.id)
	assert(pair.x >= 0)
	var start_cell:Vector2i=rooms[pair.x].center
	var end_cell:Vector2i=rooms[pair.y].center
	var route:Array[Vector2i]=[]
	var missing:=-1
	for x_first in [true,false]:
		var candidate:=_route(start_cell,end_cell,x_first)
		var count_missing:=0
		for point in candidate:
			if not floors.has(point):count_missing+=1
		if count_missing>missing:
			route=candidate;missing=count_missing
	if missing==0:
		# A straight branch needs a real bypass, not a duplicate graph edge.
		var outside:=0
		for point in floors:outside=mini(outside,point.x-2)
		var corner:=Vector2i(outside,start_cell.y)
		route=_route(start_cell,corner,true)
		route.append_array(_route(corner,Vector2i(outside,end_cell.y),false))
		route.append_array(_route(Vector2i(outside,end_cell.y),end_cell,true))
	for point in route:
		if not floors.has(point):floors[point]=-1
	links.append(pair)
	var exit_room := 1
	var farthest := 0.0
	for room in rooms:
		room["treasure"] = false
		var distance: float = Vector2(room.center).length_squared()
		if distance > farthest:
			farthest = distance
			exit_room = room.id
	rooms[1]["treasure"] = true
	var result := {"seed": seed_value, "rooms": rooms, "floors": floors, "links": links, "spawn": Vector3(0, .08, 4), "exit_room": exit_room}
	validate(result)
	return result

func _carve(room: Dictionary, floors: Dictionary) -> void:
	for x in range(-room.half.x, room.half.x + 1):
		for z in range(-room.half.y, room.half.y + 1):
			# Chamfered caves and ruined rooms keep all central access axes intact.
			if room.theme in ["cavern", "ruins"] and absi(x) == room.half.x and absi(z) == room.half.y:
				continue
			floors[room.center + Vector2i(x, z)] = room.id

static func world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL, 0, cell.y * CELL)

static func cell(position: Vector3) -> Vector2i:
	return Vector2i(roundi(position.x / CELL), roundi(position.z / CELL))

static func validate(layout: Dictionary) -> void:
	assert(layout.floors.has(Vector2i.ZERO))
	var visited := {Vector2i.ZERO: true}
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	var index := 0
	while index < queue.size():
		var p := queue[index]
		index += 1
		for side in SIDES:
			var next: Vector2i = p + side
			if layout.floors.has(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)
	assert(visited.size() == layout.floors.size(), "Disconnected floor")
	for room in layout.rooms:
		assert(visited.has(room.center), "Unreachable chamber")

func _route(start:Vector2i,end:Vector2i,x_first:bool) -> Array[Vector2i]:
	var result:Array[Vector2i]=[]
	var cursor:=start
	while cursor!=end:
		result.append(cursor)
		if (x_first and cursor.x!=end.x) or cursor.y==end.y:cursor.x+=signi(end.x-cursor.x)
		else:cursor.y+=signi(end.y-cursor.y)
	result.append(end)
	return result
