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
    renderer.default_base_color_texture = create_2D_texture(
        "modules/Renderer/assets/textures/default.png",
        .BASE_COLOR,
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
    destroy_texture(*renderer.default_base_color_texture);
}

begin_frame :: (camera: $T/interface Render_Camera) {
    renderer.transforms.perspective_projection = make_perspective_projection_transform_from_camera(camera);
    renderer.transforms.view = make_view_transform_from_camera(camera);

    begin_backbuffer_pass(clear = true);
}

draw :: (model: Model, model_transform: Matrix4) {
    using gl;

    use_shader(renderer.shader);

    set_uniform(renderer.shader, "uModelTransform", model_transform);
    set_uniform(renderer.shader, "uProjectionTransform", renderer.transforms.perspective_projection);
    set_uniform(renderer.shader, "uViewTransform", renderer.transforms.view);

    for mesh: model.meshes {
        glBindVertexArray(mesh.vao);

        set_uniform(renderer.shader, "uTint", mesh.material.tint);
        set_uniform(renderer.shader, "uMaterial.baseColor", cast(s32, 0));

        if mesh.material.texture.id != 0 {
            bind_texture(mesh.material.texture);
        } else {
            bind_texture(renderer.default_base_color_texture);
        }

        glDrawElements(
            GL_TRIANGLES,
            cast(GLsizei, mesh.index_count),
            GL_UNSIGNED_INT,
            cast(*void, 0),
        );

        unbind_texture();
    }
}

end_frame :: () {}



#scope_file

Renderer :: struct {
    clear_color: Vector4;
    shader: Shader;

    get_framebuffer_size: () -> (u32, u32);

    transforms: struct {
        perspective_projection: Matrix4;
        view:                   Matrix4;
    }

    default_base_color_texture: Texture;
}

renderer: Renderer;

Render_Camera :: struct {
    position: Vector3;

    front:    Vector3;
    up:       Vector3;

    fov: float;

    far:  float;
    near: float;
}

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

make_perspective_projection_transform_from_camera :: (camera: $T/interface Render_Camera) -> Matrix4 {
    width, height := renderer.get_framebuffer_size(); // @Todo this will eventually be get_render_target_size, right?

    return make_projection_matrix(
        camera.fov,
        cast(float, width) / cast(float, height),
        camera.near,
        camera.far,
    );
}

make_view_transform_from_camera :: (camera: $T/interface Render_Camera) -> Matrix4 {
    return make_look_at_matrix(
        camera.position,
        camera.position + camera.front,
        camera.up,
        false,
    );
}

#import "Math";
