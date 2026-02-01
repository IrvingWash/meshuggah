Mech :: struct {
    #as using entity: Entity;

    model = "assets/models/mech/mech.gltf";

    speed: float = 10;
    is_controlled: bool = true;
}

spawn_mech :: () -> Mech {
    mech: Mech;

    qx: Quaternion;
    qy: Quaternion;

    set_from_axis_and_angle(*qx, { 1, 0, 0 }, Engine.deg_to_rad(90));
    set_from_axis_and_angle(*qy, { 0, 1, 0 }, Engine.deg_to_rad(180));

    mech.orientation = qy * qx;

    return mech;
}

update_mech :: (mech: *Mech) {
    if Engine.is_key_pressed(.C) {
        mech.is_controlled = !mech.is_controlled;
    }

    if !mech.is_controlled {
        return;
    }

    disposition := mech.speed * Engine.get_delta_time();

    if Engine.is_key_held(.W) {
        mech.position.z -= disposition;
    }
    if Engine.is_key_held(.S) {
        mech.position.z += disposition;
    }
    if Engine.is_key_held(.A) {
        mech.position.x -= disposition;
    }
    if Engine.is_key_held(.D) {
        mech.position.x += disposition;
    }
}

#import "Math";
