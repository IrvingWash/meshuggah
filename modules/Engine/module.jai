#module_parameters()(DEBUG: bool = false);

init :: ($$title: string, width: u32, height: u32, vsync: bool) {
    Window.create_window(title, width, height, vsync);
    init_asset_storage();
    Renderer.init(Window.get_framebuffer_size);
    init_input();
    init_time();
}

deinit :: () {
    deinit_time();
    deinit_input();
    Renderer.deinit();
    deinit_asset_storage();
    Window.destroy_window();
}

begin_frame :: () {
    update_time();

    process_input();
}

end_frame :: () {
    Window.swap_buffers();
}

is_quit_requested :: Window.should_window_close;
toggle_fullscreen :: Window.toggle_fullscreen;

Directional_Light :: Renderer.Directional_Light;

begin_drawing_frame   :: Renderer.begin_frame;
end_drawing_frame     :: Renderer.end_frame;
draw                  :: Renderer.draw;
set_directional_light :: Renderer.set_directional_light;
set_ambient_light     :: Renderer.set_ambient_light;

get_model_from_storage :: get_model;



#scope_file

Window :: #import "Window";
Renderer :: #import "Renderer";
#load "asset_storage.jai";
#load "time.jai";
#load "input.jai";
#load "math.jai";
