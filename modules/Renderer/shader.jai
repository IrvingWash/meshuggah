#scope_module

Shader :: struct {
    id: u32;
    uniform_locations: Table(string, s32);
}

create_shader :: (vertex_path: string, fragment_path: string) -> Shader {
    shader: Shader;

    using gl;

    vertex_shader := create_shader(vertex_path, .VERTEX);
    fragment_shader := create_shader(fragment_path, .FRAGMENT);
    defer glDeleteShader(vertex_shader);
    defer glDeleteShader(fragment_shader);

    shader.id = make_program(vertex_shader, fragment_shader);

    return shader;
}

destroy_shader :: (shader: *Shader) {
    using gl;

    glDeleteProgram(shader.id);

    shader.id = 0;

    for _, key: shader.uniform_locations {
        free(key);
    }
    deinit(*shader.uniform_locations);
}

use_shader :: inline (shader: *Shader) {
    using gl;

    glUseProgram(shader.id);
}

set_uniform :: (shader: *Shader, name: string, value: $T)
#modify {
    return T == s32
        || T == float
        || T == Vector2
        || T == Vector3
        || T == Vector4
        || T == Matrix4;
}
{
    using gl;

    #if DEBUG {
        current_program: GLint;
        glGetIntegerv(GL_CURRENT_PROGRAM, *current_program);

        assert(
            current_program == cast(s32, shader.id),
            "Attempt to set an uniform for shader program %, but the currently bound program is %",
            shader.id,
            current_program,
        );
    }

    ok, location := table_find(*shader.uniform_locations, name);
    if !ok {
        c_name := temp_c_string(name);

        location = glGetUniformLocation(shader.id, c_name);

        if location == -1 {
            assert(false, "Couldn't find uniform location for %", name);
        }

        table_set(*shader.uniform_locations, copy_string(name), location);
    }

    #if T == {
        case s32;
            glUniform1i(location, value);
        case float;
            glUniform1f(location, value);
        case Vector2;
            glUniform2f(location, value.x, value.y);
        case Vector3;
            glUniform3f(location, value.x, value.y, value.z);
        case Vector4;
            glUniform4f(location, value.x, value.y, value.z, value.w);
        case Matrix4;
            glUniformMatrix4fv(
                location,
                1, // matrix count
                GL_TRUE, // should transpose?
                *value.coef[0][0], // matrix data
            );
    }
}


#scope_file

Shader_Kind :: enum {
    VERTEX;
    FRAGMENT;
}

make_shader :: (path: string, kind: Shader_Kind) -> u32 {
    shader_src, ok := read_entire_file(path,, temp);
    if !ok {
        assert(false, "Failed to load shader source code from %", path);
    }

    c_shader_src := to_c_string(shader_src,, temp);

    using gl;

    shader: GLuint;
    if kind == {
        case .VERTEX;
            shader = glCreateShader(GL_VERTEX_SHADER);
        case .FRAGMENT;
            shader = glCreateShader(GL_FRAGMENT_SHADER);
    }

    glShaderSource(shader, 1, *c_shader_src, null);

    glCompileShader(shader);

    success: GLint;
    glGetShaderiv(shader, GL_COMPILE_STATUS, *success);
    if !success {
        info_log: [1024]u8;
        glGetShaderInfoLog(shader, info_log.count, null, info_log.data);

        assert(
            false,
            "Failed to compile a % shader from %: %",
            kind, path, to_string(info_log,, tem),
        );
    }

    return shader;
}

make_program :: (vertex_shader: GLuint, fragment_shader: GLuint) -> GLuint {
    using gl;

    id := glCreateProgram();

    glAttachShader(id, vertex_shader);
    glAttachShader(id, fragment_shader);
    glLinkProgram(id);

    success: GLint;
    glGetProgramiv(id, GL_LINK_STATUS, *success);
    if !success {
        info_log: [1024]u8;
        glGetProgramInfoLog(id, info_log.count, null, info_log.data);

        assert(
            false,
            "Failed to link a shader program: %",
            to_string(info_log),
        );
    }

    return id;
}

#import "File";
#import "Hash_Table";
#import "GL";
#import "Math";
