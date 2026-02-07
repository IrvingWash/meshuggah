#scope_module

Asset_Storage :: struct {
    model_storage: Model_Storage;
    textures: Table(string, Renderer.Texture);
}

Model_Handle :: #type,distinct u32;

init_asset_storage :: () -> *Asset_Storage {
    asset_storage := New(Asset_Storage);

    return asset_storage;
}

deinit_asset_storage :: (asset_storage: *Asset_Storage) {
    destroy_model_storage(*asset_storage.model_storage);

    for *texture, path: asset_storage.textures {
        free(path);
        Renderer.destroy_texture(texture);
    }
    deinit(*asset_storage.textures);

    free(asset_storage);
}

get_model_from_asset_storage :: (
    asset_storage: *Asset_Storage,
    path: string,
) -> Model_Handle {
    absolute_path, ok := get_absolute_path(path,, temp);
    assert(ok, "Failed to get absolute path for %", path);

    ok =, model_handle := table_find(*asset_storage.model_storage.handles, absolute_path);
    if !ok {
        ok =, error_message, gltf_model_data := GLTF.load(absolute_path);
        assert(ok, error_message);
        defer GLTF.release(*gltf_model_data);

        model_data := convert_gltf_model_data(asset_storage, gltf_model_data);
        defer Renderer.destroy_model_data(*model_data);

        model := Renderer.create_model(model_data);

        array_add(*asset_storage.model_storage.models, model);

        model_handle = cast(Model_Handle, asset_storage.model_storage.models.count - 1);

        table_set(
            *asset_storage.model_storage.handles,
            copy_string(absolute_path),
            model_handle,
        );
    }

    return model_handle;
}

resolve_asset_storage_model :: (
    asset_storage: *Asset_Storage,
    handle: Model_Handle,
) -> *Renderer.Model {
    assert(
        handle < cast,no_check(Model_Handle, asset_storage.model_storage.models.count),
        "Incorrect handle: it's %, but the maximum is %",
        handle,
        asset_storage.model_storage.models.count,
    );

    return *asset_storage.model_storage.models[handle];
}



#scope_file

Model_Storage :: struct {
    handles: Table(string, Model_Handle);
    models: [..]Renderer.Model;
}

destroy_model_storage :: (model_storage: *Model_Storage) {
    for _, path: model_storage.handles {
        free(path);
    }
    deinit(*model_storage.handles);

    for *model: model_storage.models {
        Renderer.destroy_model(model);
    }
    array_free(model_storage.models);

    model_storage.* = {};
}

convert_gltf_model_data :: (asset_storage: *Asset_Storage, gltf_model: GLTF.Model_Data) -> Renderer.Model_Data {
    model_data: Renderer.Model_Data;
    array_reserve(*model_data.meshes, gltf_model.meshes.count);
    array_reserve(*model_data.nodes, gltf_model.nodes.count);

    for gltf_node: gltf_model.nodes {
        node := Renderer.Node.{
            parent = gltf_node.parent,
            first_mesh = gltf_node.first_mesh,
            mesh_count = gltf_node.mesh_count,
            local_transform = gltf_node.local_transform,
        };

        array_reserve(*node.children, gltf_node.children.count);
        array_add(*node.children, ..gltf_node.children);

        array_add(
            *model_data.nodes,
            node,
        );
    }

    for gltf_mesh: gltf_model.meshes {
        texture: Renderer.Texture;

        if gltf_mesh.material.base_color_texture_path {
            ok:, texture = table_find(*asset_storage.textures, gltf_mesh.material.base_color_texture_path);
            if !ok {
                texture = Renderer.create_2D_texture(
                    gltf_mesh.material.base_color_texture_path,
                    Renderer.Texture_Usage.BASE_COLOR,
                );

                table_set(
                    *asset_storage.textures,
                    copy_string(gltf_mesh.material.base_color_texture_path),
                    texture,
                );
            }
        }

        vertices: [..]Renderer.Vertex;
        array_reserve(*vertices, gltf_mesh.vertices.count);
        for gltf_vertex: gltf_mesh.vertices {
            array_add(
                *vertices,
                {
                    position = gltf_vertex.position,
                    normal = gltf_vertex.normal,
                    uv = gltf_vertex.uv,
                },
            );
        }

        indices: [..]u32;
        array_reserve(*indices, gltf_mesh.indices.count);
        array_add(*indices, ..gltf_mesh.indices);

        array_add(
            *model_data.meshes,
            {
                vertices = vertices,
                indices = indices,
                material = {
                    double_sided = gltf_mesh.material.double_sided,
                    base_color_texture = texture,
                    base_color = gltf_mesh.material.base_color,
                },
                min_position = gltf_mesh.min_position,
                max_position = gltf_mesh.max_position,
            },
        );
    }

    return model_data;
}

#import "File";
#import "Basic";
#import "Hash_Table";
GLTF :: #import "GLTF"(VALIDATE = DEBUG);
