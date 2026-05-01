/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
    // ============================================================
    // 1. Extend the built-in `users` auth collection
    // ============================================================
    const users = app.findCollectionByNameOrId("users");

    users.fields.add(new TextField({
        name: "username",
        required: true,
        min: 3,
        max: 20,
        pattern: "^[a-z0-9_]+$",
    }));
    users.fields.add(new TextField({
        name: "displayName",
        max: 30,
    }));
    users.fields.add(new TextField({
        name: "avatarEmoji",
        max: 8,
    }));
    users.fields.add(new BoolField({
        name: "optInScreenTime",
    }));

    users.indexes = [
        ...(users.indexes || []),
        "CREATE UNIQUE INDEX `idx_users_username` ON `users` (`username`)",
    ];

    users.listRule = "id = @request.auth.id";
    users.viewRule = "id = @request.auth.id";
    users.createRule = "";
    users.updateRule = "id = @request.auth.id";
    users.deleteRule = "id = @request.auth.id";

    app.save(users);
    const usersId = users.id;

    // ============================================================
    // 2. user_private — inviteCode lives here, never visible to friends
    // ============================================================
    const userPrivate = new Collection({
        type: "base",
        name: "user_private",
        fields: [
            {
                type: "relation",
                name: "userId",
                required: true,
                collectionId: usersId,
                cascadeDelete: true,
                maxSelect: 1,
            },
            {
                type: "text",
                name: "inviteCode",
                required: true,
                min: 6,
                max: 6,
                pattern: "^[A-Z0-9]+$",
            },
            { type: "autodate", name: "created", onCreate: true },
            { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
        ],
        indexes: [
            "CREATE UNIQUE INDEX idx_user_private_user ON user_private (userId)",
            "CREATE UNIQUE INDEX idx_user_private_code ON user_private (inviteCode)",
        ],
        listRule: "userId = @request.auth.id",
        viewRule: "userId = @request.auth.id",
        createRule: null,
        updateRule: null,
        deleteRule: null,
    });
    app.save(userPrivate);

    // ============================================================
    // 3. friendships
    // ============================================================
    const friendships = new Collection({
        type: "base",
        name: "friendships",
        fields: [
            {
                type: "relation",
                name: "userA",
                required: true,
                collectionId: usersId,
                cascadeDelete: true,
                maxSelect: 1,
            },
            {
                type: "relation",
                name: "userB",
                required: true,
                collectionId: usersId,
                cascadeDelete: true,
                maxSelect: 1,
            },
            {
                type: "select",
                name: "status",
                required: true,
                values: ["pending", "accepted", "blocked"],
                maxSelect: 1,
            },
            { type: "date", name: "acceptedAt" },
            { type: "autodate", name: "created", onCreate: true },
            { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
        ],
        indexes: [
            "CREATE UNIQUE INDEX idx_friendships_pair ON friendships (userA, userB)",
            "CREATE INDEX idx_friendships_userA ON friendships (userA)",
            "CREATE INDEX idx_friendships_userB ON friendships (userB)",
        ],
        listRule: "userA = @request.auth.id || userB = @request.auth.id",
        viewRule: "userA = @request.auth.id || userB = @request.auth.id",
        createRule: "userA = @request.auth.id",
        updateRule: "userB = @request.auth.id && status = 'pending'",
        deleteRule: "userA = @request.auth.id || userB = @request.auth.id",
    });
    app.save(friendships);

    // ============================================================
    // 4. challenges
    // ============================================================
    const challenges = new Collection({
        type: "base",
        name: "challenges",
        fields: [
            {
                type: "relation",
                name: "proposerId",
                required: true,
                collectionId: usersId,
                cascadeDelete: false,
                maxSelect: 1,
            },
            {
                type: "relation",
                name: "opponentId",
                required: true,
                collectionId: usersId,
                cascadeDelete: false,
                maxSelect: 1,
            },
            {
                type: "select",
                name: "status",
                required: true,
                values: ["proposed", "active", "completed", "cancelled", "rejected"],
                maxSelect: 1,
            },
            { type: "date", name: "weekStart" },
            { type: "date", name: "weekEnd" },
            {
                type: "text",
                name: "penaltyObjective",
                required: true,
                min: 1,
                max: 200,
            },
            {
                type: "relation",
                name: "winnerId",
                collectionId: usersId,
                cascadeDelete: false,
                maxSelect: 1,
            },
            {
                type: "relation",
                name: "loserId",
                collectionId: usersId,
                cascadeDelete: false,
                maxSelect: 1,
            },
            { type: "bool", name: "isTie" },
            { type: "bool", name: "penaltyApplied" },
            { type: "autodate", name: "created", onCreate: true },
            { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
        ],
        indexes: [
            "CREATE INDEX idx_challenges_proposer ON challenges (proposerId)",
            "CREATE INDEX idx_challenges_opponent ON challenges (opponentId)",
            "CREATE INDEX idx_challenges_status ON challenges (status)",
        ],
        listRule: "proposerId = @request.auth.id || opponentId = @request.auth.id",
        viewRule: "proposerId = @request.auth.id || opponentId = @request.auth.id",
        createRule: "proposerId = @request.auth.id && status = 'proposed'",
        updateRule:
            "(opponentId = @request.auth.id && status = 'proposed') || " +
            "(proposerId = @request.auth.id && status = 'proposed')",
        deleteRule: null,
    });
    app.save(challenges);
    const challengesId = challenges.id;

    // ============================================================
    // 5. challenge_objectives
    // ============================================================
    const challengeObjectives = new Collection({
        type: "base",
        name: "challenge_objectives",
        fields: [
            {
                type: "relation",
                name: "challengeId",
                required: true,
                collectionId: challengesId,
                cascadeDelete: true,
                maxSelect: 1,
            },
            { type: "text", name: "title", required: true, min: 1, max: 100 },
            { type: "text", name: "description", max: 500 },
            { type: "number", name: "sortOrder", required: true, min: 0, max: 4 },
            { type: "autodate", name: "created", onCreate: true },
            { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
        ],
        indexes: [
            "CREATE INDEX idx_challenge_objectives_challenge ON challenge_objectives (challengeId)",
            "CREATE UNIQUE INDEX idx_challenge_objectives_order ON challenge_objectives (challengeId, sortOrder)",
        ],
        listRule:
            "challengeId.proposerId = @request.auth.id || " +
            "challengeId.opponentId = @request.auth.id",
        viewRule:
            "challengeId.proposerId = @request.auth.id || " +
            "challengeId.opponentId = @request.auth.id",
        createRule:
            "challengeId.proposerId = @request.auth.id && " +
            "challengeId.status = 'proposed'",
        updateRule:
            "challengeId.proposerId = @request.auth.id && " +
            "challengeId.status = 'proposed'",
        deleteRule:
            "challengeId.proposerId = @request.auth.id && " +
            "challengeId.status = 'proposed'",
    });
    app.save(challengeObjectives);
    const challengeObjectivesId = challengeObjectives.id;

    // ============================================================
    // 6. challenge_completions
    // ============================================================
    const challengeCompletions = new Collection({
        type: "base",
        name: "challenge_completions",
        fields: [
            {
                type: "relation",
                name: "challengeId",
                required: true,
                collectionId: challengesId,
                cascadeDelete: true,
                maxSelect: 1,
            },
            {
                type: "relation",
                name: "userId",
                required: true,
                collectionId: usersId,
                cascadeDelete: true,
                maxSelect: 1,
            },
            {
                type: "relation",
                name: "objectiveId",
                required: true,
                collectionId: challengeObjectivesId,
                cascadeDelete: true,
                maxSelect: 1,
            },
            { type: "date", name: "date", required: true },
            { type: "bool", name: "completed" },
            { type: "autodate", name: "created", onCreate: true },
            { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
        ],
        indexes: [
            "CREATE UNIQUE INDEX idx_challenge_completions_unique ON challenge_completions (challengeId, userId, objectiveId, date)",
            "CREATE INDEX idx_challenge_completions_challenge ON challenge_completions (challengeId)",
        ],
        listRule:
            "challengeId.proposerId = @request.auth.id || " +
            "challengeId.opponentId = @request.auth.id",
        viewRule:
            "challengeId.proposerId = @request.auth.id || " +
            "challengeId.opponentId = @request.auth.id",
        createRule:
            "userId = @request.auth.id && " +
            "challengeId.status = 'active' && " +
            "(challengeId.proposerId = @request.auth.id || challengeId.opponentId = @request.auth.id)",
        updateRule:
            "userId = @request.auth.id && challengeId.status = 'active'",
        deleteRule: null,
    });
    app.save(challengeCompletions);

    // ============================================================
    // 7. daily_summaries — visible to self and to accepted friends
    // ============================================================
    const friendVisibilityRule =
        "userId = @request.auth.id || " +
        "(@collection.friendships.userA = @request.auth.id && @collection.friendships.userB = userId && @collection.friendships.status = 'accepted') || " +
        "(@collection.friendships.userB = @request.auth.id && @collection.friendships.userA = userId && @collection.friendships.status = 'accepted')";

    const dailySummaries = new Collection({
        type: "base",
        name: "daily_summaries",
        fields: [
            {
                type: "relation",
                name: "userId",
                required: true,
                collectionId: usersId,
                cascadeDelete: true,
                maxSelect: 1,
            },
            { type: "date", name: "date", required: true },
            { type: "bool", name: "perfectDay" },
            { type: "number", name: "completedCount", min: 0 },
            { type: "number", name: "totalCount", min: 0 },
            { type: "number", name: "screenTimeMinutes", min: 0 },
            { type: "number", name: "streakValue", min: 0 },
            { type: "number", name: "dinosaurCount", min: 0 },
            { type: "autodate", name: "created", onCreate: true },
            { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
        ],
        indexes: [
            "CREATE UNIQUE INDEX idx_daily_summaries_user_date ON daily_summaries (userId, date)",
        ],
        listRule: friendVisibilityRule,
        viewRule: friendVisibilityRule,
        createRule: "userId = @request.auth.id",
        updateRule: "userId = @request.auth.id",
        deleteRule: "userId = @request.auth.id",
    });
    app.save(dailySummaries);

}, (app) => {
    // ----- Down migration: drop everything created above -----
    const dropOrder = [
        "daily_summaries",
        "challenge_completions",
        "challenge_objectives",
        "challenges",
        "friendships",
        "user_private",
    ];
    for (const name of dropOrder) {
        try {
            const c = app.findCollectionByNameOrId(name);
            app.delete(c);
        } catch (e) {
            // already gone
        }
    }

    // Best-effort restore of `users` to vanilla state
    try {
        const users = app.findCollectionByNameOrId("users");
        for (const fname of ["username", "displayName", "avatarEmoji", "optInScreenTime"]) {
            const f = users.fields.getByName(fname);
            if (f) {
                users.fields.removeById(f.id);
            }
        }
        users.indexes = (users.indexes || []).filter(
            (i) => !i.includes("idx_users_username")
        );
        users.listRule = null;
        users.viewRule = null;
        users.createRule = "";
        users.updateRule = "id = @request.auth.id";
        users.deleteRule = "id = @request.auth.id";
        app.save(users);
    } catch (e) {
        // ignore
    }
});
