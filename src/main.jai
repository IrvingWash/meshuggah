#placeholder DEBUG;

#import "Basic"()(
    MEMORY_DEBUGGER = DEBUG,
    TEMP_ALLOCATOR_POISON_FREED_MEMORY = DEBUG,
    ENABLE_ASSERT = DEBUG,
    VISUALIZE_MEMORY_DEBUGGER = DEBUG,
);
#import "Math";

Engine :: #import "Engine"()(DEBUG = DEBUG);
_ :: #import "Renderer"()(DEBUG = DEBUG); // @Sucks: rendering only to pass the module parameter

main :: () {
    #if DEBUG {
        defer report_memory_leaks();
    }

    setup_formatting();

    Engine.init("Meshuggah", 800, 600, vsync = true);
    defer Engine.deinit();

    mech_handle := Engine.get_model("./assets/models/mech/mech.gltf");
    cube_handle := Engine.get_model("./assets/models/cube/cube.gltf");

    camera: struct {
        position: Vector3 = { 0, 0, 5 };
        fov: float = #run Engine.deg_to_rad(60);
        near: float = 0.1;
        far: float = 1000;
        front: Vector3 = { 0, 0, -1 };
        right:    Vector3 = { 1, 0, 0 };
        world_up: Vector3 = { 0, 1, 0 };
        up: Vector3 = { 0, 1, 0 };
    } = {};

    while !Engine.is_quit_requested() {
        Engine.begin_frame();

        translation_transform := make_translation_matrix4({});
        scale_transform := make_scale_matrix4({ 1, 1, 1 });
        orientation: Quaternion;
        rotation_transform := rotation_matrix(Matrix4, orientation);

        model_transform := translation_transform * rotation_transform * scale_transform;

        Engine.begin_drawing_frame(camera);
        Engine.draw(Engine.resolve_model_handle(mech_handle), model_transform);
        Engine.draw(Engine.resolve_model_handle(cube_handle), model_transform);
        Engine.end_drawing_frame();

        Engine.end_frame();

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
