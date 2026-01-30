create_window :: ($$title: string, vsync: bool) {
    GLFW.set_error_callback(on_glfw_error);

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
        monitor := GLFW.get_primary_monitor();
        assert(monitor != null, "Failed to get access to the monitor");

        video_mode := GLFW.get_video_mode(monitor);

        window_data.window = GLFW.create_window(
            video_mode.width,
            video_mode.height,
            title,
            monitor,
        );

        assert(window_data.window != null, "Failed to create a window via GLFW");

        GLFW.make_context_current(window_data.window);

        if vsync {
            GLFW.set_swap_interval(1);
        } else {
            GLFW.set_swap_interval(0);
        }
    }

    { // OpenGL setup
        #import "GL"; 
        gl_load(*gl, GLFW.get_proc_address);
    }

    { // Window data population
        window_data.is_vsync_enabled = vsync;

        width, height: s32;
        GLFW.get_framebuffer_size(window_data.window, *width, *height);
        window_data.pixel_width = cast(u32, width);
        window_data.pixel_height = cast(u32, height);
    }
}

destroy_window :: () {
    GLFW.destroy_window(window_data.window);
    GLFW.terminate();

    window_data.window = null;
}

should_window_close :: inline () -> bool {
    return GLFW.should_window_close(window_data.window);
}

poll_events :: inline () {
    GLFW.poll_events();
}

toggle_vsync :: () {
    if window_data.is_vsync_enabled {
        GLFW.set_swap_interval(0);
    } else {
        GLFW.set_swap_interval(1);
    }

    window_data.is_vsync_enabled = !window_data.is_vsync_enabled;
}



#scope_file

Window_Data :: struct {
    window: *GLFW.Window;

    pixel_width: u32;
    pixel_height: u32;

    is_vsync_enabled: bool;
}

window_data: Window_Data;

on_glfw_error: GLFW.Error_Proc : (code: s32, description: *u8) #c_call {
    push_context {
        log_error(
            "GLFW error. Code: %, description: %",
            code,
            to_string(description,, temp),
        );
    }
}

#import "Basic";
GLFW :: #import "GLFW";
