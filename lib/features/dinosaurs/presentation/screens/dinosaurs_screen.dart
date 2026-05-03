import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/features/dinosaurs/presentation/screens/collection_screen.dart';
import 'package:dinovigilo/features/dinosaurs/presentation/screens/incubator_screen.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';

/// Sub-tab index inside [DinosaursScreen]: 0 = Eggs, 1 = Collection.
final dinosaursSubTabProvider = StateProvider<int>((ref) => 0);

class DinosaursScreen extends ConsumerStatefulWidget {
  const DinosaursScreen({super.key});

  @override
  ConsumerState<DinosaursScreen> createState() => _DinosaursScreenState();
}

class _DinosaursScreenState extends ConsumerState<DinosaursScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: 2,
      vsync: this,
      initialIndex: ref.read(dinosaursSubTabProvider),
    );
    _controller.addListener(() {
      if (_controller.indexIsChanging) return;
      ref.read(dinosaursSubTabProvider.notifier).state = _controller.index;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(dinosaursSubTabProvider, (_, next) {
      if (_controller.index != next) {
        _controller.animateTo(next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.dinosaurs),
        bottom: TabBar(
          controller: _controller,
          tabs: [
            Tab(
              icon: const Icon(Icons.egg_outlined),
              text: context.l10n.incubator,
            ),
            Tab(
              icon: const Icon(Icons.catching_pokemon_outlined),
              text: context.l10n.collection,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: const [
          IncubatorScreen(),
          CollectionScreen(),
        ],
      ),
    );
  }
}
