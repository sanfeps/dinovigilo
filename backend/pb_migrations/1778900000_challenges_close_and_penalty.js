/// <reference path="../pb_data/types.d.ts" />

// Extend the `challenges` updateRule so participants can close an active
// challenge (active -> completed with winnerId/loserId/isTie) and so the
// loser can flip `penaltyApplied` once the local penalty has been injected.
//
// Original rule (init_friends_challenges) only allowed updates while the
// challenge was still `proposed` (opponent accepting / proposer cancelling).
// Phase 5 (weekly close) needs two more branches: any participant updating
// while `active`, and the loser updating while `completed`.
migrate((app) => {
    const c = app.findCollectionByNameOrId("challenges");
    c.updateRule =
        "(opponentId = @request.auth.id && status = 'proposed') || " +
        "(proposerId = @request.auth.id && status = 'proposed') || " +
        "((proposerId = @request.auth.id || opponentId = @request.auth.id) && status = 'active') || " +
        "(loserId = @request.auth.id && status = 'completed')";
    app.save(c);
}, (app) => {
    const c = app.findCollectionByNameOrId("challenges");
    c.updateRule =
        "(opponentId = @request.auth.id && status = 'proposed') || " +
        "(proposerId = @request.auth.id && status = 'proposed')";
    app.save(c);
});
