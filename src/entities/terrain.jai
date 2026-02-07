Terrain :: struct {
    #as using entity: Entity;

    model_path = "assets/models/cube/cube.gltf";
    entity.scale = { 20, 0.1, 20 };
}

spawn_terrain :: () {
    terrain: Terrain;

    spawn_entity(terrain);
}
