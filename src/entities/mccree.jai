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

    add_entity(mccree);
}

spawn_evil_mccree :: () {
    evil_mccree: Evil_McCree;

    add_entity(evil_mccree);
}
