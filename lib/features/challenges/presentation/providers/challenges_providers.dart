import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dinovigilo/core/providers/core_providers.dart';
import 'package:dinovigilo/features/auth/presentation/providers/auth_providers.dart';
import 'package:dinovigilo/features/challenges/data/datasources/challenges_remote_datasource.dart';
import 'package:dinovigilo/features/challenges/data/repositories/challenges_repository_impl.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/repositories/challenges_repository.dart';
import 'package:dinovigilo/features/challenges/domain/usecases/accept_challenge.dart';
import 'package:dinovigilo/features/challenges/domain/usecases/apply_my_penalty.dart';
import 'package:dinovigilo/features/challenges/domain/usecases/cancel_challenge.dart';
import 'package:dinovigilo/features/challenges/domain/usecases/close_expired_challenges.dart';
import 'package:dinovigilo/features/challenges/domain/usecases/create_challenge.dart';
import 'package:dinovigilo/features/challenges/domain/usecases/get_challenge_detail.dart';
import 'package:dinovigilo/features/challenges/domain/usecases/list_challenges.dart';
import 'package:dinovigilo/features/challenges/domain/usecases/mark_completion.dart';
import 'package:dinovigilo/features/challenges/domain/usecases/reject_challenge.dart';
import 'package:dinovigilo/features/objectives/presentation/providers/objective_providers.dart';
import 'package:dinovigilo/features/settings/presentation/providers/settings_providers.dart';
import 'package:dinovigilo/features/sprint/presentation/providers/sprint_providers.dart';

part 'challenges_providers.g.dart';

@Riverpod(keepAlive: true)
Future<ChallengesRemoteDatasource> challengesRemoteDatasource(
  ChallengesRemoteDatasourceRef ref,
) async {
  final auth = await ref.watch(authRemoteDatasourceProvider.future);
  return ChallengesRemoteDatasource(auth.client);
}

@Riverpod(keepAlive: true)
Future<ChallengesRepository> challengesRepository(
  ChallengesRepositoryRef ref,
) async {
  final remote = await ref.watch(challengesRemoteDatasourceProvider.future);
  final analytics = ref.watch(analyticsServiceProvider);
  return ChallengesRepositoryImpl(remote, analytics);
}

@riverpod
Future<ListChallengesUseCase> listChallengesUseCase(
  ListChallengesUseCaseRef ref,
) async {
  final repo = await ref.watch(challengesRepositoryProvider.future);
  return ListChallengesUseCase(repo);
}

@riverpod
Future<GetChallengeDetailUseCase> getChallengeDetailUseCase(
  GetChallengeDetailUseCaseRef ref,
) async {
  final repo = await ref.watch(challengesRepositoryProvider.future);
  return GetChallengeDetailUseCase(repo);
}

@riverpod
Future<CreateChallengeUseCase> createChallengeUseCase(
  CreateChallengeUseCaseRef ref,
) async {
  final repo = await ref.watch(challengesRepositoryProvider.future);
  return CreateChallengeUseCase(repo);
}

@riverpod
Future<AcceptChallengeUseCase> acceptChallengeUseCase(
  AcceptChallengeUseCaseRef ref,
) async {
  final repo = await ref.watch(challengesRepositoryProvider.future);
  return AcceptChallengeUseCase(repo);
}

@riverpod
Future<RejectChallengeUseCase> rejectChallengeUseCase(
  RejectChallengeUseCaseRef ref,
) async {
  final repo = await ref.watch(challengesRepositoryProvider.future);
  return RejectChallengeUseCase(repo);
}

@riverpod
Future<CancelChallengeUseCase> cancelChallengeUseCase(
  CancelChallengeUseCaseRef ref,
) async {
  final repo = await ref.watch(challengesRepositoryProvider.future);
  return CancelChallengeUseCase(repo);
}

@riverpod
Future<MarkCompletionUseCase> markCompletionUseCase(
  MarkCompletionUseCaseRef ref,
) async {
  final repo = await ref.watch(challengesRepositoryProvider.future);
  return MarkCompletionUseCase(repo);
}

@riverpod
Future<CloseExpiredChallengesUseCase> closeExpiredChallengesUseCase(
  CloseExpiredChallengesUseCaseRef ref,
) async {
  final repo = await ref.watch(challengesRepositoryProvider.future);
  return CloseExpiredChallengesUseCase(repo);
}

@riverpod
Future<ApplyMyPenaltyUseCase> applyMyPenaltyUseCase(
  ApplyMyPenaltyUseCaseRef ref,
) async {
  final challengesRepo = await ref.watch(challengesRepositoryProvider.future);
  final objectivesRepo = ref.watch(objectiveRepositoryProvider);
  final sprintRepo = ref.watch(sprintRepositoryProvider);
  return ApplyMyPenaltyUseCase(challengesRepo, objectivesRepo, sprintRepo);
}

/// All challenges involving the current user. Refetch via
/// `ref.invalidate(challengesListProvider)`.
///
/// Watches `authSessionProvider` so that switching accounts on the same
/// device refetches: a `Challenge`'s `opponent` is computed relative to the
/// current authenticated user, so cached data from a previous account would
/// invert win/lose for the new one.
@riverpod
Future<List<Challenge>> challengesList(ChallengesListRef ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) return const [];

  final useCase = await ref.watch(listChallengesUseCaseProvider.future);
  final result = await useCase.execute();
  return result.when(
    success: (list) => list,
    failure: (failure) => throw failure,
  );
}

/// Detail (with objectives + completions) for a single challenge.
/// Auth-scoped for the same reason as [challengesList].
@riverpod
Future<Challenge> challengeDetail(
  ChallengeDetailRef ref,
  String challengeId,
) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    throw const _NotSignedInFailure();
  }

  final useCase = await ref.watch(getChallengeDetailUseCaseProvider.future);
  final result = await useCase.execute(challengeId);
  return result.when(
    success: (challenge) => challenge,
    failure: (failure) => throw failure,
  );
}

class _NotSignedInFailure implements Exception {
  const _NotSignedInFailure();
  @override
  String toString() => 'Not signed in';
}

/// Aggregated report from running the close + apply-penalty pipeline once on
/// app open. The UI watches this and surfaces a snackbar per entry.
class ChallengeLifecycleReport {
  const ChallengeLifecycleReport({
    required this.closures,
    required this.appliedPenalties,
    required this.unseenOutcomes,
  });

  final List<ClosedChallengeReport> closures;
  final List<AppliedPenaltyReport> appliedPenalties;

  /// Completed challenges whose outcome animation hasn't been shown to the
  /// current user yet. Source of truth for the dialog queue. Includes both
  /// freshly closed challenges (overlaps with [closures]) and previously
  /// completed challenges where the user was the winner — those wouldn't
  /// otherwise produce any client-side event.
  final List<Challenge> unseenOutcomes;

  bool get isEmpty =>
      closures.isEmpty && appliedPenalties.isEmpty && unseenOutcomes.isEmpty;
}

/// Runs the weekly-close + penalty-apply pipeline once. Watched by TodayScreen
/// at startup. Idempotent across runs and races: PB updateRules drop redundant
/// updates and `penaltyApplied` gates re-injection.
@riverpod
Future<ChallengeLifecycleReport> processChallengesLifecycle(
  ProcessChallengesLifecycleRef ref,
) async {
  final session = await ref.watch(authSessionProvider.future);
  final myUserId = session?.user.id;
  if (myUserId == null || myUserId.isEmpty) {
    return const ChallengeLifecycleReport(
      closures: [],
      appliedPenalties: [],
      unseenOutcomes: [],
    );
  }

  final closeUseCase =
      await ref.watch(closeExpiredChallengesUseCaseProvider.future);
  final applyUseCase = await ref.watch(applyMyPenaltyUseCaseProvider.future);
  final repo = await ref.watch(challengesRepositoryProvider.future);
  final settings = ref.read(settingsServiceProvider);

  final closeResult = await closeUseCase.execute(myUserId: myUserId);
  final closures = closeResult.isSuccess
      ? closeResult.data
      : const <ClosedChallengeReport>[];

  final applyResult = await applyUseCase.execute(myUserId: myUserId);
  final applied = applyResult.isSuccess
      ? applyResult.data
      : const <AppliedPenaltyReport>[];

  // List completed challenges and pick those whose outcome the user hasn't
  // acknowledged yet on this device. Mark them acknowledged eagerly so a
  // crash mid-dialog doesn't replay the animation forever — better to miss
  // it once than to loop.
  final listResult = await repo.list();
  final completedAll = listResult.isSuccess
      ? listResult.data.where((c) => c.status == ChallengeStatus.completed).toList()
      : const <Challenge>[];

  final acked = await settings.loadOutcomeAck(myUserId);
  final unseen = completedAll
      .where((c) => !acked.contains(c.id))
      .toList(growable: false);
  if (unseen.isNotEmpty) {
    final updated = {...acked, ...unseen.map((c) => c.id)};
    await settings.saveOutcomeAck(myUserId, updated);
  }

  // Refresh dependent caches so UI sees the newly closed challenges and any
  // freshly injected penalty objective on Today.
  if (closures.isNotEmpty || applied.isNotEmpty) {
    ref.invalidate(challengesListProvider);
  }

  return ChallengeLifecycleReport(
    closures: closures,
    appliedPenalties: applied,
    unseenOutcomes: unseen,
  );
}

/// Subscribes to PocketBase realtime events on `challenge_completions` for
/// [challengeId]. On every create/update/delete (including the user's own,
/// which is fine — invalidation is idempotent) it invalidates
/// [challengeDetailProvider] so the grid refetches with fresh completions.
///
/// The Future resolves once the subscription is active. Watch it from the
/// detail screen to keep it alive; auto-dispose tears it down on leave.
@riverpod
Future<void> challengeRealtime(
  ChallengeRealtimeRef ref,
  String challengeId,
) async {
  final auth = await ref.watch(authRemoteDatasourceProvider.future);
  final pb = auth.client;

  final unsubscribe =
      await pb.collection('challenge_completions').subscribe(
    '*',
    (e) {
      final cid = e.record?.getStringValue('challengeId');
      if (cid == challengeId) {
        ref.invalidate(challengeDetailProvider(challengeId));
      }
    },
    filter: 'challengeId = "$challengeId"',
  );

  ref.onDispose(() {
    // Fire-and-forget; PocketBase's unsubscribe returns a Future but we
    // don't care to await it during dispose.
    unsubscribe();
  });
}
