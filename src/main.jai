#placeholder DEBUG;

#import "Basic"()(
    MEMORY_DEBUGGER = DEBUG,
    TEMP_ALLOCATOR_POISON_FREED_MEMORY = DEBUG,
    ENABLE_ASSERT = DEBUG,
    VISUALIZE_MEMORY_DEBUGGER = DEBUG,
);
#import "Math";

Engine :: #import "Engine"()(DEBUG = DEBUG);

#load "entity.jai";
#load "entity_manager.jai";
#load "fly_camera.jai";
#load "entities/fairy.jai";
#load "entities/mech.jai";
#load "entities/terrain.jai";
#load "entities/guy.jai";
#load "entities/mccree.jai";

main :: () {
    #if DEBUG {
        defer report_memory_leaks();
    }

    setup_formatting();

    Engine.init("Meshuggah", 800, 600, vsync = true);
    defer Engine.deinit();

    init_entity_manager();
    defer deinit_entity_manager();

    fly_camera := create_fly_camera({ -10, 1, 9 });

    spawn_fairy();
    spawn_mech();
    spawn_terrain();
    spawn_guy();
    spawn_mccree();
    spawn_evil_mccree();

    sun: Engine.Directional_Light = {
        direction = { 0, -1, -1 },
        color = { 1, 0.8, 0.8 },
    };

    look_at(*fly_camera, entity_manager.storage._McCree[0].position);

    while !Engine.is_quit_requested() {
        Engine.begin_frame();

        update_entity_manager();

        for entity: entity_manager.all {
            if entity.type == Mech {
                update_mech(downcast(entity, Mech));
            } else if entity.type == Fairy {
                update_fairy(
                    downcast(entity, Fairy),
                    entity_manager.storage._Mech[0],
                );
            }
        }

        update_camera(*fly_camera);

        Engine.begin_drawing_frame(fly_camera);
        {
            Engine.set_directional_light(sun);
            Engine.set_ambient_light({ 0.1, 0, 0 });
            for entity: entity_manager.all {
                Engine.draw(
                    Engine.resolve_asset_storage_model(entity.model),
                    get_entity_transform(entity),
                    entity.tint,
                );
            }
        }
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
