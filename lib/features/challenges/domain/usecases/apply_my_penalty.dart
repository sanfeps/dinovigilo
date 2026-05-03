import 'package:uuid/uuid.dart';

import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/repositories/challenges_repository.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/objectives/domain/repositories/objective_repository.dart';
import 'package:dinovigilo/features/sprint/domain/entities/day_objective_mapping.dart';
import 'package:dinovigilo/features/sprint/domain/entities/sprint.dart';
import 'package:dinovigilo/features/sprint/domain/repositories/sprint_repository.dart';

class AppliedPenaltyReport {
  const AppliedPenaltyReport({
    required this.challenge,
    required this.penaltyTitle,
  });

  final Challenge challenge;
  final String penaltyTitle;
}

/// For every completed challenge where I am the loser and `penaltyApplied` is
/// still false, materializes the penalty as a local objective:
///   - Creates an Objective with isPenalty=true, expiresAt=now+7d.
///   - Maps it to all 7 weekdays of the active sprint, creating one if none
///     exists.
///   - Flips `penaltyApplied=true` on PB so the next run is a no-op.
class ApplyMyPenaltyUseCase {
  ApplyMyPenaltyUseCase(
    this._challengesRepo,
    this._objectivesRepo,
    this._sprintRepo,
  );

  final ChallengesRepository _challengesRepo;
  final ObjectiveRepository _objectivesRepo;
  final SprintRepository _sprintRepo;

  static const _uuid = Uuid();
  static const _penaltyDays = 7;

  Future<Result<List<AppliedPenaltyReport>>> execute({
    required String myUserId,
  }) async {
    final listResult = await _challengesRepo.list();
    if (listResult.isFailure) return Result.failure(listResult.error);

    final pending = listResult.data.where((c) =>
        c.status == ChallengeStatus.completed &&
        !c.isTie &&
        c.loserId == myUserId &&
        !c.penaltyApplied);

    final reports = <AppliedPenaltyReport>[];
    for (final challenge in pending) {
      final injected = await _injectPenalty(challenge);
      if (injected.isFailure) continue;

      final markResult = await _challengesRepo.markPenaltyApplied(challenge.id);
      // If we wrote the local penalty but couldn't flip the flag (network),
      // the next run would re-inject. Acceptable — the user just gets the
      // penalty applied once per run until PB is reachable.
      if (markResult.isFailure) continue;

      reports.add(AppliedPenaltyReport(
        challenge: markResult.data,
        penaltyTitle: injected.data,
      ));
    }

    return Result.success(reports);
  }

  Future<Result<String>> _injectPenalty(Challenge challenge) async {
    final now = DateTime.now();
    final expiresAt = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: _penaltyDays));

    final objective = Objective(
      id: _uuid.v4(),
      title: challenge.penaltyObjective,
      createdAt: now,
      isPenalty: true,
      expiresAt: expiresAt,
    );

    final createResult = await _objectivesRepo.create(objective);
    if (createResult.isFailure) return Result.failure(createResult.error);

    final mappings = List.generate(
      7,
      (weekdayIndex) => DayObjectiveMapping(
        id: _uuid.v4(),
        dayOfSprint: weekdayIndex,
        objectiveId: objective.id,
      ),
    );

    final activeSprintResult = await _sprintRepo.getActiveSprint();
    if (activeSprintResult.isFailure) {
      return Result.failure(activeSprintResult.error);
    }

    final activeSprint = activeSprintResult.data;
    if (activeSprint != null) {
      final addResult =
          await _sprintRepo.addMappings(activeSprint.id, mappings);
      if (addResult.isFailure) return Result.failure(addResult.error);
    } else {
      final newSprint = Sprint(
        id: _uuid.v4(),
        dayMappings: mappings,
        isActive: true,
      );
      final createSprintResult = await _sprintRepo.create(newSprint);
      if (createSprintResult.isFailure) {
        return Result.failure(createSprintResult.error);
      }
    }

    return Result.success(objective.title);
  }
}
