import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/repositories/challenges_repository.dart';
import 'package:dinovigilo/features/challenges/domain/services/challenge_progress.dart';

/// Outcome of a single challenge close, returned per challenge so the UI can
/// surface the right message.
enum ClosedChallengeOutcome { iWon, iLost, tie }

class ClosedChallengeReport {
  const ClosedChallengeReport({
    required this.challenge,
    required this.outcome,
  });

  final Challenge challenge;
  final ClosedChallengeOutcome outcome;
}

/// Walks the user's challenges and closes any that are still `active` after
/// `weekEnd`. Computes the winner from per-side `failedDayCount` (lower wins;
/// equal = tie). Race-safe: if another client closed it first, PB returns 403
/// and we just skip the entry.
class CloseExpiredChallengesUseCase {
  CloseExpiredChallengesUseCase(this._repository);

  final ChallengesRepository _repository;

  Future<Result<List<ClosedChallengeReport>>> execute({
    required String myUserId,
  }) async {
    final listResult = await _repository.list();
    if (listResult.isFailure) return Result.failure(listResult.error);

    final now = DateTime.now();
    final expired = listResult.data.where((c) =>
        c.status == ChallengeStatus.active &&
        c.weekEnd != null &&
        c.weekEnd!.isBefore(now));

    final reports = <ClosedChallengeReport>[];
    for (final summary in expired) {
      // `list()` does not fetch challenge_completions, so the summary's
      // completions list is empty. Pull the full detail before scoring,
      // otherwise both sides count every past day as failed → always tie.
      final detailResult = await _repository.getDetail(summary.id);
      if (detailResult.isFailure) continue;
      final challenge = detailResult.data;

      final myFails = ChallengeProgress.failedDayCount(
        challenge: challenge,
        userId: myUserId,
        now: now,
      );
      final opponentFails = ChallengeProgress.failedDayCount(
        challenge: challenge,
        userId: challenge.opponent.id,
        now: now,
      );

      String? winnerId;
      String? loserId;
      bool isTie = false;
      ClosedChallengeOutcome outcome;

      if (myFails < opponentFails) {
        winnerId = myUserId;
        loserId = challenge.opponent.id;
        outcome = ClosedChallengeOutcome.iWon;
      } else if (myFails > opponentFails) {
        winnerId = challenge.opponent.id;
        loserId = myUserId;
        outcome = ClosedChallengeOutcome.iLost;
      } else {
        isTie = true;
        outcome = ClosedChallengeOutcome.tie;
      }

      final closeResult = await _repository.closeChallenge(
        challengeId: challenge.id,
        winnerId: winnerId,
        loserId: loserId,
        isTie: isTie,
      );

      // Lost the race? Skip silently — the other client closed it.
      if (closeResult.isFailure) continue;

      reports.add(ClosedChallengeReport(
        challenge: closeResult.data,
        outcome: outcome,
      ));
    }

    return Result.success(reports);
  }
}
