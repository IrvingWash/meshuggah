Fairy :: struct {
    #as using entity: Entity;

    entity.scale = { 0.5, 0.5, 0.5 };
    model = "assets/models/cube/cube.gltf";

    offset:          Vector3 = { 2, 3, 1 };
}

update_fairy :: (fairy: *Fairy, master: Entity) {
    fairy.position = master.position + fairy.offset;
}
