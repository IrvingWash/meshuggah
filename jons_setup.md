About 1:43 (a bit earlier)

```jai
ENTITIES_PER_BUCKET :: 20;
```

```jai
entity_default_states: [NUM_ENTITY_TYPES]*Entity;
```
Not sure what exacly this is. Looks like they run a function which initializes all the entity types and store the results here. Don't understand how this is useful.

```jai
entity_type_infos: [NUM_ENTITY_TYPES]*Type_Info_Struct;
```
Also not don't understand how is this useful.

```jai
#placeholder init_entity_default_states;
```
Maybe here we could do `Engine.resolve_asset_storage_model(entity.model);` just once, not every time the entity is spawned.

```jai
#placeholder entity_manager_type_of_index;
```
Looks like it returns an entity type for a passed index.

```jai
#placeholder entity_manager_index_of_type;
```
Vice versa. This returns an index for the provided entity type

```jai
#placeholder By_Type;

/*
By_Type :: struct {
    _Guy: [..]*Guy;
}
*/
```
Why just dynamic arrays? Why pointers?

In `By_Type` the have both flat_arrays (as I understand simple arrays and bucket_arrays.
They use #overlay to change flat arrays to a single array of [..]*Entity; Same for bucket_arrays, but it's Type_Erased_Bucket_Array; Same for bucket_arrays, but it's Type_Erased_Bucket_Array.
```jai
By_Type :: struct {
    flat_arrays: void; // Target for #overlay

    // actual flat arrays here

    bucket_arrays: void; // Target for #overlay

    // actual bucket arrays

    #overlay (flat_arrays) voidified: [NUM_ENTITY_TYPES][..]*Entity;
    #overlay (bucket_arrays) voidifiefd_bucket_arrays: [NUM_ENTITY_TYPES]TypeErasedBucketArray;
}
```
