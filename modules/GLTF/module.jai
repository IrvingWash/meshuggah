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
                    parse_primitive(gltf, primitive, buffers, root_directory),
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

parse_primitive :: (
    gltf: GLTF,
    primitive: GLTF_Primitive,
    buffers: [][]u8,
    root_directory: string,
) -> Mesh_Data {
    mesh_data: Mesh_Data;

    {
        positions := parse_attribute(
            gltf,
            buffers,
            gltf.accessors[primitive.attributes.POSITION],
            Vector3,
        );
        defer array_free(positions);

        array_resize(*mesh_data.vertices, positions.count);
        for position: positions {
            mesh_data.vertices[it_index].position = position;
        }
    }

    if primitive.attributes.NORMAL != -1 {
        normals := parse_attribute(
            gltf,
            buffers,
            gltf.accessors[primitive.attributes.NORMAL],
            Vector3,
        );
        defer array_free(normals);

        for normal: normals {
            mesh_data.vertices[it_index].normal = normal;
        }
    } 

    if primitive.attributes.TEXCOORD_0 != -1 {
        uvs := parse_attribute(
            gltf,
            buffers,
            gltf.accessors[primitive.attributes.TEXCOORD_0],
            Vector2,
        );
        defer array_free(uvs);

        for uv: uvs {
            mesh_data.vertices[it_index].uv = uv;
        }
    }

    if primitive.indices != -1 {
        mesh_data.indices = parse_attribute(
            gltf,
            buffers,
            gltf.accessors[primitive.indices],
            u16,
        ); // @Todo: hardcoded indices to u16, this will need to be resolved sooner or later
    }

    if primitive.material != -1 {
        mesh_data.material = parse_material(
            gltf,
            primitive,
            root_directory,
        );
    }

    return mesh_data;
}

parse_material :: (gltf: GLTF, primitive: GLTF_Primitive, root_directory: string) -> Material {
    result: Material;

    gltf_material := gltf.materials[primitive.material];

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
            assert(false, "Unexpected accessor component type %", accessor.component_type);
    }

    return 0;
}

// The returned array of buffers is indexed in respect of the incoming gltf_buffers
load_buffers :: (root_directory: string, gltf_buffers: []GLTF_Buffer) -> ok: bool, error_message: string, buffers: [..][]u8 {
    loaded_buffers: [..][]u8;
    array_resize(*loaded_buffers, gltf_buffers.count);

    for gltf_buffer: gltf_buffers {
        buffer_path := path_join(
            root_directory,
            gltf_buffer.uri,,
            temp
        );
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
