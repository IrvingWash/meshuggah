Key :: GLFW.Key;
Key_State :: GLFW.Key_State;

Framebuffer_Size_Change_Handler :: #type (width: u32, height: u32);
Scroll_Handler :: #type (x_offset: float, y_offset: float);
Cursor_Position_Change_Handler :: #type (x: float, y: float);
Key_Handler :: #type (key: Key, state: Key_State);

create_window :: ($$title: string, width: u32, height: u32, vsync: bool) {
    GLFW.set_error_callback(handle_glfw_error);

    { // GLFW intitalization
        is_glfw_initialized := GLFW.init();
        assert(
            is_glfw_initialized,
            "Failed to initialize GLFW",
        );
    }

    // Hints
    GLFW.set_window_hint(.CONTEXT_VERSION_MAJOR, 3);
    GLFW.set_window_hint(.CONTEXT_VERSION_MINOR, 3);
    GLFW.set_window_hint(.OPENGL_PROFILE, .CORE);
    GLFW.set_window_hint(.SRGB_CAPABLE, true);
    #if OS == .MACOS {
        GLFW.set_window_hint(.OPENGL_FORWARD_COMPATIBILITY, true);
    }

    { // Window creation
        window_data.window = GLFW.create_window(
            width,
            height,
            title,
        );
        assert(window_data.window != null, "Failed to create a window via GLFW");

        GLFW.make_context_current(window_data.window);

        if vsync {
            GLFW.set_swap_interval(1);
        } else {
            GLFW.set_swap_interval(0);
        }
    }

    { // Callbacks
        GLFW.set_framebuffer_size_callback(
            window_data.window,
            handle_framebuffer_size_change,
        );
        GLFW.set_scroll_callback(
            window_data.window,
            handle_scroll,
        );
        GLFW.set_cursor_position_callback(
            window_data.window,
            handle_cursor_position_change,
        );
        GLFW.set_key_callback(
            window_data.window,
            handle_key,
        );
    }

    { // Window data population
        window_data.is_vsync_enabled = vsync;

        width, height: s32;
        GLFW.get_framebuffer_size(window_data.window, *width, *height);
        window_data.pixel_width = cast(u32, width);
        window_data.pixel_height = cast(u32, height);


        window_data.monitor = GLFW.get_primary_monitor();
        assert(window_data.monitor != null, "Failed to get access to the monitor");

        window_data.video_mode = GLFW.get_video_mode(window_data.monitor);
    }

    { // OpenGL initialization
        gl_load(*gl, GLFW.get_proc_address);
    }
}

destroy_window :: () {
    GLFW.destroy_window(window_data.window);
    GLFW.terminate();

    window_data.window = null;

    array_free(window_data.framebuffer_size_change_handlers);
    array_free(window_data.scroll_handlers);
    array_free(window_data.cursor_position_change_handlers);
    array_free(window_data.key_handlers);
}

should_window_close :: inline () -> bool {
    return GLFW.should_window_close(window_data.window);
}

poll_events :: inline () {
    GLFW.poll_events();
}

swap_buffers :: inline () {
    GLFW.swap_buffers(window_data.window);
}

toggle_fullscreen :: () {
    if window_data.is_fullscreen {
        GLFW.set_window_monitor(
            window_data.window,
            null,
            0,
            0,
            window_data.pixel_width,
            window_data.pixel_height,
        );
    } else {
        GLFW.set_window_monitor(
            window_data.window,
            window_data.monitor,
            0,
            0,
            window_data.pixel_width,
            window_data.pixel_height,
        );
    }

    window_data.is_fullscreen = !window_data.is_fullscreen;
}

toggle_vsync :: () {
    if window_data.is_vsync_enabled {
        GLFW.set_swap_interval(0);
    } else {
        GLFW.set_swap_interval(1);
    }

    window_data.is_vsync_enabled = !window_data.is_vsync_enabled;
}

set_window_size :: inline (width: u32, height: u32) {
    GLFW.set_window_size(window_data.window, width, height);
}

add_framebuffer_size_change_handler :: (
    handler: Framebuffer_Size_Change_Handler,
) {
    array_add(*window_data.framebuffer_size_change_handlers, handler);
}

add_scroll_handler :: (
    handler: Scroll_Handler,
) {
    array_add(*window_data.scroll_handlers, handler);
}

add_cursor_position_change_handler :: (
    handler: Cursor_Position_Change_Handler,
) {
    array_add(
        *window_data.cursor_position_change_handlers,
        handler,
    );
}

add_key_handler :: (
    handler: Key_Handler,
) {
    array_add(
        *window_data.key_handlers,
        handler,
    );
}



#scope_file

Window_Data :: struct {
    window:  *GLFW.Window;
    monitor: *GLFW.Monitor;
    video_mode: GLFW.Video_Mode;

    pixel_width: u32;
    pixel_height: u32;

    is_vsync_enabled: bool;
    is_fullscreen: bool;

    framebuffer_size_change_handlers: [..]Framebuffer_Size_Change_Handler;
    scroll_handlers: [..]Scroll_Handler;
    cursor_position_change_handlers: [..]Cursor_Position_Change_Handler;
    key_handlers: [..]Key_Handler;
}

window_data: Window_Data;

handle_glfw_error: GLFW.Error_Proc : (code: s32, description: *u8) #c_call {
    push_context {
        log_error(
            "GLFW error. Code: %, description: %",
            code,
            to_string(description,, temp),
        );
    }
}

handle_framebuffer_size_change: GLFW.Framebuffer_Size_Proc : (
    window: *GLFW.Window,
    width: s32,
    height: s32,
) #c_call {
    window_data.pixel_width = cast(u32, width);
    window_data.pixel_height = cast(u32, height);

    gl.glViewport(0, 0, cast(u32, width), cast(u32, height));

    push_context {
        for proc: window_data.framebuffer_size_change_handlers {
            proc(window_data.pixel_width, window_data.pixel_height);
        }
    }
}

handle_scroll: GLFW.Scroll_Proc : (
    window: *GLFW.Window,
    x_offset: float64,
    y_offset: float64,
) #c_call {
    push_context {
        for proc: window_data.scroll_handlers {
            proc(cast(float, x_offset), cast(float, y_offset));
        }
    }
}

handle_cursor_position_change: GLFW.Cursor_Position_Proc : (
    window: *GLFW.Window,
    x: float64,
    y: float64,
) #c_call {
    push_context {
        for proc: window_data.cursor_position_change_handlers {
            proc(cast(float, x), cast(float, y));
        }
    }
}

handle_key: GLFW.Key_Proc : (
    window: *GLFW.Window,
    key: GLFW.Key,
    scan_code: s32,
    action: GLFW.Key_State,
    mods: s32,
) #c_call {
    push_context {
        for proc: window_data.key_handlers {
            proc(key, action);
        }
    }
}

#import "Basic";
#import "GL";
GLFW :: #import "GLFW";
