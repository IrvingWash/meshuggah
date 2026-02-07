Fairy :: struct {
    #as using entity: Entity;
    model_path = "assets/models/fairy/fairy.gltf";

    entity.scale = { 0.3, 0.3, 0.3 };

    offset:          Vector3 = { 2, 3, 1 };
}

spawn_fairy :: () {
    fairy: Fairy;

    spawn_entity(fairy);
}

update_fairy :: (fairy: *Fairy, master: Entity) {
    fairy.position = master.position + fairy.offset;
}
