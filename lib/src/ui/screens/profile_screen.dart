import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/profile.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/stats_provider.dart';
import '../../utils/number_format.dart';
import '../theme/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/custom_app_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  bool _didInitFromProfile = false;
  bool _hasChanges = false;
  bool _isSaving = false;

  late TabController _tabController;

  double _parseDecimal(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final profile = ref.read(appDataProvider).profile;
    _heightController = TextEditingController(
      text: profile.heightCm == 0 ? '' : profile.heightCm.toString(),
    );
    _weightController = TextEditingController(
      text: profile.weightKg == 0 ? '' : formatDecimalFr(profile.weightKg),
    );
    _heightController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(appDataProvider.select((s) => s.profile));
    final history = ref.watch(appDataProvider.select((s) => s.weightEntries));
    final stats = ref.watch(userStatsProvider);
    final streak = ref.watch(streakProvider);

    if (!_didInitFromProfile && profile.id != 'profile') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _heightController.text = profile.heightCm == 0 ? '' : profile.heightCm.toString();
        _weightController.text =
            profile.weightKg == 0 ? '' : formatDecimalFr(profile.weightKg);
        setState(() {
          _didInitFromProfile = true;
          _hasChanges = false;
        });
      });
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profil',
        subtitle: 'Gérez vos informations',
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _hasChanges
          ? SizedBox(
              width: MediaQuery.of(context).size.width - 32,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
              ),
            )
          : null,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                children: [
                  _userInfoCard(context, profile, streak),
                  const SizedBox(height: 16),
                  _socialCard(context),
                  const SizedBox(height: 16),
                  _profileTabs(context),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final index = _tabController.index;
                      if (index == 0) {
                        return Column(
                          children: [
                            _profileCard(context, profile),
                            const SizedBox(height: 16),
                            _weightChartCard(context, history),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _statsGrid(context, stats),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileTabs(BuildContext context) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(2),
        indicator: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: colors.textPrimary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(text: 'Informations'),
          Tab(text: 'Statistiques'),
        ],
      ),
    );
  }

  Widget _userInfoCard(BuildContext context, Profile profile, int streak) {
    final colors = context.themeColors;
    final userName = profile.name.isNotEmpty ? profile.name : 'Athlète';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.isDark
              ? [
                  const Color(0xFF6366F1).withValues(alpha: 0.15),
                  const Color(0xFF4F46E5).withValues(alpha: 0.1),
                ]
              : [
                  const Color(0xFF6366F1).withValues(alpha: 0.08),
                  const Color(0xFF818CF8).withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colors.isDark
              ? const Color(0xFF6366F1).withValues(alpha: 0.3)
              : const Color(0xFF6366F1).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: colors.isDark ? 0.2 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person,
              color: colors.primary,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre profil',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '$streak',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialCard(BuildContext context) {
    final colors = context.themeColors;
    final friendsState = ref.watch(friendsProvider);
    final notificationsState = ref.watch(notificationsProvider);

    return Row(
      children: [
        Expanded(
          child: _socialButton(
            context,
            colors,
            icon: Icons.people_outline,
            label: 'Amis',
            count: friendsState.friends.length,
            onTap: () => context.go('/friends'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _socialButton(
            context,
            colors,
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            count: notificationsState.unreadCount,
            onTap: () => context.go('/notifications'),
            showBadge: notificationsState.unreadCount > 0,
          ),
        ),
      ],
    );
  }

  Widget _socialButton(
    BuildContext context,
    ThemeColors colors, {
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: colors.primary, size: 32),
                    if (showBadge)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileCard(BuildContext context, Profile profile) {
    final colors = context.themeColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: colors.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Informations physiques',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _inputBlock(
                  label: 'Taille (cm)',
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  icon: Icons.height,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _inputBlock(
                  label: 'Poids (kg)',
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(BuildContext context, UserStats stats) {
    final hours = stats.totalMinutes ~/ 60;
    final minutesRemainder = stats.totalMinutes % 60;
    final avgMinutesLabel = '${formatDecimalFr(stats.avgMinutes)} min';
    final totalTimeLabel =
        hours > 0 ? '${hours}h ${minutesRemainder}m' : '${stats.totalMinutes} min';
    final volumeLabel = '${formatDecimalFr(stats.totalVolume)} kg';

    final statsItems = [
      _StatItem('Séances totales', stats.totalSessions.toString(), 'séances'),
      _StatItem('Temps total', totalTimeLabel, 'durée cumulée'),
      _StatItem('Durée moyenne', avgMinutesLabel, 'par séance'),
      _StatItem('Jours actifs', stats.activeDays.toString(), 'jours'),
      _StatItem('Exercices réalisés', stats.totalExercises.toString(), 'exercices'),
      _StatItem('Séries réalisées', stats.totalSets.toString(), 'séries'),
      _StatItem('Volume total', volumeLabel, 'charge totale'),
      _StatItem('Exercice favori', stats.topExercise ?? '—', 'le plus fait'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 680 ? 3 : 2;
        final isNarrow = constraints.maxWidth < 380;
        final ratio = isNarrow ? 2.8 : 2.3;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: ratio,
          children: [
            for (final stat in statsItems) _statCard(context, stat, isNarrow),
          ],
        );
      },
    );
  }

  Widget _statCard(BuildContext context, _StatItem stat, bool isNarrow) {
    final colors = context.themeColors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: isNarrow ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (stat.caption != null) ...[
            const SizedBox(height: 4),
            Text(
              stat.caption!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _weightChartCard(BuildContext context, List<WeightEntry> history) {
    final sorted = [...history]..sort((a, b) => a.dateIso.compareTo(b.dateIso));
    final colors = context.themeColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: colors.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.show_chart,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Courbe de poids',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sorted.isEmpty)
            Text(
              'Aucune mesure enregistree.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          final date = DateTime.tryParse(sorted[index].dateIso);
                          final label =
                              date == null ? '' : DateFormat('dd/MM').format(date);
                          return Text(label, style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      barWidth: 3,
                      color: Theme.of(context).colorScheme.primary,
                      dotData: const FlDotData(show: true),
                      spots: [
                        for (var i = 0; i < sorted.length; i++)
                          FlSpot(i.toDouble(), sorted[i].weightKg),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final notifier = ref.read(appDataProvider.notifier);
    final profile = ref.read(appDataProvider).profile;

    final height = int.tryParse(_heightController.text.trim()) ?? profile.heightCm;
    final weightText = _weightController.text.trim();
    final weight = weightText.isEmpty ? profile.weightKg : _parseDecimal(weightText);

    final updated = profile.copyWith(
      heightCm: height,
      weightKg: weight,
    );

    setState(() => _isSaving = true);
    try {
      await notifier.updateProfile(updated);
      if (weight > 0) {
        await notifier.addWeightEntry(weight);
      }
      if (!mounted) return;
      setState(() => _hasChanges = false);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().contains('FormatException')
          ? 'Réponse invalide du serveur. Vérifie l’API.'
          : 'Impossible de sauvegarder le profil.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  void _onFieldChanged() {
    _syncDirtyFlag(ref.read(appDataProvider).profile);
  }

  void _syncDirtyFlag(Profile profile) {
    if (!_didInitFromProfile) return;
    final height = int.tryParse(_heightController.text.trim()) ?? profile.heightCm;
    final weightText = _weightController.text.trim();
    final weight = weightText.isEmpty ? profile.weightKg : _parseDecimal(weightText);
    final hasChanges = height != profile.heightCm || weight != profile.weightKg;
    if (hasChanges != _hasChanges && mounted) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  Widget _inputBlock({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    IconData? icon,
  }) {
    final colors = context.themeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.cardBackgroundAlt,
            prefixIcon: icon != null
                ? Icon(icon, color: colors.textSecondary, size: 20)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: icon != null
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
                : const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

}

class _StatItem {
  const _StatItem(this.label, this.value, [this.caption]);

  final String label;
  final String value;
  final String? caption;
}
