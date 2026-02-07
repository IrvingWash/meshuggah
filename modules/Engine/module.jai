#module_parameters()(DEBUG: bool = false);

init :: ($$title: string, width: u32, height: u32, vsync: bool) {
    engine.window = Window.create_window(title, width, height, vsync);
    init_asset_storage();
    Renderer.init(get_framebuffer_size);
    init_input();
    init_time();
}

deinit :: () {
    deinit_time();
    deinit_input();
    Renderer.deinit();
    deinit_asset_storage();
    Window.destroy_window(engine.window);
}

begin_frame :: () {
    update_time();

    process_input();
}

end_frame :: () {
    Window.swap_buffers(engine.window);
}

get_framebuffer_size :: () -> u32, u32 {
    width, height := Window.get_framebuffer_size(engine.window);

    return width, height;
}

is_terminating :: () -> bool {
    return Window.should_window_close(engine.window);
}

toggle_fullscreen :: () {
    Window.toggle_fullscreen(engine.window);
}

Directional_Light :: Renderer.Directional_Light;

begin_drawing_frame   :: Renderer.begin_frame;
end_drawing_frame     :: Renderer.end_frame;
draw                  :: Renderer.draw;
set_directional_light :: Renderer.set_directional_light;
set_ambient_light     :: Renderer.set_ambient_light;



#scope_module

engine: Engine;

Renderer :: #import "Renderer"(DEBUG = DEBUG);



#scope_file

Engine :: struct {
    window: Window.Window_Handle;
}

Window :: #import "Window";
#load "asset_storage.jai";
#load "time.jai";
#load "input.jai";
#load "math.jai";
