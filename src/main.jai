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

#load "fly_camera.jai";
#load "entity.jai";
#load "cube.jai";
#load "mech.jai";

main :: () {
    #if DEBUG {
        defer report_memory_leaks();
    }

    setup_formatting();

    Engine.init("Meshuggah", 800, 600, vsync = true);
    defer Engine.deinit();

    fly_camera := create_fly_camera();

    cube: Cube;
    mech: Mech;

    while !Engine.is_quit_requested() {
        Engine.begin_frame();

        update_camera(*fly_camera);

        Engine.begin_drawing_frame(fly_camera);
        Engine.draw(
            Engine.get_model_from_storage(cube.model),
            get_entity_transform(cube),
        );
        Engine.draw(
            Engine.get_model_from_storage(mech.model),
            get_entity_transform(mech),
        );
        Engine.end_drawing_frame();

        Engine.end_frame();

        reset_temporary_storage();

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
