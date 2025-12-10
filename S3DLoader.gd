class_name S3DLoader


class S3D_Vertex:
	var position: Vector3
	var normal: Vector3
	var tex_coord: Vector2

class S3D_Mesh:
	var vertices: Array[S3D_Vertex]
	var indices: Array[int]
	var texture_RGBA: PackedByteArray

static func load(path: String) -> Mesh:
	var mesh_data := FileAccess.get_file_as_bytes(path)
	if mesh_data.is_empty(): return null
	
	var mesh_data_offset := 0
	
	var num_vertices := mesh_data.decode_u32(mesh_data_offset)
	mesh_data_offset += 4
	var num_indices := mesh_data.decode_u32(mesh_data_offset)
	mesh_data_offset += 4
	var texture_RGBA_count := mesh_data.decode_u32(mesh_data_offset)
	mesh_data_offset += 4
	
	var mesh := S3D_Mesh.new()
	mesh.vertices.resize(num_vertices)
	mesh.indices.resize(num_indices)
	mesh.texture_RGBA.resize(texture_RGBA_count * 4)
	
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
		vertex.tex_coord = Vector2(
			mesh_data.decode_float(mesh_data_offset),
			mesh_data.decode_float(mesh_data_offset+4)
		)
		mesh_data_offset += 4 + 4
		mesh.vertices[i] = vertex
	
	@warning_ignore("integer_division")
	for i in range(int(num_indices / 3)):
		mesh.indices[3*i] = mesh_data.decode_u32(mesh_data_offset)
		mesh.indices[3*i + 1] = mesh_data.decode_u32(mesh_data_offset+4+4)
		mesh.indices[3*i + 2] = mesh_data.decode_u32(mesh_data_offset+4)
		mesh_data_offset += 4 + 4 + 4
	
	for i in range(texture_RGBA_count * 4):
		mesh.texture_RGBA[i] = mesh_data.decode_u8(mesh_data_offset)
		mesh_data_offset += 1
	
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for vertex in mesh.vertices:
		st.set_normal(vertex.normal)
		st.set_uv(vertex.tex_coord)
		st.add_vertex(vertex.position)
	
	for index in mesh.indices:
		st.add_index(index)
	
	if not mesh.texture_RGBA.is_empty():
		var texture_resolution := int(sqrt(texture_RGBA_count))
		var texture_image := Image.create_from_data(
			texture_resolution,
			texture_resolution,
			false,
			Image.FORMAT_RGBA8,
			mesh.texture_RGBA
		)
		texture_image.generate_mipmaps()
		var texture := ImageTexture.new()
		texture.set_image(texture_image)
		var material := StandardMaterial3D.new()
		material.albedo_texture = texture
		st.set_material(material)
	
	return st.commit()
