#module_parameters(DEBUG: bool = false);

#load "renderer.jai";
#load "model.jai";
#load "texture.jai";
#load "light.jai";
#load "utils.jai";



#scope_module

#load "shader.jai";

#if DEBUG {
    #load "debug_renderer.jai";
}
