Fairy :: struct {
    #as using entity: Entity;
    model_path = "assets/models/fairy/fairy.gltf";

    entity.scale = { 0.3, 0.3, 0.3 };

    offset:          Vector3 = { 2, 3, 1 };
}

spawn_fairy :: () -> Fairy {
    fairy: Fairy;

    fairy.model = Engine.get_model_from_asset_storage(fairy.model_path);

    return fairy;
}

update_fairy :: (fairy: *Fairy, master: Entity) {
    fairy.position = master.position + fairy.offset;
}
