class_name S3DLoader


class S3D_Vertex:
	var position: Vector3
	var normal: Vector3
	var color: Color

class S3D_Mesh:
	var vertices: Array[S3D_Vertex]
	var indices: Array[int]

static func load(path: String) -> Mesh:
	var mesh_data := FileAccess.get_file_as_bytes(path)
	if mesh_data.is_empty(): return null
	
	var mesh_data_offset := 0
	
	var num_vertices := mesh_data.decode_u32(mesh_data_offset)
	mesh_data_offset += 4
	var num_indices := mesh_data.decode_u32(mesh_data_offset)
	mesh_data_offset += 4
	
	var mesh := S3D_Mesh.new()
	mesh.vertices.resize(num_vertices)
	mesh.indices.resize(num_indices)
	
	for i in range(num_vertices):
		var vertex := S3D_Vertex.new()
		vertex.position = Vector3(
			mesh_data.decode_float(mesh_data_offset),
			mesh_data.decode_float(mesh_data_offset+4),
			mesh_data.decode_float(mesh_data_offset+4+4)
		)
		mesh_data_offset += 4 + 4 + 4
		vertex.normal = Vector3(
			mesh_data.decode_float(mesh_data_offset),
			mesh_data.decode_float(mesh_data_offset+4),
			mesh_data.decode_float(mesh_data_offset+4+4)
		)
		mesh_data_offset += 4 + 4 + 4
		vertex.color = Color(
			mesh_data.decode_float(mesh_data_offset),
			mesh_data.decode_float(mesh_data_offset+4),
			mesh_data.decode_float(mesh_data_offset+4+4)
		)
		mesh_data_offset += 4 + 4 + 4
		mesh.vertices[i] = vertex
	
	@warning_ignore("integer_division")
	for i in range(int(num_indices / 3)):
		mesh.indices[3*i] = mesh_data.decode_u32(mesh_data_offset)
		mesh.indices[3*i + 1] = mesh_data.decode_u32(mesh_data_offset+4+4)
		mesh.indices[3*i + 2] = mesh_data.decode_u32(mesh_data_offset+4)
		mesh_data_offset += 4 + 4 + 4
	
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for vertex in mesh.vertices:
		st.set_normal(vertex.normal)
		st.set_color(vertex.color)
		st.add_vertex(vertex.position)
	
	for index in mesh.indices:
		st.add_index(index)
	
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	st.set_material(material)
	
	return st.commit()
