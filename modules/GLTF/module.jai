#import "Basic";
#import "File";
#import "jaison";

load :: (path: string) -> ok: bool, error_message: string, GLTF {
    ok, error_message, gltf := parse_gltf_file(path);

    if gltf.scenes.count != 1 {
        return false, sprint("Multi-scene gltf files arne not supported, % has % scenes", path, gltf.scenes.count), gltf;
    }

    scene := gltf.scenes[gltf.scene];

    for node_index: scene.nodes {
        node := gltf.nodes[node_index];

        mesh := gltf.meshes[node.mesh];

        print("%\n", mesh);
    }

    return ok, error_message, gltf;
}

release :: (gltf_file: *GLTF) {
    release_gltf_file(gltf_file);
}



#scope_file

#import "Basic";
#import "Math";

#load "gltf_parser.jai";
