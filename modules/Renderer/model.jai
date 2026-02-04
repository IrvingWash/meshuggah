Model :: struct {
    meshes: [..]Mesh;
    nodes:  [..]Node;
}

Mesh :: struct {
    vao:          u32;
    vbo:          u32;
    ebo:          u32;
    instance_vbo: u32;

    index_count: u32;

    material: Material;

    bounding_sphere: Bounding_Sphere;
    aabb:            AABB;
}

Node :: struct {
    parent:   int = -1;
    children: [..]u32;

    first_mesh: u32;
    mesh_count: u32;

    local_transform: Matrix4;
}

Material :: struct {
    double_sided: bool;

    base_color_texture: Texture;
    base_color: Vector4;
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
    nodes:  [..]Node;
}

Mesh_Data :: struct {
    vertices: [..]Vertex;
    indices:  [..]u32;
    material: Material;

    min_position: Vector3;
    max_position: Vector3;
}

create_model :: (model_data: Model_Data) -> Model {
    model: Model;
    array_reserve(*model.meshes, model_data.meshes.count);
    array_reserve(*model.nodes, model_data.nodes.count);

    for mesh_data: model_data.meshes {
        array_add(
            *model.meshes,
            create_mesh(mesh_data),
        );
    }

    array_add(*model.nodes, ..model_data.nodes);

    return model;
}

destroy_model :: (model: *Model) {
    for *mesh: model.meshes {
        destroy_mesh(mesh);
    }
    array_free(model.meshes);

    for node: model.nodes {
        array_free(node.children);
    }
    array_free(model.nodes);

    model.* = {};
}

destroy_model_data :: (model_data: *Model_Data) {
    for mesh: model_data.meshes {
        array_free(mesh.vertices);
        array_free(mesh.indices);
    }
    array_free(model_data.meshes);

    array_free(model_data.nodes);

    model_data.* = {};
}



#scope_module

Instance :: struct {
    tint: Vector4;

    transform:        Matrix4;
    normal_transform: Matrix3;
}

// create_bounding_sphere
Bounding_Sphere :: struct {
    center: Vector3;
    radius: float;
}

// create_aabb
AABB :: struct {
    min: Vector3;
    max: Vector3;
}



#scope_file

create_mesh :: (mesh_data: Mesh_Data) -> Mesh {
    mesh: Mesh;
    mesh.material = mesh_data.material;

    mesh.index_count = cast(u32, mesh_data.indices.count);

    mesh.bounding_sphere = create_bounding_sphere(mesh_data.min_position, mesh_data.max_position);
    mesh.aabb = {
        min = mesh_data.min_position,
        max = mesh_data.max_position,
    };

    using gl;

    glGenVertexArrays(1, *mesh.vao);
    glGenBuffers(1, *mesh.vbo);
    glGenBuffers(1, *mesh.ebo);
    glGenBuffers(1, *mesh.instance_vbo);

    glBindVertexArray(mesh.vao);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.ebo);
    glBufferData(
        GL_ELEMENT_ARRAY_BUFFER,
        mesh_data.indices.count * size_of(u32),
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

    // Instance VBO
    glBindBuffer(GL_ARRAY_BUFFER, mesh.instance_vbo);
    glBufferData(
        GL_ARRAY_BUFFER,
        size_of(Instance),
        null,
        GL_DYNAMIC_DRAW,
    );

    // Tint
    glEnableVertexAttribArray(3);
    glVertexAttribDivisor(3, 1);
    glVertexAttribPointer(
        3,
        4,
        GL_FLOAT,
        GL_FALSE,
        size_of(Instance),
        cast(*void, 0),
    );

    // Model transform
    add_matrix_attribute(4, Instance, "transform", Matrix4);

    // Normal transform
    add_matrix_attribute(8, Instance, "normal_transform", Matrix3);

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    return mesh;
}

add_matrix_attribute :: (
    start_attribute: u32,
    $Struct: Type,
    $member: string,
    $Matrix_type: Type,
)
#modify {
    return Matrix_type == Matrix4 || Matrix_type == Matrix3;
}
{
    attribute := start_attribute;

    using gl;

    for 0..Matrix_type.v.count - 1 {
        defer attribute += 1;

        glEnableVertexAttribArray(attribute);
        glVertexAttribDivisor(attribute, 1);
        glVertexAttribPointer(
            attribute,
            Matrix_type.Row_Type.component.count,
            GL_FLOAT,
            GL_FALSE,
            size_of(Struct),
            cast(
                *void,
                offset_of(Struct, member) + it * size_of(Matrix_type.Row_Type)
            ),
        );
    }
}

destroy_mesh :: (mesh: *Mesh) {
    using gl;

    glDeleteVertexArrays(1, *mesh.vao);
    glDeleteBuffers(1, *mesh.vbo);
    glDeleteBuffers(1, *mesh.ebo);
    glDeleteBuffers(1, *mesh.instance_vbo);

    mesh.* = Mesh.{};
}

create_bounding_sphere :: (min_position: Vector3, max_position: Vector3) -> Bounding_Sphere {
    sphere: Bounding_Sphere;

    sphere.center = (min_position + max_position) / 2;
    sphere.radius = length(max_position - sphere.center);

    return sphere;
}

#import "GL";
#import "Math";
