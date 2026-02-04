#module_parameters()(DEBUG: bool = false);

#load "renderer.jai";
#load "model.jai";
#load "shader.jai";
#load "texture.jai";
#load "light.jai";

#if DEBUG {
    #load "debug_renderer.jai";
}



#scope_module

#load "utils.jai";
