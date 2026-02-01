init_asset_storage :: () {}

deinit_asset_storage :: () {
    for *model, path: asset_storage.models {
        free(path);
        Renderer.destroy_model(model);
    }
    deinit(*asset_storage.models);

    asset_storage = {};
}

get_model :: (path: string) -> Renderer.Model {
    absolute_path, ok := get_absolute_path(path,, temp);
    assert(ok, "Failed to get absolute path for %", path);

    ok =, model := table_find(*asset_storage.models, absolute_path);
    if !ok {
        ok =, error_message, gltf_model := GLTF.load(absolute_path);
        assert(ok, error_message);
        defer GLTF.release(*gltf_model);

        model_data := convert_gltf_model(gltf_model);
        defer Renderer.destroy_model_data(*model_data);

        model = Renderer.create_model(model_data);

        table_set(*asset_storage.models, copy_string(absolute_path), model);
    }

    return model;
}



#scope_file

Asset_Storage :: struct {
    models: Table(string, Renderer.Model);
}

asset_storage: Asset_Storage;

convert_gltf_model :: (gltf_model: GLTF.Model) -> Renderer.Model_Data {
    model_data: Renderer.Model_Data;
    array_reserve(*model_data.meshes, gltf_model.meshes.count);

    for mesh: gltf_model.meshes {
        array_add(
            *model_data.meshes,
            {
                vertices = cast,force([]Renderer.Vertex, mesh.vertices),
                indices = mesh.indices,
                material = {
                    tint = mesh.material.base_color,
                    double_sided = mesh.material.double_sided,
                },
            },
        );
    }

    return model_data;
}

#import "File";
#import "Basic";
#import "Hash_Table";
GLTF :: #import "GLTF"(VALIDATE = DEBUG);
Renderer :: #import "Renderer";
