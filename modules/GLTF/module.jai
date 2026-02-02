#import "Basic";
#import "File";
#import "jaison";

#module_parameters(VALIDATE: bool = false);

Model :: struct {
    meshes: [..]Mesh_Data; // GLTF primitives
}

Mesh_Data :: struct {
    vertices: [..]Vertex;
    indices:  [..]u32;
    material: Material;
}

Vertex :: struct {
    position: Vector3;
    normal:   Vector3 = { 0, 0, 1 };
    uv:       Vector2;
}

Material :: struct {
    double_sided: bool;

    base_color: Vector4 = { 1, 1, 1, 1 };

    base_color_texture_path: string;

    mag_filter: Texture_Filter;
    min_filter: Texture_Filter;
}

Texture_Filter :: enum {
    NEAREST;
    LINEAR;
    NEAREST_MIPMAP_NEAREST;
    LINEAR_MIPMAP_NEAREST;
    NEAREST_MIPMAP_LINEAR;
    LINEAR_MIPMAP_LINEAR;
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

    // Load buffers which contain the actual vertex data
    ok =, error_message =, gltf_buffers := load_gltf_buffers(root_directory, gltf.buffers);
    if !ok {
        return false, error_message, {};
    }
    defer release_gltf_buffers(gltf_buffers);

    // Parse all the nodes of the scene and put them into `model`
    gltf_scene := gltf.scenes[gltf.scene];
    for gltf_node_index: gltf_scene.nodes {
        parse_gltf_node(
            gltf,
            gltf_node_index,
            *model,
            gltf_buffers,
            root_directory,
        );
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

parse_gltf_node :: (
    gltf: GLTF,
    gltf_node_index: int,
    model: *Model,
    gltf_buffers: [][]u8,
    root_directory: string,
) {
    gltf_node := gltf.nodes[gltf_node_index];

    if gltf_node.mesh != -1 {
        gltf_mesh := gltf.meshes[gltf_node.mesh];

        for gltf_primitive: gltf_mesh.primitives {
            array_add(
                *model.meshes,
                parse_gltf_primitive(gltf, gltf_primitive, gltf_buffers, root_directory),
            );
        }
    }

    for gltf_child: gltf_node.children {
        parse_gltf_node(gltf, gltf_child, model, gltf_buffers, root_directory);
    }
}

parse_gltf_primitive :: (
    gltf: GLTF,
    gltf_primitive: GLTF_Primitive,
    gltf_buffers: [][]u8,
    root_directory: string,
) -> Mesh_Data {
    mesh_data: Mesh_Data;

    {
        positions := parse_gltf_attribute(
            gltf,
            gltf_buffers,
            gltf.accessors[gltf_primitive.attributes.POSITION],
            Vector3,
        );
        defer array_free(positions);

        array_resize(*mesh_data.vertices, positions.count);
        for position: positions {
            mesh_data.vertices[it_index].position = position;
        }
    }

    if gltf_primitive.attributes.NORMAL != -1 {
        normals := parse_gltf_attribute(
            gltf,
            gltf_buffers,
            gltf.accessors[gltf_primitive.attributes.NORMAL],
            Vector3,
        );
        defer array_free(normals);

        for normal: normals {
            mesh_data.vertices[it_index].normal = normal;
        }
    } 

    if gltf_primitive.attributes.TEXCOORD_0 != -1 {
        uvs := parse_gltf_attribute(
            gltf,
            gltf_buffers,
            gltf.accessors[gltf_primitive.attributes.TEXCOORD_0],
            Vector2,
        );
        defer array_free(uvs);

        for uv: uvs {
            mesh_data.vertices[it_index].uv = uv;
        }
    }

    if gltf_primitive.indices != -1 {
        mesh_data.indices = parse_gltf_indices_attribute(
            gltf,
            gltf_buffers,
            gltf.accessors[gltf_primitive.indices],
            u32,
        );
    }

    if gltf_primitive.material != -1 {
        mesh_data.material = parse_gltf_material(
            gltf,
            gltf_primitive,
            root_directory,
        );
    }

    return mesh_data;
}

parse_gltf_material :: (gltf: GLTF, gltf_primitive: GLTF_Primitive, root_directory: string) -> Material {
    result: Material;

    gltf_material := gltf.materials[gltf_primitive.material];

    result.double_sided = gltf_material.double_sided;
    result.base_color.component = gltf_material
        .pbr_metallic_roughness
        .base_color_factor;

    if gltf_material.pbr_metallic_roughness.base_color_texture.index != -1 {
        gltf_texture := gltf.textures[
            gltf_material
            .pbr_metallic_roughness
            .base_color_texture.index
        ];
        gltf_sampler := gltf.samplers[gltf_texture.sampler];

        result.base_color_texture_path = path_join(
            root_directory,
            gltf.images[gltf_texture.source].uri,
            separator = "/",,
            temp
        );

        if gltf_sampler.mag_filter == {
            case GLTF_Texture_Filter.NEAREST;
                result.mag_filter = .NEAREST;
            case GLTF_Texture_Filter.LINEAR;
                result.mag_filter = .LINEAR;
        }

        if gltf_sampler.min_filter == {
            case GLTF_Texture_Filter.NEAREST;
                result.min_filter = .NEAREST;
            case GLTF_Texture_Filter.LINEAR;
                result.min_filter = .LINEAR;
            case GLTF_Texture_Filter.NEAREST_MIPMAP_NEAREST;
                result.min_filter = .NEAREST_MIPMAP_NEAREST;
            case GLTF_Texture_Filter.LINEAR_MIPMAP_NEAREST;
                result.min_filter = .LINEAR_MIPMAP_NEAREST;
            case GLTF_Texture_Filter.NEAREST_MIPMAP_LINEAR;
                result.min_filter = .NEAREST_MIPMAP_LINEAR;
            case GLTF_Texture_Filter.LINEAR_MIPMAP_LINEAR;
                result.min_filter = .LINEAR_MIPMAP_LINEAR;
        }
    }

    return result;
}

parse_gltf_attribute :: (
    gltf: GLTF,
    gltf_buffers: [][]u8,
    gltf_accessor: GLTF_Accessor,
    $T: Type,
) -> [..]T
#modify {
    return (T == Vector2 || T == Vector3 || IsScalar(T));
}
{
    gltf_buffer_view := gltf.buffer_views[gltf_accessor.buffer_view];
    gltf_buffer := gltf_buffers[gltf_buffer_view.buffer];

    start_offset := gltf_buffer_view.byte_offset + gltf_accessor.byte_offset;
    element_count := gltf_accessor.count;

    component_count := get_accessor_component_count(gltf_accessor);
    component_byte_size := get_accessor_component_byte_size(gltf_accessor);

    element_size := component_count * component_byte_size;

    step := ifx gltf_buffer_view.byte_stride != 0
        then gltf_buffer_view.byte_stride
        else element_size;

    // Reinterpreting bytes from the buffer to the passed type. Scary
    result: [..]T;
    array_reserve(*result, element_count);
    for 0..(element_count - 1) {
        byte_index := start_offset + it * step;

        value := cast(*T, *gltf_buffer[byte_index]);

        array_add(*result, value.*);
    }

    return result;
}

parse_gltf_indices_attribute :: (
    gltf: GLTF,
    gltf_buffers: [][]u8,
    gltf_accessor: GLTF_Accessor,
    $T: Type,
) -> [..]T
#modify {
    return T == u32 || T == u16;
}
{
    assert(gltf_accessor.type == GLTF_Accessor_Type.SCALAR, "Expected indices to be scalars, but got %", gltf_accessor.type);

    // @Copy_N_Paste from parse_attribute
    gltf_buffer_view := gltf.buffer_views[gltf_accessor.buffer_view];
    gltf_buffer := gltf_buffers[gltf_buffer_view.buffer];

    start_offset := gltf_buffer_view.byte_offset + gltf_accessor.byte_offset;
    element_count := gltf_accessor.count;

    component_count := get_accessor_component_count(gltf_accessor);
    component_byte_size := get_accessor_component_byte_size(gltf_accessor);

    element_size := component_count * component_byte_size;

    step := ifx gltf_buffer_view.byte_stride != 0
        then gltf_buffer_view.byte_stride
        else element_size;

    // We need to know the internal type of a single index.
    // We will cast the bytes to this type
    // and then cast it again to the desired type T.
    // This way we can ask for u32 while the actual data is u16
    internal_type: Type;
    if gltf_accessor.component_type == {
        case GLTF_Component_Type.U16;
            internal_type = u16;
        case GLTF_Component_Type.U32;
            internal_type = u32;
        case;
            assert(false, "Expected indices to be either u16 or u32, but got %", gltf_accessor.component_type);
    }

    result: [..]T;
    array_reserve(*result, element_count);
    for 0..(element_count - 1) {
        byte_index := start_offset + it * step;

        if internal_type == {
            case u16;
                value := cast(*u16, *gltf_buffer[byte_index]);
                array_add(*result, cast(T, value.*));
            case u32;
                value := cast(*u32, *gltf_buffer[byte_index]);
                array_add(*result, cast(T, value.*));
        }
    }

    return result;
}

get_accessor_component_count :: (gltf_accessor: GLTF_Accessor) -> u8 {
    if gltf_accessor.type == {
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
            assert(false, "Unexpected accessor type %", gltf_accessor.type);
    }

    return 0;
}

get_accessor_component_byte_size :: (gltf_accessor: GLTF_Accessor) -> u8 {
    if gltf_accessor.component_type == {
        case GLTF_Component_Type.I8; #through;
        case GLTF_Component_Type.U8;
            return 1;
        case GLTF_Component_Type.I16; #through;
        case GLTF_Component_Type.U16;
            return 2;
        case GLTF_Component_Type.U32; #through;
        case GLTF_Component_Type.F32;
            return 4;
        case;
            assert(false, "Unexpected accessor component type %", gltf_accessor.component_type);
    }

    return 0;
}

// The returned array of buffers is indexed in respect of the incoming gltf_buffers (each buffer has the same index, English is hard)
load_gltf_buffers :: (
    root_directory: string,
    gltf_buffers: []GLTF_Buffer
) -> ok: bool, error_message: string, gltf_buffers: [..][]u8 {
    loaded_gltf_buffers: [..][]u8;
    array_resize(*loaded_gltf_buffers, gltf_buffers.count);

    for gltf_buffer: gltf_buffers {
        buffer_path := path_join(
            root_directory,
            gltf_buffer.uri,,
            temp
        );
        data, ok := read_entire_file(buffer_path);
        if !ok {
            release_gltf_buffers(loaded_gltf_buffers);
            return false,
                sprint("Failed to load buffer from %", buffer_path),
                loaded_gltf_buffers;
        }

        bytes: []u8 = cast([]u8, data);
        if bytes.count < gltf_buffer.byte_length {
            release_gltf_buffers(loaded_gltf_buffers);
            return false,
                sprint(
                    "Buffer file contains less bytes (%) than it's specified in metadata (%)",
                    bytes.count, gltf_buffer.byte_length
                ),
                loaded_gltf_buffers;
        }

        loaded_gltf_buffers[it_index] = bytes;
    }

    return true, "", loaded_gltf_buffers;
}

release_gltf_buffers :: (buffers: [..][]u8) {
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
