Guy :: struct {
    #as using entity: Entity;
    model_path = "assets/models/guy/guy.gltf";
    type = Guy;

    entity.scale = { 0.6, 0.6, 0.6 };
}

spawn_guy :: () {
    guy: Guy;

    guy.position = { 0, 0, -5 };

    set_from_axis_and_angle(*guy.orientation, { 0, 1, 0 }, Engine.deg_to_rad(-90));

    guy.model = Engine.get_model_from_asset_storage(guy.model_path);

    bucket_array_add(*entity_manager.storage._Guy, guy);
}
