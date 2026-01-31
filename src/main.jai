#placeholder DEBUG;

#import "Basic"()(
    MEMORY_DEBUGGER = DEBUG,
    TEMP_ALLOCATOR_POISON_FREED_MEMORY = DEBUG,
    ENABLE_ASSERT = DEBUG,
    VISUALIZE_MEMORY_DEBUGGER = DEBUG,
);
#import "Math";

Engine :: #import "Engine";
Window :: #import "Window";
Renderer :: #import "Renderer"()(DEBUG = DEBUG);
GLTF :: #import "GLTF";

TRIANGLE_INDICES :: u32.[
    0, 1, 2,
];

TRIANGLE_VERTICES :: Renderer.Vertex.[
    {
        position = { 0, 0.5, 0 },
        normal = { 0, 0, 1 },
        uv = { 1, 0 },
    },
    {
        position = { -0.5, -0.5, 0 },
        normal = { 0, 0, 1 },
        uv = { 1, 0 },
    },
    {
        position = { 0.5, -0.5, 0 },
        normal = { 0, 0, 1 },
        uv = { 1, 0 },
    },
];

main :: () {
    #if DEBUG {
        defer report_memory_leaks();
    }

    setup_formatting();

    Window.create_window("Meshuggah", 800, 600, vsync = true);
    defer Window.destroy_window();

    Renderer.init(Window.get_framebuffer_size);
    defer Renderer.deinit();

    Engine.init_asset_storage();
    defer Engine.deinit_asset_storage();

    ok, message, gltf_triangle := GLTF.load("assets/models/cube/cube.gltf");
    assert(ok, message);
    defer GLTF.release(*gltf_triangle);

    triangle := Renderer.create_model(TRIANGLE_VERTICES, TRIANGLE_INDICES);
    defer Renderer.destroy_model(*triangle);

    camera: struct {
        position: Vector3 = { 0, 0, 3 };
        fov: float = #run deg_to_rad(60);
        near: float = 0.1;
        far: float = 1000;
        front: Vector3 = { 0, 0, -1 };
        right:    Vector3 = { 1, 0, 0 };
        world_up: Vector3 = { 0, 1, 0 };
        up: Vector3 = { 0, 1, 0 };
    } = {};

    while !Window.should_window_close() {
        Window.poll_events();

        translation_transform := make_translation_matrix4({});
        scale_transform := make_scale_matrix4({ 1, 1, 1 });
        orientation: Quaternion;
        set_from_axis_and_angle(*orientation, { 0, 0, 1 }, deg_to_rad(90));
        rotation_transform := rotation_matrix(Matrix4, orientation);

        model_transform := translation_transform * rotation_transform * scale_transform;

        Renderer.begin_frame(camera);
        Renderer.draw(triangle, model_transform);
        Renderer.end_frame();

        Window.swap_buffers();

        #if DEBUG {
            memory_visualizer_per_frame_update();
        }
    }
}

setup_formatting :: () {
    print_style := *context.print_style;

    print_style.default_format_struct.draw_type_name = true;
    print_style.default_format_struct.use_long_form_if_more_than_this_many_members = 0;
    print_style.default_format_struct.use_newlines_if_long_form = true;
}

deg_to_rad :: (degrees: float) -> float {
    return degrees * PI_BY_HALF_CIRCLE;
}

PI_BY_HALF_CIRCLE :: PI / 180.0;
