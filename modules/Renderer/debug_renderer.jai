draw_bounding_box :: (
    aabb: AABB,
    world_transform: Matrix4,
    color: Vector4 = { 0, 1, 0, 1 },
) {
    corners: [8]Vector3;
    {
        using aabb;

        corners[0] = Vector3.{ min.x, min.y, min.z };
        corners[1] = Vector3.{ max.x, min.y, min.z };
        corners[2] = Vector3.{ max.x, max.y, min.z };
        corners[3] = Vector3.{ min.x, max.y, min.z };
        corners[4] = Vector3.{ min.x, min.y, max.z };
        corners[5] = Vector3.{ max.x, min.y, max.z };
        corners[6] = Vector3.{ max.x, max.y, max.z };
        corners[7] = Vector3.{ min.x, max.y, max.z };
    }

    for *corner: corners {
        corner.* = (world_transform * Vector4.{ corner.x, corner.y, corner.z, 1 }).xyz;
    }

    draw_line(corners[0], corners[1], color);
    draw_line(corners[1], corners[2], color);
    draw_line(corners[2], corners[3], color);
    draw_line(corners[3], corners[0], color);
    draw_line(corners[4], corners[5], color);
    draw_line(corners[5], corners[6], color);
    draw_line(corners[6], corners[7], color);
    draw_line(corners[7], corners[4], color);
    draw_line(corners[0], corners[4], color);
    draw_line(corners[1], corners[5], color);
    draw_line(corners[2], corners[6], color);
    draw_line(corners[3], corners[7], color);

}

draw_line :: (
    a: Vector3,
    b: Vector3,
    color: Vector4 = { 0, 1, 0, 1 },
) {
    array_add(
        *debug_renderer.vertices,
        { a, color },
        { b, color },
    );
}



#scope_module

init_debug_renderer :: () {
    debug_renderer.shader = create_shader(
        "modules/Renderer/assets/shaders/debug_vertex.glsl",
        "modules/Renderer/assets/shaders/debug_fragment.glsl",
    );

    using gl;

    glGenVertexArrays(1, *debug_renderer.vao);
    glGenBuffers(1, *debug_renderer.vbo);

    glBindVertexArray(debug_renderer.vao);

    glBindBuffer(GL_ARRAY_BUFFER, debug_renderer.vbo);
    glBufferData(
        GL_ARRAY_BUFFER,
        0,
        null,
        GL_DYNAMIC_DRAW,
    );
    // Position
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(
        0,
        3,
        GL_FLOAT,
        GL_FALSE,
        size_of(Debug_Vertex),
        cast(*void, offset_of(Debug_Vertex, "position")),
    );
    // Color
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(
        1,
        4,
        GL_FLOAT,
        GL_FALSE,
        size_of(Debug_Vertex),
        cast(*void, offset_of(Debug_Vertex, "color")),
    );

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

deinit_debug_renderer :: () {
    using gl;

    glDeleteVertexArrays(1, *debug_renderer.vao);
    glDeleteBuffers(1, *debug_renderer.vbo);

    destroy_shader(*debug_renderer.shader);

    array_free(debug_renderer.vertices);

    debug_renderer = {};
}

start_debug_drawing :: (transforms: Transforms) {
    array_reset(*debug_renderer.vertices);

    debug_renderer.transforms = transforms;
}

begin_debug_pass :: () {
    using gl;

    glDisable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    use_shader(debug_renderer.shader);
    set_uniform(debug_renderer.shader, "uProjectionTransform", debug_renderer.transforms.perspective_projection);
    set_uniform(debug_renderer.shader, "uViewTransform", debug_renderer.transforms.view);
}

end_debug_pass :: () {
    using gl;

    if debug_renderer.vertices.count == 0 {
        return;
    }

    glBindVertexArray(debug_renderer.vao);

    glBindBuffer(GL_ARRAY_BUFFER, debug_renderer.vbo);
    glBufferData(
        GL_ARRAY_BUFFER,
        debug_renderer.vertices.count * size_of(Debug_Vertex),
        debug_renderer.vertices.data,
        GL_DYNAMIC_DRAW,
    );

    glDrawArrays(GL_LINES, 0, cast(GLsizei, debug_renderer.vertices.count));

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}



#scope_file

Debug_Renderer :: struct {
    shader: Shader;

    vao: u32;
    vbo: u32;

    transforms: Transforms;

    vertices: [..]Debug_Vertex;
}

debug_renderer: Debug_Renderer;

Debug_Vertex :: struct {
    position: Vector3;
    color: Vector4;
}

#import "GL";
