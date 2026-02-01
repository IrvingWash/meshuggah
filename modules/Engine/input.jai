init_input :: () {
    Window.set_cursor_mode(.DISABLED);

    Window.add_scroll_handler(on_scroll_change);
    Window.add_cursor_position_change_handler(on_cursor_position_change);
    Window.add_key_handler(on_key);
}

deinit_input :: () {
    input_state = {};
}

is_key_held :: inline (key: Window.Key) -> bool {
    return Window.get_key(key) == .PRESS;
}

is_key_pressed :: inline (key: Window.Key) -> bool {
    return input_state.key_state[key] == .PRESS;
}

get_cursor_delta :: inline () -> Vector2 {
    return input_state.cursor_state.delta;
}

get_scroll_delta :: inline () -> Vector2 {
    return input_state.scroll_delta;
}



#scope_module

process_input :: () {
    input_state.scroll_delta = {};
    input_state.cursor_state.delta = {};
    input_state.key_state = DEFAULT_KEY_STATE;

    Window.poll_events();
}



#scope_file

_, HIGHEST_KEY :: #run enum_range(Window.Key);

DEFAULT_KEY_STATE: [HIGHEST_KEY]Window.Key_State;

Input_State :: struct {
    cursor_state: struct {
        previous_position: Vector2;
        delta:             Vector2;
    };

    scroll_delta: Vector2;

    key_state: [HIGHEST_KEY]Window.Key_State;
}

input_state: Input_State;

on_cursor_position_change: Window.Cursor_Position_Change_Handler : (
    x: float,
    y: float,
) {
    using *input_state.cursor_state;

    if previous_position.x != 0 || previous_position.y != 0 {
        delta = {
            x - previous_position.x,
            y - previous_position.y,
        };
    }

    previous_position = {
        x,
        y,
    };
}

on_scroll_change: Window.Scroll_Handler : (
    x_offset: float,
    y_offset: float,
) {
    input_state.scroll_delta = {
        x_offset,
        y_offset,
    };
}

on_key: Window.Key_Handler : (
    key: Window.Key,
    state: Window.Key_State,
) {
    if key >= HIGHEST_KEY {
        return;
    }

    input_state.key_state[key] = state;
}

#import "Math";
Window :: #import "Window";
