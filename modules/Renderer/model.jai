Model :: struct {
    mesh: Mesh;
    material: Material;
}

Mesh :: struct {
    vao: u32;
    vbo: u32;
    ebo: u32;

    index_count: u32;
    index_type:  u32;
}

Material :: struct {
    shader: Shader;
    color: Vector4;
}

create_model :: () -> Model {
    model: Model;

    model.mesh = create_mesh();

    return model;
}

destroy_model :: (model: *Model) {
    destroy_mesh(*model.mesh);

    model = {};
}



#scope_file

create_mesh :: () -> Mesh {
    mesh: Mesh;

    using gl;

    glGenVertexArrays(1, *mesh.vao);
    glGenBuffers(1, *mesh.vbo);
    glGenBuffers(1, *mesh.ebo);

    return mesh;
}

destroy_mesh :: (mesh: *Mesh) {
    using gl;

    glDeleteVertexArrays(1, *mesh.vao);
    glDeleteBuffers(1, *mesh.vbo);
    glDeleteBuffers(1, *mesh.ebo);

    mesh = {};
}

#import "GL";
#import "Math";
