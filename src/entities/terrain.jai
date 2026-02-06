Terrain :: struct {
    #as using entity: Entity;
    type = Terrain; // @Todo do this outside of """user space"""

    model_path = "assets/models/cube/cube.gltf";
    entity.scale = { 20, 0.1, 20 };
}

spawn_terrain :: () {
    terrain: Terrain;

    terrain.model = Engine.get_model_from_asset_storage(terrain.model_path); // @Todo do this outside of """user space"""

    bucket_array_add(*entity_manager.storage._Terrain, terrain);
}
