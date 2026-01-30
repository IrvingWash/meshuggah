#import "Basic";
#import "Compiler";
#import "Process";
#import "File";

ABSOLUTE_SOURCE_PATH :: #run -> string {
    return get_absolute_path("glfw");
}

#if OS == .MACOS {
    PLATFORM_NAME :: "macos";
} else #if OS == .LINUX {
    PLATFORM_NAME :: "linux";
} else #if OS == .WINDOWS {
    PLATFORM_NAME :: "windows";
}


#run {
    set_build_options_dc({
        do_output           = false,
        write_added_strings = false,
    });

    build();

    reset_temporary_storage();
}

build :: () {
    // =========================================================================
    // Configure
    // =========================================================================
    config_command: [..]string;
    defer array_free(config_command);

    ok := make_directory_if_it_does_not_exist(PLATFORM_NAME);
    if !ok {
        log_error("Failed to create binary directory");
        return;
    }
    absolute_binary_path := get_absolute_path(PLATFORM_NAME);

    array_add(
        *config_command,
        "cmake",
        ABSOLUTE_SOURCE_PATH,
        tprint("-B %", ABSOLUTE_SOURCE_PATH),
        tprint("-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY=%", absolute_binary_path),
        "-DBUILD_SHARED_LIBS=OFF",
        "-DGLFW_LIBRARY_TYPE=STATIC",
        "-DGLFW_BUILD_EXAMPLES=OFF",
        "-DGLFW_BUILD_TESTS=OFF",
        "-DGLFW_BUILD_DOCS=OFF",
    );
    #if OS == {
        case .MACOS;
            array_add(
                *config_command,
                "-DCMAKE_OSX_DEPLOYMENT_TARGET=26.0",
                "-DGLFW_BUILD_COCOA=ON",
            );
        case .LINUX;
            array_add(
                *config_command,
                "-DGLFW_BUILD_X11=ON",
            );
    }
    run_command(
        ..config_command,
        working_directory = #filepath,
        capture_and_return_output = true,
        print_captured_output     = true,
    );

    // =====================================================================
    // Build
    // =====================================================================
    build_command: [..]string;
    defer array_free(build_command);
    array_add(
        *build_command,
        "cmake",
        "--build",
        ABSOLUTE_SOURCE_PATH,
    );
    #if OS == .WINDOWS {
        array_add(
            *build_command,
            "--config",
            "Release",
        );
    }

    run_command(
        ..build_command,
        working_directory = #filepath,
        capture_and_return_output = true,
        print_captured_output     = true,
    );
}
