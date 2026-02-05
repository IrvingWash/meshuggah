#placeholder DEBUG;

#import "Basic"()(
    MEMORY_DEBUGGER = DEBUG,
    TEMP_ALLOCATOR_POISON_FREED_MEMORY = DEBUG,
    ENABLE_ASSERT = DEBUG,
    VISUALIZE_MEMORY_DEBUGGER = DEBUG,
);
#import "Math";

Engine :: #import "Engine"()(DEBUG = DEBUG);

#load "fly_camera.jai";
#load "entity.jai";
#load "fairy.jai";
#load "mech.jai";
#load "terrain.jai";
#load "guy.jai";
#load "mccree.jai";

main :: () {
    #if DEBUG {
        defer report_memory_leaks();
    }

    setup_formatting();

    Engine.init("Meshuggah", 800, 600, vsync = true);
    defer Engine.deinit();

    fly_camera := create_fly_camera({ -10, 1, 9 });

    fairy := spawn_fairy();
    mech := spawn_mech();
    terrain := spawn_terrain();
    guy := spawn_guy();
    mccree := spawn_mccree();
    evil_mccree := spawn_evil_mccree();
    sun: Engine.Directional_Light = {
        direction = { 0, -1, -1 },
        color = { 1, 0.8, 0.8 },
    };

    look_at(*fly_camera, mccree.position);

    while !Engine.is_quit_requested() {
        Engine.begin_frame();

        update_mech(*mech);
        update_fairy(*fairy, mech);
        update_camera(*fly_camera);

        Engine.begin_drawing_frame(fly_camera);
        Engine.set_directional_light(sun);
        Engine.set_ambient_light({ 0.1, 0, 0 });
        Engine.draw(
            Engine.resolve_asset_storage_model(fairy.model),
            get_entity_transform(fairy),
            fairy.tint,
        );
        Engine.draw(
            Engine.resolve_asset_storage_model(mech.model),
            get_entity_transform(mech),
            mech.tint,
        );
        Engine.draw(
            Engine.resolve_asset_storage_model(terrain.model),
            get_entity_transform(terrain),
            terrain.tint,
        );
        Engine.draw(
            Engine.resolve_asset_storage_model(guy.model),
            get_entity_transform(guy),
            guy.tint,
        );
        Engine.draw(
            Engine.resolve_asset_storage_model(mccree.model),
            get_entity_transform(mccree),
            mccree.tint,
        );
        Engine.draw(
            Engine.resolve_asset_storage_model(evil_mccree.model),
            get_entity_transform(evil_mccree),
            evil_mccree.tint,
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
