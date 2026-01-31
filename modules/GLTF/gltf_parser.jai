#scope_module

GLTF :: struct {
    asset: GLTF_Asset;

    scene:        int = -1;
    scenes:       [..]GLTF_Scene;
    nodes:        [..]GLTF_Node;
    meshes:       [..]GLTF_Mesh;
    accessors:    [..]GLTF_Accessor;
    buffer_views: [..]GLTF_Buffer_View; @JsonName(bufferViews)
    buffers:      [..]GLTF_Buffer;
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
    name: string;

    mesh:   int = -1;
    camera: int = -1;
}

GLTF_Mesh :: struct {
    name: string;
    primitives: [..]GLTF_Primitive;
}

GLTF_Primitive :: struct {
    attributes: GLTF_Attributes;
    indices: int = -1;
}

GLTF_Attributes :: struct {
    POSITION:   int = -1;
    NORMAL:     int = -1;
    TEXCOORD_0: int = -1;
}

GLTF_Accessor :: struct {
    buffer_view: int = -1; @JsonName(bufferView)
    byte_offset: u32; @JsonName(byteOffset)
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
    byte_stride: u32; @JsonName(byteStride)
    target: int = -1;
}

GLTF_Buffer :: struct {
    byte_length: u32; @JsonName(byteLength)
    uri: string;
}

parse_gltf_file :: (path: string) -> ok: bool, error_message: string, GLTF {
    gltf: GLTF;

    data, ok := read_entire_file(path,, temp);
    if !ok {
        return false, sprint("Failed to read GLTF file from %", path), {};
    }

    ok, gltf = json_parse_string(data, GLTF);
    if !ok {
        return false, sprint("Failed to parse GLTF file from %", path), {};
    }

    if gltf.asset.version != SUPPORTED_GLTF_VERSION {
        error_message := sprint(
            "Only GLTF version % is supported, but tried to laod version %",
            SUPPORTED_GLTF_VERSION,
            gltf.asset.version,
        );

        return false, error_message, {};
    }

    ok =, errors: = validate(gltf);
    if !ok {
        return false, sprint("Invalid gltf file at %: %", path, join(..errors, separator = ", ")), {};
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

validate :: (gltf: GLTF) -> ok: bool, errors: []string {
    errors: [..]string;

    if gltf.scene == -1 {
        array_add(
            *errors,
            "No scene",
        );
    }

    for buffer_view: gltf.buffer_views {
        if buffer_view.buffer < gltf.buffers.count {
            continue;
        };

        array_add(
            *errors,
            "Buffer views without a buffer",
        );
        break;
    }

    for buffer_view: gltf.buffer_views {
        if buffer_view.byte_length > 0 {
            continue;
        }

        array_add(
            *errors,
            "Buffer view with incorrect byte length",
        );
        break;
    }

    for accessor: gltf.accessors {
        if accessor.type != "" {
            continue;
        }

        array_add(
            *errors,
            "Accessor doesn't have a type",
        );
        break;
    }

    for accessor: gltf.accessors {
        if accessor.count > 0 {
            continue;
        }

        array_add(
            *errors,
            "Accessor with incorrect count",
        );
        break;
    }

    for mesh: gltf.meshes {
        for primitive: mesh.primitives {
            if primitive.attributes.POSITION != -1 {
                continue;
            }

            array_add_if_unique(*errors, sprint("Primitive doesn't have position for mesh with name %", mesh.name));
        }
    }

    return errors.count == 0, errors;
}

SUPPORTED_GLTF_VERSION :: "2.0";

#import "File";
