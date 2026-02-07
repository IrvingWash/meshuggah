#scope_module

Time :: struct {
    // Real time, not affected by scale
    raw_previous: float64;
    raw_current:  float64;
    raw_delta:    float;

    // Time affected by scale
    simulated_time: float64;

    scale: float = 1;

    next_timer_id: u32 = 1;
    timers: Table(u32, Timer_Data);

    finished_timers: [..]u32;
}


init_time :: () -> *Time {
    time := New(Time);

    return time;
}

deinit_time :: (time: *Time) {
    deinit(*time.timers);

    array_free(time.finished_timers);

    free(time);
}

get_delta_time :: (time: *Time) -> float {
    return time.raw_delta * time.scale;
}

get_time_scale :: (time: *Time) -> float {
    return time.scale;
}

get_time :: (time: *Time) -> float64 {
    return time.simulated_time;
}

set_time_scale :: (time: *Time, scale: float) {
    time.scale = scale;
}

set_timeout :: inline (time: *Time, seconds: float) -> u32 {
    return set_timer(seconds, false);
}

set_interval :: inline (time: *Time, seconds: float) -> u32 {
    return set_timer(seconds, true);
}

clear_timer :: (time: *Time, id: u32) {
    table_remove(*time.timers, id);
}

get_finished_timers :: (time: *Time) -> []u32 {
    return time.finished_timers;
}

update_time :: (time: *Time) {
    array_reset_keeping_memory(*time.finished_timers);

    time.raw_previous = time.raw_current;
    time.raw_current = seconds_since_init();

    time.raw_delta = cast(
        float,
        min(time.raw_current - time.raw_previous, MAX_DELTA_TIME)
    );

    time.simulated_time += time.raw_delta * time.scale;

    timer_ids_to_remove: [..]u32;
    timer_ids_to_remove.allocator = temp;

    for *timer: time.timers {
        if time.simulated_time >= timer.duration + timer.start_time {
            array_add(*time.finished_timers, timer.id);

            if timer.is_interval {
                timer.start_time += timer.duration;
            } else {
                array_add(*timer_ids_to_remove, timer.id);
            }
        }
    }

    for timer_id: timer_ids_to_remove {
        clear_timer(time, timer_id);
    }
}



#scope_file

MAX_DELTA_TIME: float64 : 1.0 / 60.0 * 2;

Timer_Data :: struct {
    id: u32;

    start_time: float64; // In simulated time (scaled)
    duration:   float;

    is_interval: bool;
}

set_timer :: (seconds: float, is_interval: bool) -> u32 {
    defer time.next_timer_id += 1;

    timer_data: Timer_Data = {
        id = time.next_timer_id,
        duration = seconds,
        start_time = time.simulated_time,
        is_interval = is_interval,
    };

    table_set(*time.timers, time.next_timer_id, timer_data);

    return time.next_timer_id;
}


#import "Basic";
#import "Math";
#import "Hash_Table";
