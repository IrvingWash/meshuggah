#module_parameters()(DEBUG: bool = false);

Directional_Light :: #type Renderer.Directional_Light;

init :: ($$title: string, width: u32, height: u32, vsync: bool) {
    engine.window = Window.create_window(title, width, height, vsync);
    engine.asset_storage = init_asset_storage();
    engine.renderer = Renderer.init(get_framebuffer_size);
    engine.input_state = init_input(engine.window);
    init_time();
}

deinit :: () {
    deinit_time();
    deinit_input(engine.input_state);
    Renderer.deinit(engine.renderer);
    deinit_asset_storage(engine.asset_storage);
    Window.destroy_window(engine.window);
}

begin_frame :: () {
    update_time();

    process_input(engine.input_state);
}

end_frame :: () {
    Window.swap_buffers(engine.window);
}

// =============================================================================
// Windowing
// =============================================================================

is_terminating :: () -> bool {
    return Window.should_window_close(engine.window);
}

toggle_fullscreen :: () {
    Window.toggle_fullscreen(engine.window);
}

// =============================================================================
// Rendering
// =============================================================================

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

// =============================================================================
// Asset Storage
// =============================================================================

get_model_from_asset_storage :: (path: string) -> Model_Handle {
    return get_model_from_asset_storage(engine.asset_storage, path);
}

resolve_asset_storage_model :: (handle: Model_Handle) -> Renderer.Model {
    return resolve_asset_storage_model(engine.asset_storage, handle);
}

// =============================================================================
// Input
// =============================================================================

get_scroll_delta :: () -> Vector2 {
    return get_scroll_delta(engine.input_state);
}

get_cursor_delta :: () -> Vector2 {
    return get_cursor_delta(engine.input_state);
}

is_key_pressed :: (key: Window.Key) -> bool {
    return is_key_pressed(engine.input_state, key);
}

is_key_held :: (key: Window.Key) -> bool {
    return is_key_held(engine.input_state, key);
}



#scope_module

engine: Engine; // @Todo move into file scope

Window :: #import "Window";
Renderer :: #import "Renderer"(DEBUG = DEBUG);



#scope_file

Engine :: struct {
    window: Window.Window_Handle;
    renderer: Renderer.Renderer_Handle;
    asset_storage: *Asset_Storage;
    input_state: *Input_State;
}

get_framebuffer_size :: () -> u32, u32 {
    width, height := Window.get_framebuffer_size(engine.window);

    return width, height;
}

#load "asset_storage.jai";
#load "time.jai";
#load "input.jai";
#load "math.jai";
