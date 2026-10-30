extends RefCounted
var graph := AStar3D.new()
var ids: Dictionary = {}

func build(layout: Dictionary) -> void:
	graph.clear()
	ids.clear()
	for cell in layout.floors:
		ids[cell] = ids.size()
		graph.add_point(ids[cell],GridLayoutGenerator.world(cell))
	for cell in ids:
		for side in [Vector2i.RIGHT,Vector2i.DOWN]:
			if ids.has(cell+side): graph.connect_points(ids[cell],ids[cell+side])

func route(from: Vector3, to: Vector3) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var a := GridLayoutGenerator.cell(from)
	var b := GridLayoutGenerator.cell(to)
	if not ids.has(a) or not ids.has(b): return result
	var points := graph.get_point_path(ids[a],ids[b])
	# Retain grid centers at corners; movement itself remains continuous/physical.
	for i in range(1,points.size()): result.append(points[i])
	var destination:=Vector3(to.x,0,to.z)
	if result.is_empty() or result[-1]!=destination:result.append(destination)
	return result

func has_floor(at:Vector3) -> bool:
	return ids.has(GridLayoutGenerator.cell(at))
