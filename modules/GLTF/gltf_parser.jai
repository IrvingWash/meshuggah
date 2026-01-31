#scope_module

GLTF :: struct {
    asset: GLTF_Asset;
    scene: u32;
    scenes: [..]GLTF_Scene;
    nodes: [..]GLTF_Node;
    meshes: [..]GLTF_Mesh;
    accessors: [..]GLTF_Accessor;
    buffer_views: [..]GLTF_Buffer_View; @JsonName(bufferViews)
    buffers: [..]GLTF_Buffer;
};

GLTF_Asset :: struct {
    generator: string;
    version: string;
}

GLTF_Scene :: struct {
    name: string;
    nodes: [..]u32;
}

GLTF_Node :: struct {
    mesh: u32;
    name: string;
}

GLTF_Mesh :: struct {
    name: string;
    primitives: [..]GLTF_Primitive;
}

GLTF_Primitive :: struct {
    attributes: GLTF_Attributes;
    indices: u32;
}

GLTF_Attributes :: struct {
    POSITION: u32;
    NORMAL: u32;
    TEXCOORD_0: u32;
}

GLTF_Accessor :: struct {
    buffer_view: u32; @JsonName(bufferView)
    component_type: u32; @JsonName(componentType)
    count: u32;
    max: [..]float;
    min: [..]float;
    type: string;
}

GLTF_Buffer_View :: struct {
    buffer: u32;
    byte_length: u32; @JsonName(byteLength)
    byte_offset: u32; @JsonName(byteOffset)
    target: u32;
}

GLTF_Buffer :: struct {
    byte_length: u32; @JsonName(byteLength)
    uri: string;
}

parse_gltf_file :: (path: string) -> ok: bool, error_message: string, GLTF {
    gltf: GLTF;

    data, ok := read_entire_file(path,, temp);
    if !ok {
        return false, sprint("Failed to read GLTF file from %", path), gltf;
    }

    ok, gltf = json_parse_string(data, GLTF);
    if !ok {
        return false, sprint("Failed to parse GLTF file from %", path), gltf;
    }

    if gltf.asset.version != SUPPORTED_GLTF_VERSION {
        error_message := sprint(
            "Only GLTF version % is supported, but tried to laod version %",
            SUPPORTED_GLTF_VERSION,
            gltf.asset.version,
        );

        return false, error_message, gltf;
    }

    return true, "", gltf;
}

release_gltf_file :: (gltf: *GLTF) {
    free(gltf.asset.generator);
    free(gltf.asset.version);

    for scene: gltf.scenes {
        free(scene.name);
        array_free(scene.nodes);
    }
    array_free(gltf.scenes);

    for node: gltf.nodes {
        free(node.name);
    }
    array_free(gltf.nodes);

    for mesh: gltf.meshes {
        free(mesh.name);

        array_free(mesh.primitives);
    }
    array_free(gltf.meshes);

    for accessor: gltf.accessors {
        array_free(accessor.max);
        array_free(accessor.min);
        free(accessor.type);
    }
    array_free(gltf.accessors);

    array_free(gltf.buffer_views);

    for buffer: gltf.buffers {
        free(buffer.uri);
    }
    array_free(gltf.buffers);

    gltf.* = {};
}



#scope_file

SUPPORTED_GLTF_VERSION :: "2.0";

#import "File";
