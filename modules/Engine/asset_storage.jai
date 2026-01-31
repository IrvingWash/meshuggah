Asset_Handle :: u32;

init_asset_storage :: () {}

deinit_asset_storage :: () {
    destroy_model_storage(*asset_storage.model_storage);
}

get_model :: (path: string) -> Asset_Handle {
    absolute_path, ok := get_absolute_path(path);
    assert(ok, "Failed to get absolute path for %", path);

    ok, handle := table_find(asset_storage.model_storage.map, absolute_path);
    if !ok {
        ok =, error_message, model_data := GLTF.load(absolute_path);
        assert(ok, error_message);
        defer GLTF.release(model_data);

        model := Renderer.create_model(model_data);

        array_add(*asset_storage.model_storage.models, model);

        handle = asset_storage.model_storage.models.count - 1;

        table_set(*asset_storage.model_storage.map, copy_string(absolute_path), handle);
    }

    return handle;
}

resolve_model_handle :: (handle: Asset_Handle) -> Renderer.Model {
    return asset_storage.model_storage.models[handle];
}



#scope_file

Asset_Storage :: struct {
    model_storage: Model_Storage;
}

asset_storage: Asset_Storage;

Model_Storage :: struct {
    map: Table(string, Asset_Handle);
    models: [..]Renderer.Model;
}

destroy_model_storage :: (model_storage: *Model_Storage) {
    for *model: model_storage.models {
        Renderer.destroy_model(model);
    }
    array_free(model_storage.models);

    for _, path: model_storage.map {
        free(path);
    }
    table_reset(*model_storage.map);
    deinit(*model_storage.map);

    model_storage.* = {};
}

#import "File";
#import "Basic";
#import "Hash_Table";
GLTF :: #import "GLTF";
Renderer :: #import "Renderer";
