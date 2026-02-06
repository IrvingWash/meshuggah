Entity_Manager :: struct {
    all: []*Entity;
    storage: Entity_Storage;
    next_id: u32;
}

entity_manager: Entity_Manager;

init_entity_manager :: () {}

deinit_entity_manager :: () {
    destroy_entity_storage(*entity_manager.storage);
}

update_entity_manager :: () {
    entity_manager.all = get_all_entities();
}

add_entity :: (entity: $T)
#modify {
    return is_subclass_of(cast(*Type_Info, T), "Entity");
}
{
    pointer: *T;
    locator: Bucket_Locator;

    #insert -> string {
        entity_type_names := make_entity_type_names();

        builder: String_Builder;

        print_to_builder(*builder, "    #if T == {\n");

        for entity_type_names {
            print_to_builder(
                *builder,
                "        case %1; locator, pointer = bucket_array_add(*entity_manager.storage._%1, entity);\n",
                it,
            );
        }

        print_to_builder(*builder, "    }\n");

        return builder_to_string(*builder);
    }

    pointer.locator = locator;
    pointer.type = T;
    pointer.id = entity_manager.next_id;

    if pointer.model_path {
        pointer.model = Engine.get_model_from_asset_storage(entity.model_path);
    }

    entity_manager.next_id += 1;
}



#scope_file

Entity_Storage :: struct {
    #insert -> string {
        return generate_entity_storage_body();
    }
};

get_all_entities :: () -> []*Entity {
    #insert -> string {
        return generate_get_all_entities_body();
    }
}

destroy_entity_storage :: (storage: *Entity_Storage) {
    #insert -> string {
        entity_type_names := make_entity_type_names();

        builder: String_Builder;

        for entity_type_names {
            print_to_builder(
                *builder,
                "    bucket_array_reset(*storage._%);\n",
                it,
            );
        }

        return builder_to_string(*builder);
    }
}

// =============================================================================
// Code generations
// =============================================================================

generate_get_all_entities_body :: () -> string #compile_time {
INSERTION_STRING :: #string DONE
    all_entities: [..]*Entity;
    all_entities.allocator = temp;

    array_reserve(
        *all_entities,
%
    );

%

    return all_entities;
DONE
    entity_type_names := make_entity_type_names();

    reserve_code_builder: String_Builder;
    addition_code_builder: String_Builder;

    for entity_type_names {
        print_to_builder(
            *reserve_code_builder,
            "        + entity_manager.storage._%.count\n",
            it
        );

        print_to_builder(
            *addition_code_builder,
            "    for *entity_manager.storage._% array_add(*all_entities, it);\n",
            it,
        );
    }

    return sprint(
        INSERTION_STRING,
        builder_to_string(*reserve_code_builder),
        builder_to_string(*addition_code_builder),
    );
}

generate_entity_storage_body :: () -> string #compile_time {
    entity_type_names := make_entity_type_names();

    builder: String_Builder;

    for entity_type_names {
        items_per_bucket := 32;

        print_to_builder(
            *builder,
            "   _%1: Bucket_Array(%1, %2, true);\n",
            it,
            items_per_bucket,
        );
    }

    return builder_to_string(*builder);
}

make_entity_type_names :: () -> []string #compile_time {
    #import "Compiler";
    #import "Sort";

    w := get_current_workspace();

    type_table := get_type_table(w);

    entity_type_names: [..]string;
    for type_table {
        if it.type != .STRUCT {
            continue;
        }

        tis := cast(*Type_Info_Struct, it);

        if is_subclass_of(it, "Entity") {
            array_add(*entity_type_names, tis.name);
        }
    }

    return quick_sort(entity_type_names, compare_strings);
}

#import "Bucket_Array";
