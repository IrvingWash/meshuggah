#import "jaison";

GLTF :: struct {
    scene: u32;
    scenes: [..]GLTF_Scene;
    nodes: [..]GLTF_Node;
    meshes: [..]GLTF_Mesh;
    accessors: [..]GLTF_Accessor;
    buffer_views: [..]GLTF_Buffer_View; @JsonName(bufferViews)
    buffers: [..]GLTF_Buffer;
};

GLTF_Scene :: struct {
    name: string;
    nodes: []u32;
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
    max: [..]s32;
    min: [..]s32;
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
