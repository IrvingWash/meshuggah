#placeholder DEBUG;

#import "Basic"()(
    MEMORY_DEBUGGER = DEBUG,
    TEMP_ALLOCATOR_POISON_FREED_MEMORY = DEBUG,
    ENABLE_ASSERT = DEBUG,
    VISUALIZE_MEMORY_DEBUGGER = DEBUG,
);

Window :: #import "Window";
Renderer :: #import "Renderer";
GLTF :: #import "GLTF";

main :: () {
    #if DEBUG {
        defer report_memory_leaks();
    }

    setup_formatting();

    Window.create_window("Meshuggah", 800, 600, vsync = true);
    defer Window.destroy_window();

    Renderer.init(Window.get_framebuffer_size);
    defer Renderer.deinit();

    model := GLTF.load("assets/models/cube.gltf");
    defer GLTF.release(model);

    while !Window.should_window_close() {
        Window.poll_events();

        Renderer.begin_frame();
        Renderer.draw();
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
