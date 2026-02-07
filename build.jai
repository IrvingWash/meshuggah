#import "Basic";
#import "Compiler";
#import "Metaprogram_Plugins";
#import "File";
#import "Print_Color";
#import "String";

ENTRY_FILE          :: "src/main.jai";
OUTPUT_PATH_WILDCARD :: "build/%";
EXECUTABLE_NAME     :: "target";

DEFAULT_PLUGINS_TO_CREATE :: Plugin_To_Create.[
    { name = "Check" },
];

HELP_TEXT :: #string DONE
Options:
  --optimized    Build in VERY_OPTIMIZED mode
  --debug        Build in DEBUG mode
  -h, --help     Show this help message

Plugins:
    Any plugins shipped with the language can be used.

Example
    jai ./build.jai - --optimized +Autorun
DONE

Config :: struct {
    should_help:       bool;
    optimization_type: Optimization_Type;
    plugins_to_create: []Plugin_To_Create;
}

run_when_ready_procedures: [..]*Code_Procedure_Header;

#run,stallable {
    set_build_options_dc({
        do_output           = false,
        write_added_strings = true,
    });

    build_options_dc := get_build_options();

    ok, config := create_config(build_options_dc.compile_time_command_line);
    if !ok {
        log_error("Failed to configure the build");
        return;
    }

    if config.should_help {
        log(HELP_TEXT);
        return;
    }

    ok =, error_message := build(build_options_dc, config);
    if !ok {
        log_error("Build failed: %", error_message);
    }
}

build :: (build_options_dc: Build_Options, config: Config) -> ok: bool, error_message: string {
    print_color("Building meshuggah in % mode\n", config.optimization_type, color = .GREEN, .UNDERLINE);
    for plugin_to_create: config.plugins_to_create {
        print_color("'%' plugin enabled\n", plugin_to_create.name, color = .BLUE);
    }

    workspace := compiler_create_workspace("meshuggah");
    if !workspace {
        return false, "Workspace creation failed";
    }

    output_path := tprint(OUTPUT_PATH_WILDCARD, config.optimization_type);

    // Build options
    {
        build_options := get_build_options(workspace);
        copy_commonly_propagated_fields(build_options_dc, *build_options);

        #if #exists(JAILS_DIAGNOSTICS_BUILD) {
            build_options.output_type = .NO_OUTPUT;
        } else {
            build_options.output_type = .EXECUTABLE;
        }

        build_options.output_executable_name = EXECUTABLE_NAME;
        build_options.output_path = output_path;
        build_options.intermediate_path = output_path;
        #if OS == .MACOS {
            build_options.minimum_os_version = { major = 14, minor = 0 };
        }

        set_optimization(*build_options, config.optimization_type);

        set_build_options(build_options, workspace);
    }

    ok := make_directory_if_it_does_not_exist(output_path, recursive = true);
    if !ok {
        return false, "Failed to create the build directory";
    }

    plugins: [..]*Metaprogram_Plugin;
    plugins.allocator = temp;
    ok = init_plugins(config.plugins_to_create, *plugins, workspace);
    array_free(config.plugins_to_create);
    if !ok {
        return false, "Failed to initialize plugins";
    }

    intercept_flags: Intercept_Flags;

    for plugin: plugins {
        if plugin.before_intercept {
            plugin.before_intercept(plugin, *intercept_flags);
        }
    }

    compiler_begin_intercept(workspace, intercept_flags);

    for plugin: plugins {
        if plugin.add_source {
            plugin.add_source(plugin);
        }
    }

    add_build_file(ENTRY_FILE, workspace);

    handle_compiler_messages(plugins, config, workspace);

    compiler_end_intercept(workspace);

    for plugin: plugins {
        if plugin.finish {
            plugin.finish(plugin);
        }

        if plugin.shutdown {
            plugin.shutdown(plugin);
        }
    }

    return true, "";
}

handle_compiler_messages :: (
    plugins: []*Metaprogram_Plugin,
    config: Config,
    workspace: Workspace,
) {
    while true {
        message := compiler_wait_for_message();

        for plugin: plugins {
            if plugin.message {
                plugin.message(plugin, message);
            }
        }

        handle_run_when_ready(message);
        handle_debug_constant(message, config, workspace);

        if message.kind == {
            case .COMPLETE;
                break;
        }
    }
}

create_config :: (arguments: []string) -> ok: bool, Config {
    config: Config;
    unknown_flags: [..]string;
    unknown_flags.allocator = temp;

    for argument: arguments {
        if argument == {
            case "-h";
                #through;
            case "--help";
                config.should_help = true;
            case "--optimized";
                config.optimization_type = .VERY_OPTIMIZED;
            case "--debug";
                config.optimization_type = .DEBUG;
            case;
                if !starts_with(argument, "+") { // Any plugins can be passed
                    array_add_if_unique(*unknown_flags, argument);
                }
        }
    }

    if unknown_flags.count > 0 {
        log_error("Encountered unknown command line flags: %", join(..unknown_flags, separator = ", "));
        return false, {};
    }

    ok, plugins_to_create := parse_plugin_arguments(arguments);
    if ok {
        array_add(*plugins_to_create, ..DEFAULT_PLUGINS_TO_CREATE);
        config.plugins_to_create = plugins_to_create;
    }

    return ok, config;
}

handle_debug_constant :: (
    message: *Message,
    config: Config,
    workspace: Workspace,
) {
    if message.kind == {
        case .FILE;
            file := cast(*Message_File, message);
            if ends_with(file.fully_pathed_filename, "main.jai") {
                add_build_string(
                    tprint(
                        "DEBUG: bool : %;",
                        config.optimization_type <= .VERY_DEBUG
                    ),
                    workspace,
                    file
                );
            }
    }
}

handle_run_when_ready :: (message: *Message) {
    RUN_WHEN_READY_NOTE :: "RunWhenReady";

    if message.kind == {
        case .TYPECHECKED;
            typechecked := cast(*Message_Typechecked) message;
            for tc: typechecked.procedure_headers {
                header := tc.expression;
                if has_note(header, RUN_WHEN_READY_NOTE) {
                    array_add(*run_when_ready_procedures, header);
                }
            }
        case .PHASE;
            phase := cast(*Message_Phase) message;
            if phase.phase == .TYPECHECKED_ALL_WE_CAN {
                for run_when_ready_procedures {
                    s := tprint("#run %();", it.name);
                    add_build_string(s, message.workspace);
                }

                array_reset(*run_when_ready_procedures);
            }
    }
}

has_note :: (header: *Code_Procedure_Header, note: string) -> bool {
    for header.notes {
        if it.text == note {
            return true;
        }
    }

    return false;
}
