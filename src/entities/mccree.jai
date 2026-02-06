McCree :: struct {
    #as using entity: Entity;
    model_path = "assets/models/low_poly_mccree/scene.gltf";
    type = McCree;

    position = { -2, 0.1, 2 };
}

Evil_McCree :: struct {
    #as using entity: Entity;
    model_path = "assets/models/low_poly_mccree/scene.gltf";
    type = Evil_McCree;

    position = { 2, 0.1, -2 };
    entity.scale = { -1, 1, 1 };
    tint = { 1, 0, 0, 1 };
}

spawn_mccree :: () {
    mccree: McCree;

    mccree.model = Engine.get_model_from_asset_storage(mccree.model_path);

    bucket_array_add(*entity_manager.storage._McCree, mccree);
}

spawn_evil_mccree :: () {
    evil_mccree: Evil_McCree;

    evil_mccree.model = Engine.get_model_from_asset_storage(evil_mccree.model_path);

    bucket_array_add(*entity_manager.storage._Evil_McCree, evil_mccree);
}
