Model :: struct {
    mesh: Mesh;
    material: Material;
}

Mesh :: struct {
    vao: u32;
    vbo: u32;
    ebo: u32;

    index_count: u32;
}

Material :: struct {
    shader: Shader;
    color: Vector4;
}

Vertex :: struct {
    position: Vector3;
    normal:   Vector3;
    uv:       Vector2;
}

Vertex_Attribute_Offsets  :: struct {
    POSITION :: #run offset_of(Vertex, "position");
    NORMAL :: #run offset_of(Vertex, "normal");
    UV :: #run offset_of(Vertex, "uv");
}

create_model :: (vertices: []Vertex, indices: []u32) -> Model {
    model: Model;

    model.mesh = create_mesh(vertices, indices);

    return model;
}

destroy_model :: (model: *Model) {
    destroy_mesh(*model.mesh);

    model.* = {};
}



#scope_file

create_mesh :: (vertices: []Vertex, indices: []u32) -> Mesh {
    mesh: Mesh;

    mesh.index_count = cast(u32, indices.count);

    using gl;

    glGenVertexArrays(1, *mesh.vao);
    glGenBuffers(1, *mesh.vbo);
    glGenBuffers(1, *mesh.ebo);

    glBindVertexArray(mesh.vao);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.ebo);
    glBufferData(
        GL_ELEMENT_ARRAY_BUFFER,
        indices.count * size_of(u32),
        indices.data,
        GL_STATIC_DRAW,
    );

    glBindBuffer(GL_ARRAY_BUFFER, mesh.vbo);
    glBufferData(
        GL_ARRAY_BUFFER,
        vertices.count * size_of(Vertex),
        vertices.data,
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
