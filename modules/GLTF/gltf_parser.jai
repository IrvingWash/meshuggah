#scope_module

GLTF :: struct {
    asset: GLTF_Asset;

    scene:        int = -1;
    scenes:       [..]GLTF_Scene;
    nodes:        [..]GLTF_Node;
    materials:    [..]GLTF_Material;
    meshes:       [..]GLTF_Mesh;
    textures:     [..]GLTF_Texture;
    images:       [..]GLTF_Image;
    accessors:    [..]GLTF_Accessor;
    buffer_views: [..]GLTF_Buffer_View; @JsonName(bufferViews)
    buffers:      [..]GLTF_Buffer;
    samplers:     [..]GLTF_Sampler;
};

GLTF_Texture :: struct {
    sampler: int = -1;
    source:  int = -1;
}

GLTF_Image :: struct {
    name:     string;
    mimeType: string;
    uri:      string;
}

GLTF_Sampler :: struct {
    mag_filter: int = -1; @JsonName(magFilter)
    min_filter: int = -1; @JsonName(minFilter)
}

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
    children: [..]u32;
    matrix: [16]float = #run Matrix4_Identity.floats; // @Todo: unused for now. We don't have a concpet of nodes in the engine. GLTF most probably has column-major matrices, but we want row major here, as Jai's Math library stores matrices in row-major format.
}

GLTF_Material :: struct {
    name: string;
    double_sided: bool; @JsonName(doubleSided)
    pbr_metallic_roughness: GLTF_PBR_Metallic_Roughness; @JsonName(pbrMetallicRoughness)
}

GLTF_PBR_Metallic_Roughness :: struct {
    base_color_factor: [4]float = float.[1, 1, 1, 1]; @JsonName(baseColorFactor);
    base_color_texture: GLTF_Base_Color_Texture; @JsonName(baseColorTexture)

    metallic_factor:  float; @JsonName(metallicFactor)
    roughness_factor: float; @JsonName(roughnessFactor)
}

GLTF_Base_Color_Texture :: struct {
    index: int = -1;
}

GLTF_Mesh :: struct {
    name: string;
    primitives: [..]GLTF_Primitive;
}

GLTF_Primitive :: struct {
    attributes: GLTF_Attributes;
    indices: int = -1;
    material: int = -1;
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

GLTF_Texture_Filter :: struct {
    NEAREST:                int : 9728;
    LINEAR:                 int : 9729;
    NEAREST_MIPMAP_NEAREST: int : 9984;
    LINEAR_MIPMAP_NEAREST:  int : 9985;
    NEAREST_MIPMAP_LINEAR:  int : 9986;
    LINEAR_MIPMAP_LINEAR:   int : 9987;
}

GLTF_Accessor_Type :: struct {
    SCALAR :: "SCALAR";
    VEC2   :: "VEC2";
    VEC3   :: "VEC3";
    VEC4   :: "VEC4";
    MAT4   :: "MAT4";
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

    #if VALIDATE {
        ok =, errors: = validate(gltf);
        if !ok {
            return false, sprint("Invalid gltf file at %: %", path, errors), {};
        }
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
        array_free(node.children);
    }
    array_free(gltf.nodes);

    for material: gltf.materials {
        free(material.name);
    }
    array_free(gltf.materials);

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

    array_free(gltf.textures);
    array_free(gltf.samplers);

    for image: gltf.images {
        free(image.uri);
        free(image.name);
        free(image.mimeType);
    }
    array_free(gltf.images);

    gltf.* = {};
}

GLTF_Component_Type :: struct {
    I8  :: 5120;
    U8  :: 5121;
    I16 :: 5122;
    U16 :: 5123;
    U32 :: 5125;
    F32 :: 5126;
}



#scope_file

SUPPORTED_GLTF_VERSION :: "2.0";

validate :: (gltf: GLTF) -> ok: bool, errors: []string {
    errors: [..]string;

    // @Incomplete

    return errors.count == 0, errors;
}

#import "File";
