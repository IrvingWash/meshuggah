Render_Camera :: struct {
    position: Vector3;

    front:    Vector3;
    up:       Vector3;

    fov: float;

    far:  float;
    near: float;
}

#scope_module

Transforms :: struct {
    perspective:     Matrix4;
    view:            Matrix4;
}

offset_of :: ($T: Type, $member: string) -> int {
    for type_info(T).members {
        if it.name == member{
            return it.offset_in_bytes;
        }
    }

    assert(false, "Type '%' does not have member '%'", T, member);
    return -1;
}
