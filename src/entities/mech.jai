Mech :: struct {
    #as using entity: Entity;

    entity.scale = { 3, 3, 3 };
    model_path = "assets/models/mech/mech.gltf";

    speed: float = 10;
    is_controlled: bool = true;
}

spawn_mech :: () {
    mech: Mech;
    mech.position = {0, 5, 0 };

    set_from_axis_and_angle(*mech.orientation, { 1, 0, 0 }, Engine.deg_to_rad(90));

    add_entity(mech);
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
