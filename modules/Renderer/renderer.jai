init :: (
    framebuffer_size_getter: () -> (u32, u32),
    clear_color: Vector4 = { 0, 0, 1, 1 },
) {
    renderer.get_framebuffer_size = framebuffer_size_getter;
    renderer.clear_color = clear_color;
    renderer.shader = create_shader(
        "modules/Renderer/assets/shaders/test_vertex.glsl",
        "modules/Renderer/assets/shaders/test_fragment.glsl",
    );

    glDepthFunc(GL_LESS);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClearDepth(1);
    glFrontFace(GL_CCW);
    glCullFace(GL_BACK);

    glDisable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glEnable(GL_FRAMEBUFFER_SRGB);
}

deinit :: () {
    destroy_shader(*renderer.shader);
}

begin_frame :: () {
    begin_backbuffer_pass(clear = true);
}

draw :: (model: Model, model_transform: Matrix4) {
    using gl;

    use_shader(renderer.shader);

    set_uniform(renderer.shader, "uModelTransform", model_transform);

    glBindVertexArray(model.mesh.vao);

    glDrawElements(
        GL_TRIANGLES,
        cast(GLsizei, model.mesh.index_count),
        GL_UNSIGNED_INT,
        cast(*void, 0),
    );
}

end_frame :: () {}



#scope_file

Renderer :: struct {
    clear_color: Vector4;
    shader: Shader;

    get_framebuffer_size: () -> (u32, u32);
}

renderer: Renderer;

begin_backbuffer_pass :: (clear: bool) {
    using gl;

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    width, height := renderer.get_framebuffer_size();
    glViewport(0, 0, width, height);

    if clear {
        {
            using renderer.clear_color;
            gl.glClearColor(x, y, z, w);
        }
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }
}
