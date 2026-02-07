Renderer_Handle :: #type,distinct *void;

init :: (
    framebuffer_size_getter: () -> (u32, u32),
    clear_color: Vector4 = { 0, 0, 1, 1 },
) -> Renderer_Handle {
    renderer := New(Renderer);

    renderer.get_framebuffer_size = framebuffer_size_getter;
    renderer.clear_color = clear_color;
    renderer.shader = create_shader(
        "modules/Renderer/assets/shaders/test_vertex.glsl",
        "modules/Renderer/assets/shaders/test_fragment.glsl",
    );
    renderer.default_base_color_texture = create_2D_texture(
        "modules/Renderer/assets/textures/default.png",
        Texture_Usage.BASE_COLOR,
    );

    #if DEBUG {
        init_debug_renderer();
    }

    return cast(Renderer_Handle, renderer);
}

deinit :: (handle: Renderer_Handle) {
    renderer := cast(*Renderer, handle);

    #if DEBUG {
        deinit_debug_renderer();
    }

    deinit(*renderer.batches);
    destroy_shader(*renderer.shader);
    destroy_texture(*renderer.default_base_color_texture);

    free(renderer);
}

begin_drawing_frame :: (handle: Renderer_Handle, camera: $T/interface Render_Camera) {
    renderer := cast(*Renderer, handle);

    renderer.transforms.perspective = make_perspective_projection_transform_from_camera(renderer, camera);
    renderer.transforms.view = make_view_transform_from_camera(camera);

    #if DEBUG {
        start_debug_drawing(renderer.transforms);
    }
}

draw_model :: (
    handle: Renderer_Handle,
    model: Model,
    model_transform: Matrix4,
    tint: Vector4 = { 1, 1, 1, 1 },
) {
    renderer := cast(*Renderer, handle);

    for node: model.nodes {
        if node.parent == -1 {
            draw_node(renderer, model, cast(u32, it_index), model_transform, tint);
        }
    }
}

set_ambient_light :: (handle: Renderer_Handle, color: Vector3) {
    renderer := cast(*Renderer, handle);

    renderer.ambient_light.color = color;
}

set_directional_light :: (handle: Renderer_Handle, light: Directional_Light) {
    renderer := cast(*Renderer, handle);

    renderer.directional_light = light;
}

end_drawing_frame :: (handle: Renderer_Handle) {
    renderer := cast(*Renderer, handle);

    begin_backbuffer_pass(renderer, clear = true);
    finish_backbuffer_pass(renderer);

    #if DEBUG {
        begin_debug_pass();
        end_debug_pass();
    }

    table_reset(*renderer.batches);
}



#scope_file

Renderer :: struct {
    clear_color: Vector4;
    shader: Shader;

    get_framebuffer_size: () -> (u32, u32);

    transforms: Transforms;

    default_base_color_texture: Texture;

    batches: Table(u32, Batch);

    ambient_light: Ambient_Light;
    directional_light: Directional_Light;
}

Batch :: struct {
    mesh: Mesh;
    instances: [..]Instance;
    instances.allocator = temp;
}

begin_backbuffer_pass :: (renderer: *Renderer, clear: bool) {
    using gl;

    glDepthFunc(GL_LESS);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClearDepth(1);
    glFrontFace(GL_CCW);
    glCullFace(GL_BACK);

    glDisable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glEnable(GL_FRAMEBUFFER_SRGB);
    glDepthMask(GL_TRUE);

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

    use_shader(renderer.shader);

    set_uniform(
        renderer.shader,
        "uProjectionTransform",
        renderer.transforms.perspective,
    );
    set_uniform(renderer.shader, "uViewTransform", renderer.transforms.view);

    set_uniform(
        renderer.shader,
        "uAmbientLight.color",
        renderer.ambient_light.color,
    );
    set_uniform(
        renderer.shader,
        "uDirectionalLight.direction",
        renderer.directional_light.direction,
    );
    set_uniform(
        renderer.shader,
        "uDirectionalLight.color",
        renderer.directional_light.color,
    );
}

finish_backbuffer_pass :: (renderer: *Renderer) {
    using gl;

    for batch: renderer.batches {
        // Material
        set_uniform(
            renderer.shader,
            "uMaterial.baseColor",
            batch.mesh.material.base_color,
        );
        set_uniform(
            renderer.shader,
            "uMaterial.baseColorTexture",
            cast(s32, 0),
        );
        if batch.mesh.material.base_color_texture.id != 0 {
            bind_texture(batch.mesh.material.base_color_texture, 0);
        } else {
            bind_texture(renderer.default_base_color_texture, 0);
        }
        if batch.mesh.material.double_sided {
            glDisable(GL_CULL_FACE);
        } else {
            glEnable(GL_CULL_FACE);
        }

        glBindVertexArray(batch.mesh.vao);

        // Batch allocation
        batch_size := batch.instances.count * size_of(Instance);

        glBindBuffer(GL_ARRAY_BUFFER, batch.mesh.instance_vbo);
        glBufferData(
            GL_ARRAY_BUFFER,
            batch_size,
            batch.instances.data,
            GL_DYNAMIC_DRAW,
        );

        glDrawElementsInstanced(
            GL_TRIANGLES,
            cast(GLsizei, batch.mesh.index_count),
            GL_UNSIGNED_INT,
            cast(*void, 0),
            cast(GLsizei, batch.instances.count),
        );

        glBindVertexArray(0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    unbind_texture();
}

draw_node :: (
    renderer: *Renderer,
    model: Model,
    node_index: u32,
    parent_world_transform: Matrix4,
    tint: Vector4,
) {
    node := model.nodes[node_index];

    world_transform := parent_world_transform * node.local_transform;

    if node.mesh_count > 0 {
        for node.first_mesh..(node.first_mesh + node.mesh_count - 1) {
            mesh := model.meshes[it];
            ok, normal_transform := inverse(make_matrix3(world_transform), epsilon = 0.00001);
            assert(ok, "Failed to inverse a matrix");

            instance: Instance = {
                tint = tint,
                transform = transpose(world_transform),
                normal_transform = normal_transform, // Not transposing as we would need to transpose again in the shader
            };

            batch := table_find_pointer(*renderer.batches, mesh.vao);
            if batch != null {
                array_add(*batch.instances, instance);
            } else {
                new_batch: Batch = { mesh = mesh };

                array_add(*new_batch.instances, instance);

                // @Todo: we currently use mesh.vao as the key to the table. That sucks
                table_set(*renderer.batches, mesh.vao, new_batch);
            }

            #if DEBUG {
                draw_bounding_box(mesh.aabb, world_transform);
            }
        }
    }

    for child_index: node.children {
        draw_node(renderer, model, child_index, world_transform, tint);
    }
}

make_perspective_projection_transform_from_camera :: (
    renderer: *Renderer,
    camera: $T/interface Render_Camera,
) -> Matrix4 {
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
#import "Hash_Table";
