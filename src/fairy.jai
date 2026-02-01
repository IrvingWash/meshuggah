Fairy :: struct {
    #as using entity: Entity;

    entity.scale = { 0.3, 0.3, 0.3 };
    model = "assets/models/fairy/fairy.gltf";

    offset:          Vector3 = { 2, 3, 1 };
}

update_fairy :: (fairy: *Fairy, master: Entity) {
    fairy.position = master.position + fairy.offset;
}
