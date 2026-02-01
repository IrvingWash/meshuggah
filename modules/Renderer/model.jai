Model :: struct {
    meshes: [..]Mesh;
}

Mesh :: struct {
    vao: u32;
    vbo: u32;
    ebo: u32;

    index_count: u32;

    material: Material;
}

Material :: struct {
    tint: Vector4;

    double_sided: bool;

    texture: Texture;
}

Vertex :: struct {
    position: Vector3;
    normal:   Vector3;
    uv:       Vector2;
}

Vertex_Attribute_Offsets  :: struct {
    POSITION :: #run offset_of(Vertex, "position");
    NORMAL   :: #run offset_of(Vertex, "normal");
    UV       :: #run offset_of(Vertex, "uv");
}

Model_Data :: struct {
    meshes: [..]Mesh_Data;
}

Mesh_Data :: struct {
    vertices: []Vertex;
    indices:  []u16;
    material: Material;
}

create_model :: (model_data: Model_Data) -> Model {
    model: Model;

    for mesh_data: model_data.meshes {
        array_add(
            *model.meshes,
            create_mesh(mesh_data),
        );
    }

    return model;
}

destroy_model :: (model: *Model) {
    for *mesh: model.meshes {
        destroy_mesh(mesh);
    }
    array_free(model.meshes);

    model.* = {};
}

destroy_model_data :: (model_data: *Model_Data) {
    array_free(model_data.meshes);

    model_data.* = {};
}



#scope_file

create_mesh :: (mesh_data: Mesh_Data) -> Mesh {
    mesh: Mesh;
    mesh.material = mesh_data.material;

    mesh.index_count = cast(u32, mesh_data.indices.count);

    using gl;

    glGenVertexArrays(1, *mesh.vao);
    glGenBuffers(1, *mesh.vbo);
    glGenBuffers(1, *mesh.ebo);

    glBindVertexArray(mesh.vao);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.ebo);
    glBufferData(
        GL_ELEMENT_ARRAY_BUFFER,
        mesh_data.indices.count * size_of(u16),
        mesh_data.indices.data,
        GL_STATIC_DRAW,
    );

    glBindBuffer(GL_ARRAY_BUFFER, mesh.vbo);
    glBufferData(
        GL_ARRAY_BUFFER,
        mesh_data.vertices.count * size_of(Vertex),
        mesh_data.vertices.data,
        GL_STATIC_DRAW,
    );

    // Position
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(
        0,
        3,
        GL_FLOAT,
        GL_FALSE,
        size_of(Vertex),
        cast(*void, Vertex_Attribute_Offsets.POSITION),
    );

    // Normal
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(
        1,
        3,
        GL_FLOAT,
        GL_FALSE,
        size_of(Vertex),
        cast(*void, Vertex_Attribute_Offsets.NORMAL),
    );

    // UV
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(
        2,
        2,
        GL_FLOAT,
        GL_FALSE,
        size_of(Vertex),
        cast(*void, Vertex_Attribute_Offsets.UV),
    );

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    return mesh;
}

destroy_mesh :: (mesh: *Mesh) {
    using gl;

    glDeleteVertexArrays(1, *mesh.vao);
    glDeleteBuffers(1, *mesh.vbo);
    glDeleteBuffers(1, *mesh.ebo);

    if mesh.material.texture.id != 0 {
        destroy_texture(*mesh.material.texture);
    }

    mesh.* = Mesh.{};
}

offset_of :: ($T: Type, $member: string) -> int {
    for type_info(T).members {
        if it.name == member{
            return it.offset_in_bytes;
        }
    }

    assert(false, "Type '%' does not have member '%'", T, member);
    return -1;
}

#import "GL";
#import "Math";
