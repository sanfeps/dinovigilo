/// <reference path="../pb_data/types.d.ts" />

// After a user record is created, generate a unique 6-char invite code
// and store it in the `user_private` collection. Helpers are inlined
// because PocketBase pulls a fresh JS VM from the pool for each hook
// invocation — top-level function declarations aren't in scope.
onRecordAfterCreateSuccess((e) => {
    const userId = e.record.id;

    const chars = "ABCDEFGHIJKLMNPQRSTUVWXYZ23456789";
    const randomCode = () => {
        let s = "";
        for (let i = 0; i < 6; i++) {
            s += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return s;
    };

    let code = "";
    let collisions = 0;
    while (collisions < 20) {
        code = randomCode();
        try {
            $app.findFirstRecordByFilter(
                "user_private",
                "inviteCode = {:code}",
                { code: code }
            );
            collisions++;
        } catch (_err) {
            break;
        }
    }
    if (collisions >= 20) {
        $app.logger().error("[onUserCreate] failed to generate unique inviteCode", "userId", userId);
        return;
    }

    try {
        const col = $app.findCollectionByNameOrId("user_private");
        const rec = new Record(col, {
            userId: userId,
            inviteCode: code,
        });
        $app.save(rec);
    } catch (err) {
        $app.logger().error("[onUserCreate] failed to save user_private", "userId", userId, "err", String(err));
    }
}, "users");
