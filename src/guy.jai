Guy :: struct {
    #as using entity: Entity;

    model = "assets/models/guy/guy.gltf";
}

spawn_guy :: () -> Guy {
    guy: Guy;

    guy.position = { 0, 0, -5 };

    set_from_axis_and_angle(*guy.orientation, { 0, 1, 0 }, Engine.deg_to_rad(-90));

    return guy;
}
