#module_parameters()(DEBUG: bool = false);

Directional_Light :: #type Renderer.Directional_Light;

init :: ($$title: string, width: u32, height: u32, vsync: bool) {
    engine.window = Window.create_window(title, width, height, vsync);
    init_asset_storage();
    engine.renderer = Renderer.init(get_framebuffer_size);
    init_input();
    init_time();
}

deinit :: () {
    deinit_time();
    deinit_input();
    Renderer.deinit(engine.renderer);
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

is_terminating :: () -> bool {
    return Window.should_window_close(engine.window);
}

toggle_fullscreen :: () {
    Window.toggle_fullscreen(engine.window);
}

begin_drawing_frame :: (camera: $T/interface Renderer.Render_Camera) {
    Renderer.begin_drawing_frame(engine.renderer, camera);
}

draw_model :: (
    model: Renderer.Model,
    model_transform: Matrix4,
    tint: Vector4 = { 1, 1, 1, 1 },
) {
    Renderer.draw_model(engine.renderer, model, model_transform, tint);
}

set_directional_light :: (light: Directional_Light) {
    Renderer.set_directional_light(engine.renderer, light);
}

set_ambient_light :: (color: Vector3) {
    Renderer.set_ambient_light(engine.renderer, color);
}

end_drawing_frame :: () {
    Renderer.end_drawing_frame(engine.renderer);
}



#scope_module

engine: Engine;

Renderer :: #import "Renderer"(DEBUG = DEBUG);



#scope_file

Engine :: struct {
    window: Window.Window_Handle;
    renderer: Renderer.Renderer_Handle;
}

get_framebuffer_size :: () -> u32, u32 {
    width, height := Window.get_framebuffer_size(engine.window);

    return width, height;
}

Window :: #import "Window";
#load "asset_storage.jai";
#load "time.jai";
#load "input.jai";
#load "math.jai";
