#import "Basic";
#import "File";
#import "jaison";

load :: (path: string) -> ok: bool, error_message: string, GLTF {
    ok, error_message, gltf := parse_gltf_file(path);

    return ok, error_message, gltf;
}

release :: (gltf_file: GLTF) {
    release_gltf_file(gltf);
}



#scope_file

#import "Math";

#load "gltf.jai";
