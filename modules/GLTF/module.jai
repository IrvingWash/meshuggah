#import "Basic";
#import "File";
#import "jaison";

#module_parameters(VALIDATE: bool = false);

Model :: struct {
    meshes: [..]Mesh_Data;
}

Mesh_Data :: struct {
    vertices: [..]Vertex;
    indices:  [..]u32;
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
            mesh := gltf.meshes[node.mesh]; // Maybe parse_mesh();
        }
    }

    // @Incomplete

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
