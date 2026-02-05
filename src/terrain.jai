Terrain :: struct {
    #as using entity: Entity;

    model_path = "assets/models/cube/cube.gltf";
    entity.scale = { 20, 0.1, 20 };
}

spawn_terrain :: () -> Terrain {
    terrain: Terrain;

    terrain.model = Engine.get_model_from_asset_storage(terrain.model_path);

    return terrain;
}
