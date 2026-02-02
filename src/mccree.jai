McCree :: struct {
    #as using entity: Entity;

    model = "assets/models/low_poly_mccree/scene.gltf";

    entity.scale = { 0.1, 0.1, 0.1 };
}

spawn_mccree :: () -> McCree{
    mccree: McCree;

    mccree.position = { -2, 0, 2 };

    set_from_axis_and_angle(*mccree.orientation, { 1, 0, 0 }, Engine.deg_to_rad(-90));

    return mccree;
}
