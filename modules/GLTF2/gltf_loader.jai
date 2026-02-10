#scope_module

// @Todo: enums instead of strings
// @Todo Node

GLTF :: struct {
    accessors:    [..]GLTF_Accessor;
    buffers:      [..]GLTF_Buffer;
    buffer_views: [..]GLTF_Buffer_View; @JsonName(bufferViews)
    images:       [..]GLTF_Image;
    materials:    [..]GLTF_Material;
    meshes:       [..]GLTF_Mesh;
}

GLTF_Accessor :: struct {
    _buffer_view:    s32                  = -1;       @JsonName(bufferView)
     byte_offset:    s32;                             @JsonName(byteOffset)
     component_type: GLTF_Component_Type;             @JsonName(componentType)
     normalized:     bool;
     count:          s32;
     type:           string;
    _max:            [..]float;                       @JsonName(max)
    _min:            [..]float;                       @JsonName(min)
}

GLTF_Buffer :: struct {
    _uri:         string; @JsonName(uri)
     byte_length: s32;    @JsonName(byteLength)
}

GLTF_Buffer_View :: struct {
     buffer:      s32;
     byte_offset: s32;                                @JsonName(byteOffset)
     byte_length: s32;                                @JsonName(byteLength)
    _byte_stride: s32                     = -1;       @JsonName(byteStride)
    _target:      GLTF_Buffer_View_Target = .NONE;    @JsonName(target)
}

GLTF_Image :: struct {
    _name:        string;       @JsonName(name)
    _uri:         string;       @JsonName(uri)
    _buffer_view: s32     = -1; @JsonName(bufferView)
}

GLTF_Material :: struct {
    _name:                   string;                                                    @JsonName(name)
     pbr_metallic_roughness: PBR_Metallic_Roughness;                                    @JsonName(pbrMetallicRoughness)
     normal_texture:         Normal_Texture_Info;                                       @JsonName(normalTexture)
     occlusion_texture:      Occlusion_Texture_Info;                                    @JsonName(occlusionTexture)
     emissive_texture:       Texture_Info;                                              @JsonName(emissiveTexture)
     emissive_factor:        [3]float;                                                  @JsonName(emissiveFactor)
     alpha_mode:             string                  = GLTF_Material_Alpha_Mode.OPAQUE; @JsonName(alphaMode)
     alpha_cutoff:           float                   = 0.5;                             @JsonName(alphaCutoff)
     double_sided:           bool;                                                      @JsonName(doubleSided)

    Normal_Texture_Info :: struct {
        using texture_info: Texture_Info;
        scale:     float = 1;
    }

    Occlusion_Texture_Info :: struct {
        using texture_info: Texture_Info;
        strength:  float = 1;
    }

    PBR_Metallic_Roughness :: struct {
        base_color_factor:          [4]float           = float.[1, 1, 1, 1]; @JsonName(baseColorFactor)
        base_color_texture:         Texture_Info;                       @JsonName(baseColorTexture)
        metallic_factor:            float              = 1;                  @JsonName(metallicFactor)
        roughness_factor:           float              = 1;                  @JsonName(roughnessFactor)
        metallic_roughness_texture: Texture_Info;                       @JsonName(metallicRoughnessTexture)
    };

    Texture_Info :: struct {
        _index:     s32 = -1; @JsonName(index)
        tex_coord: s32;      @JsonName(texCoord)
    }
}

GLTF_Mesh :: struct {
     primitives: [..]Primitive;
    _name:       string;        @JsonName(name)

    Primitive :: struct {
         attributes: Attributes;
        _indices:    s32         = -1; @JsonName(indices)
        _material:   s32         = -1; @JsonName(material)
         mode:       Mode        = .TRIANGLES;

        Attributes :: struct {
            _position:    s32 = -1; @JsonName(POSITION)
            _normal:      s32 = -1; @JsonName(NORMAL)
            _tex_coord_0: s32 = -1; @JsonName(TEXCOORD_0)
        }

        Mode :: enum s32 #specified {
            POINTS         :: 0;
            LINES          :: 1;
            LINE_LOOP      :: 2;
            LINE_STRIP     :: 3;
            TRIANGLES      :: 4;
            TRIANGLE_STRIP :: 5;
            TRIANGLE_FAN   :: 6;
        }
    }
}

GLTF_Buffer_View_Target :: enum s32 #specified {
    NONE                 :: 0;
    ARRAY_BUFFER         :: 34962;
    ELEMENT_ARRAY_BUFFER :: 34963;
}

GLTF_Component_Type :: enum s32 #specified {
    INVALID :: 0;
    I8      :: 5120;
    U8      :: 5121;
    I16     :: 5122;
    U16     :: 5123;
    U32     :: 5125;
    FLOAT32 :: 5126;
}

GLTF_Material_Alpha_Mode :: struct {
    OPAQUE :: "OPAQUE";
    MASK   :: "MASK";
    BLEND  :: "BLEND";
}

GLTF_Accessor_Type :: struct {
    SCALAR :: "SCALAR";
    VEC2   :: "VEC2";
    VEC3   :: "VEC3";
    VEC4   :: "VEC4";
    MAT2   :: "MAT2";
    MAT3   :: "MAT3";
    MAT4   :: "MAT4";
}

load_gltf :: (path: string) -> ok: bool, error: string, GLTF {
    gltf: GLTF;

    absolute_path, ok := get_absolute_path(path);
    if !ok {
        return false, sprint("Failed to get absolute path of '%'|", path), gltf;
    }

    content:, ok = read_entire_file(absolute_path);
    if !ok {
        return false, sprint("Failed to read file at '%'", absolute_path), gltf;
    }

    ok =, gltf := json_parse_string(content, GLTF);
    if !ok {
        return false, sprint("Failed to parse GLTF file at '%'", absolute_path), gltf;
    }

    return true, "", gltf;
}

release_gltf :: (gltf: GLTF) {
    for accessor: gltf.accessors {
        free(accessor.type);
        array_free(accessor._min);
        array_free(accessor._max);
    }
    array_free(gltf.accessors);

    for buffer: gltf.buffers {
        free(buffer._uri);
    }
    array_free(gltf.buffers);

    array_free(gltf.buffer_views);

    for image: gltf.images {
        free(image._name);
        free(image._uri);
    }
    array_free(gltf.images);

    for material: gltf.materials {
        free(material._name);
        free(material.alpha_mode);
    }
    array_free(gltf.materials);

    for mesh: gltf.meshes {
        free(mesh._name);
        array_free(mesh.primitives);
    }
    array_free(gltf.meshes);
}

#import "Basic";
#import "File";
#import "jaison";
