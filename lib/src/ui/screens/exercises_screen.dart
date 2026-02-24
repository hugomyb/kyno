import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/exercise.dart';
import '../../providers/app_data_provider.dart';
import '../../services/api_exceptions.dart';
import '../theme/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/custom_app_bar.dart';

enum ExerciseFilter { all, mine, global }

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  List<Exercise>? _remoteResults;
  bool _searching = false;
  ExerciseFilter _filter = ExerciseFilter.all;
  Future<List<String>>? _categoriesFuture;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(appDataProvider).exercises;
    final query = _searchController.text.trim();
    final baseList = query.isEmpty ? exercises : (_remoteResults ?? <Exercise>[]);
    final sortedBase = query.isEmpty
        ? (List<Exercise>.from(baseList)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())))
        : baseList;
    final filtered = _applyFilter(sortedBase);
    final totalCount = query.isEmpty ? exercises.length : baseList.length;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Exercices',
        subtitle: '${exercises.length} exercice${exercises.length > 1 ? 's' : ''}',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel exercice'),
      ),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: _runSearch,
                          decoration: InputDecoration(
                            labelText: 'Rechercher un exercice',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _searchController.clear();
                                      _runSearch('');
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _filterRow(),
                        const SizedBox(height: 16),
                        if (_searching)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: LinearProgressIndicator(),
                          ),
                        _summaryRow(filtered.length, totalCount),
                        const SizedBox(height: 8),
                        if (query.isEmpty && exercises.isEmpty)
                          const Text('Aucun exercice disponible.')
                        else if (filtered.isEmpty)
                          const Text('Aucun exercice ne correspond à ta recherche.'),
                      ],
                    ),
                  ),
                ),
                if (filtered.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) => _exerciseCard(filtered[index]),
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemCount: filtered.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Exercise> _applyFilter(List<Exercise> base) {
    switch (_filter) {
      case ExerciseFilter.mine:
        return base.where((e) => !e.isGlobal).toList();
      case ExerciseFilter.global:
        return base.where((e) => e.isGlobal).toList();
      case ExerciseFilter.all:
        return base;
    }
  }

  void _runSearch(String value) {
    final query = value.trim();
    _searchTimer?.cancel();
    if (query.isEmpty) {
      setState(() {
        _remoteResults = null;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _searchTimer = Timer(const Duration(milliseconds: 350), () async {
      final results = await ref.read(appDataProvider.notifier).searchExercises(query);
      if (!mounted) return;
      setState(() {
        _remoteResults = results;
        _searching = false;
      });
    });
  }

  Widget _filterRow() {
    return Row(
      children: [
        Expanded(
          child: _filterChip(ExerciseFilter.all, 'Tous'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _filterChip(ExerciseFilter.global, 'Communs'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _filterChip(ExerciseFilter.mine, 'Mes exos'),
        ),
      ],
    );
  }

  Widget _filterChip(ExerciseFilter filter, String label) {
    final colors = context.themeColors;
    final selected = _filter == filter;
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: () => setState(() => _filter = filter),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? colors.primary : colors.cardBackground,
          foregroundColor: selected
              ? (colors.isDark ? colors.textPrimary : Colors.white)
              : colors.textPrimary,
          side: BorderSide(color: selected ? colors.primary : colors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _summaryRow(int count, int total) {
    final colors = context.themeColors;
    return Row(
      children: [
        Text(
          '$count / $total exercices',
          style: TextStyle(color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _exerciseCard(Exercise exercise) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: colors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.chipBackground(colors.primary),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.fitness_center,
              color: colors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (exercise.categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: exercise.categories.take(4).map(
                      (category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.chipBackground(colors.primary),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.chipBackground(colors.primary),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.history_outlined),
              color: colors.primary,
              tooltip: 'Voir l\'historique',
              onPressed: () => context.push(
                '/exercises/${exercise.id}/history?name=${Uri.encodeComponent(exercise.name)}',
              ),
            ),
          ),
          if (!exercise.isGlobal) ...[
            const SizedBox(width: 4),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                color: const Color(0xFFEF4444),
                onPressed: () =>
                    ref.read(appDataProvider.notifier).removeExercise(exercise.id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final nameController = TextEditingController();
    final selected = <String>{};
    final categoriesFuture =
        _categoriesFuture ??= ref.read(appDataProvider.notifier).fetchExerciseCategories();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          Text('Nouvel exercice',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: 'Nom'),
                          ),
                          const SizedBox(height: 12),
                          Text('Categories', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          FutureBuilder<List<String>>(
                            future: categoriesFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: LinearProgressIndicator(),
                                );
                              }
                              final allCategories = (snapshot.data ?? <String>[])
                                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                              if (allCategories.isEmpty) {
                                return const Text('Aucune categorie disponible.');
                              }
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: allCategories.map((category) {
                                  final isSelected = selected.contains(category);
                                  return FilterChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (value) {
                                      setModalState(() {
                                        if (value) {
                                          selected.add(category);
                                        } else {
                                          selected.remove(category);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) return;
                              try {
                                await ref.read(appDataProvider.notifier).addExercise(
                                      name,
                                      categories: selected.toList(),
                                    );
                                if (context.mounted) Navigator.of(context).pop();
                              } catch (error) {
                                if (!context.mounted) return;
                                String message = 'Erreur lors de la creation.';
                                if (error is ApiException) {
                                  message = error.message;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              }
                            },
                            child: const Text('Ajouter', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annuler', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
