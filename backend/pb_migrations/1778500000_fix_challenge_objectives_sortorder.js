/// <reference path="../pb_data/types.d.ts" />

// PocketBase number fields treat the zero value as "blank" when `required: true`,
// so creating the first challenge objective (sortOrder = 0) was rejected with
// `"sortOrder":"cannot be blank"`. The client always sends a value, so dropping
// `required` is safe — `min: 0, max: 4` still bounds the value.
migrate((app) => {
    const c = app.findCollectionByNameOrId("challenge_objectives");
    const field = c.fields.getByName("sortOrder");
    field.required = false;
    app.save(c);
}, (app) => {
    const c = app.findCollectionByNameOrId("challenge_objectives");
    const field = c.fields.getByName("sortOrder");
    field.required = true;
    app.save(c);
});
