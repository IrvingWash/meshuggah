McCree :: struct {
    #as using entity: Entity;

    model = "assets/models/low_poly_mccree/scene.gltf";
}

spawn_mccree :: () -> McCree{
    mccree: McCree;

    mccree.position = { -2, 0, 2 };

    return mccree;
}
