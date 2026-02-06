Entity :: struct {
    id: u32;
    locator: Bucket_Locator;
    type: Type;

    position: Vector3;
    scale:    Vector3 = { 1, 1, 1 };
    orientation: Quaternion;

    model_path: string;
    model: Engine.Model_Handle;

    tint: Vector4 = { 1, 1, 1, 1 };

    flags: Entity_Flags;
}

Entity_Flags :: enum_flags #specified {
    NONE      :: 0;
    INVISIBLE :: 1 << 0;
}

get_entity_transform :: (entity: Entity) -> Matrix4 {
    translation := make_translation_matrix4(entity.position);
    rotation := rotation_matrix(Matrix4, entity.orientation);
    scale := make_scale_matrix4(entity.scale);

    return translation * rotation * scale;
}

has_flags :: (entity: Entity, flags: Entity_Flags) -> bool {
    return (flags & entity.flags) == flags;
}

add_flags :: (entity: *Entity, flags: Entity_Flags) {
    entity.flags |= flags;
}

remove_flags :: (entity: *Entity, flags: Entity_Flags) {
    entity.flags &= ~flags;
}

downcast :: (entity: *Entity, $T: Type) -> *T
#modify {
    return is_subclass_of(cast(*Type_Info, T), "Entity");
}
{
    assert(entity.type == T);

    return cast(*T, entity);
}



#scope_file

#import "Math";
#import "Bucket_Array";
#import "Compiler";
