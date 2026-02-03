McCree :: struct {
    #as using entity: Entity;

    model = "assets/models/low_poly_mccree/scene.gltf";
    position = { -2, 0.1, 2 };
}

Evil_McCree :: struct {
    #as using entity: Entity;

    model = "assets/models/low_poly_mccree/scene.gltf";
    position = { 2, 0.1, -2 };
    entity.scale = { -1, 1, 1 };
    tint = { 1, 0, 0, 1 };
}
