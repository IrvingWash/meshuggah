Terrain :: struct {
    #as using entity: Entity;
    type = Terrain; // @Todo do this outside of """user space"""

    model_path = "assets/models/cube/cube.gltf";
    entity.scale = { 20, 0.1, 20 };
}

spawn_terrain :: () {
    terrain: Terrain;

    add_entity(terrain);
}
