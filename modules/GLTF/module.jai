#import "Basic";
#import "File";
#import "jaison";

#module_parameters(VALIDATE: bool = false);

Model :: struct {
    meshes: [..]Mesh_Data;
}

Mesh_Data :: struct {
    vertices: [..]Vertex;
    indices:  [..]u16;
}

Vertex :: struct {
    position: Vector3;
    normal:   Vector3 = { 0, 0, 1 };
    uv:       Vector2;
}

load :: (path: string) -> ok: bool, error_message: string, Model {
    model: Model;

    ok, error_message, gltf := parse_gltf_file(path);
    if !ok {
        return false, error_message, {};
    }
    defer release_gltf_file(*gltf);

    if gltf.scenes.count != 1 {
        return false, sprint("Multi-scene gltf files are not supported, % has % scenes", path, gltf.scenes.count), {};
    }

    root_directory := path_strip_filename(path);

    ok =, error_message =, buffers := load_buffers(root_directory, gltf.buffers);
    if !ok {
        return false, error_message, {};
    }
    defer release_buffers(buffers);

    scene := gltf.scenes[gltf.scene];

    for node_index: scene.nodes {
        node := gltf.nodes[node_index];

        if node.mesh != -1 {
            mesh := gltf.meshes[node.mesh];

            for primitive: mesh.primitives {
                array_add(
                    *model.meshes,
                    parse_primitive(gltf, primitive, buffers),
                );
            }
        }
    }

    return true, "", model;
}

release :: (model: *Model) {
    for mesh: model.meshes {
        array_free(mesh.vertices);
        array_free(mesh.indices);
    }

    array_free(model.meshes);

    model.* = {};
}



#scope_file

GLTF_Accessor_Type :: struct {
    SCALAR :: "SCALAR";
    VEC2   :: "VEC2";
    VEC3   :: "VEC3";
    VEC4   :: "VEC4";
    MAT4   :: "MAT4";
}

parse_primitive :: (gltf: GLTF, primitive: GLTF_Primitive, buffers: [][]u8) -> Mesh_Data {
    mesh_data: Mesh_Data;

    {
        positions := parse_attribute(gltf, buffers, gltf.accessors[primitive.attributes.POSITION], Vector3);
        array_resize(*mesh_data.vertices, positions.count);
        for position: positions {
            mesh_data.vertices[it_index].position = position;
        }
        array_free(positions);
    }

    if primitive.attributes.NORMAL != -1 {
        normals := parse_attribute(gltf, buffers, gltf.accessors[primitive.attributes.NORMAL], Vector3);
        for normal: normals {
            mesh_data.vertices[it_index].normal = normal;
        }
        array_free(normals);
    } 

    if primitive.attributes.TEXCOORD_0 != -1 {
        uvs := parse_attribute(gltf, buffers, gltf.accessors[primitive.attributes.TEXCOORD_0], Vector2);
        for uv: uvs {
            mesh_data.vertices[it_index].uv = uv;
        }
        array_free(uvs);
    }

    if primitive.indices != -1 {
        mesh_data.indices = parse_attribute(gltf, buffers, gltf.accessors[primitive.indices], u16);
    }

    return mesh_data;
}

parse_attribute :: (
    gltf: GLTF,
    buffers: [][]u8,
    accessor: GLTF_Accessor,
    $T: Type,
) -> [..]T
#modify {
    return (T == Vector2 || T == Vector3 || IsScalar(T));
}
{
    buffer_view := gltf.buffer_views[accessor.buffer_view];
    buffer := buffers[buffer_view.buffer];

    start_offset := buffer_view.byte_offset + accessor.byte_offset;
    element_count := accessor.count;

    component_count := get_accessor_component_count(accessor);
    component_byte_size := get_accessor_component_byte_size(accessor);

    element_size := component_count * component_byte_size;

    step := ifx buffer_view.byte_stride != 0
    then buffer_view.byte_stride
    else element_size;

    result: [..]T;
    for 0..(element_count - 1) {
        byte_index := start_offset + it * step;

        value := cast(type_of(result.data), *buffer[byte_index]);

        array_add(*result, value.*);
    }

    return result;
}

get_accessor_component_count :: (accessor: GLTF_Accessor) -> u8 {
    if accessor.type == {
        case GLTF_Accessor_Type.SCALAR;
            return 1;
        case GLTF_Accessor_Type.VEC2;
            return 2;
        case GLTF_Accessor_Type.VEC3;
            return 3;
        case GLTF_Accessor_Type.VEC4;
            return 4;
        case GLTF_Accessor_Type.MAT4;
            return 16;
        case;
            assert(false, "Unexpected accessor type %", accessor.type);
    }

    return 0;
}

get_accessor_component_byte_size :: (accessor: GLTF_Accessor) -> u8 {
    if accessor.component_type == {
        case 5120; #through;
        case 5121;
            return 1;
        case 5122; #through;
        case 5123;
            return 2;
        case 5125; #through;
        case 5126;
            return 4;
        case;
            assert(false, "Unexpected accessor component type %", accessor.component_type);
    }

    return 0;
}

// The returned array of buffers is indexed in respect of the incoming gltf_buffers
load_buffers :: (root_directory: string, gltf_buffers: []GLTF_Buffer) -> ok: bool, error_message: string, buffers: [..][]u8 {
    loaded_buffers: [..][]u8;
    array_resize(*loaded_buffers, gltf_buffers.count);

    for gltf_buffer: gltf_buffers {
        buffer_path := path_join(root_directory, gltf_buffer.uri,, temp);
        data, ok := read_entire_file(buffer_path);
        if !ok {
            release_buffers(loaded_buffers);
            return false, sprint("Failed to load buffer from %", buffer_path), loaded_buffers;
        }

        bytes: []u8 = cast([]u8, data);
        if bytes.count < gltf_buffer.byte_length {
            release_buffers(loaded_buffers);
            return false, sprint("Buffer file contains less bytes (%) than it's specified in metadata (%)", bytes.count, gltf_buffer.byte_length), loaded_buffers;
        }

        loaded_buffers[it_index] = bytes;
    }

    return true, "", loaded_buffers;
}

release_buffers :: (buffers: [..][]u8) {
    for buffer: buffers {
        array_free(buffer);
    }

    array_free(buffers);
}

#import "Basic";
#import "Math";
#import "String";
#import "Hash_Table";

#load "gltf_parser.jai";
