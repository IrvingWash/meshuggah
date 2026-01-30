init :: () {
    renderer.shader = create_shader(
        "modules/Renderer/assets/shaders/test_vertex.glsl",
        "modules/Renderer/assets/shaders/test_fragment.glsl",
    );
}

deinit :: () {
    destroy_shader(*renderer.shader);
}

start_drawing :: () {}

draw :: () {}

finish_drawing :: () {}



#scope_file

Renderer :: struct {
    shader: Shader;
}

renderer: Renderer;

#load "shader.jai";
