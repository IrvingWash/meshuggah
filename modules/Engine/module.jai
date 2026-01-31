#module_parameters()(DEBUG: bool = false);

init :: ($$title: string, width: u32, height: u32, vsync: bool) {
    Window.create_window(title, width, height, vsync);
    init_asset_storage();
    Renderer.init(Window.get_framebuffer_size);
}

deinit :: () {
    Renderer.deinit();
    deinit_asset_storage();
    Window.destroy_window();
}

begin_frame :: () {
    update_time();

    Window.poll_events();
}

end_frame :: () {
    Window.swap_buffers();
}

is_quit_requested :: Window.should_window_close;



#scope_file

Window :: #import "Window";
Renderer :: #import "Renderer";
#load "asset_storage.jai";
#load "time.jai";
