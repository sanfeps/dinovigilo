/// <reference path="../pb_data/types.d.ts" />

// POST /api/friends/by-code  { "code": "AB7K29" }
// Auth required (users). Looks up the target user via user_private,
// creates a friendship in pending state with userA = requester, and
// returns the new friendship + minimal public info about the target.
//
// Errors:
//   400 invalid_code      — code format wrong
//   400 cannot_add_self   — code belongs to authenticated user
//   404 code_not_found    — no user has that code
//   400 already_exists    — friendship between the pair already exists
routerAdd("POST", "/api/friends/by-code", (e) => {
    const auth = e.auth;
    if (!auth || auth.collection().name !== "users") {
        return e.unauthorizedError("Authentication required.");
    }

    const body = e.requestInfo().body || {};
    const raw = (body.code || "").toString().trim().toUpperCase();
    if (!/^[A-Z0-9]{6}$/.test(raw)) {
        return e.badRequestError("Invalid code format. Expected 6 chars [A-Z0-9].");
    }

    // 1. Find target user via user_private
    let targetUserPrivate;
    try {
        targetUserPrivate = $app.findFirstRecordByFilter(
            "user_private",
            "inviteCode = {:code}",
            { code: raw }
        );
    } catch (_err) {
        return e.notFoundError("Code not found.");
    }
    const targetUserId = targetUserPrivate.get("userId");

    if (targetUserId === auth.id) {
        return e.badRequestError("Cannot add yourself.");
    }

    // 2. Reject duplicate friendship in either direction
    try {
        $app.findFirstRecordByFilter(
            "friendships",
            "(userA = {:a} && userB = {:b}) || (userA = {:b} && userB = {:a})",
            { a: auth.id, b: targetUserId }
        );
        return e.badRequestError("Friendship already exists.");
    } catch (_err) {
        // not found → good, continue
    }

    // 3. Create the friendship (pending). Bypasses collection rules
    //    because $app.save runs server-side without an auth context.
    const friendshipsCol = $app.findCollectionByNameOrId("friendships");
    const friendship = new Record(friendshipsCol, {
        userA: auth.id,
        userB: targetUserId,
        status: "pending",
    });
    $app.save(friendship);

    // 4. Return friendship + public-only info about the target
    const targetUser = $app.findRecordById("users", targetUserId);
    return e.json(200, {
        friendship: {
            id: friendship.id,
            userA: friendship.get("userA"),
            userB: friendship.get("userB"),
            status: friendship.get("status"),
        },
        friend: {
            id: targetUser.id,
            username: targetUser.get("username"),
            displayName: targetUser.get("displayName"),
            avatarEmoji: targetUser.get("avatarEmoji"),
        },
    });
});
