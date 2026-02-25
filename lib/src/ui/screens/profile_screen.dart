import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/profile.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/number_format.dart';
import '../theme/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/custom_app_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _startTimerController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _didInitFromProfile = false;
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isPasswordSaving = false;

  double _parseDecimal(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    final profile = ref.read(appDataProvider).profile;
    _heightController = TextEditingController(
      text: profile.heightCm == 0 ? '' : profile.heightCm.toString(),
    );
    _weightController = TextEditingController(
      text: profile.weightKg == 0 ? '' : formatDecimalFr(profile.weightKg),
    );
    _startTimerController = TextEditingController(
      text: profile.startTimerSeconds.toString(),
    );
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _heightController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _startTimerController.addListener(_onFieldChanged);
    _currentPasswordController.addListener(_onPasswordFieldChanged);
    _newPasswordController.addListener(_onPasswordFieldChanged);
    _confirmPasswordController.addListener(_onPasswordFieldChanged);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _startTimerController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(appDataProvider).profile;
    final history = ref.watch(appDataProvider).weightEntries;

    if (!_didInitFromProfile && profile.id != 'profile') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _heightController.text = profile.heightCm == 0 ? '' : profile.heightCm.toString();
        _weightController.text =
            profile.weightKg == 0 ? '' : formatDecimalFr(profile.weightKg);
        _startTimerController.text = profile.startTimerSeconds.toString();
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                _userInfoCard(context, profile),
                const SizedBox(height: 16),
                _socialCard(context),
                const SizedBox(height: 24),
                _profileCard(context, profile),
                const SizedBox(height: 24),
                _weightChartCard(context, history),
                const SizedBox(height: 24),
                _settingsCard(context),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userInfoCard(BuildContext context, Profile profile) {
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
          Text(
            'Informations physiques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _inputBlock(
                  label: 'Taille (cm)',
                  controller: _heightController,
                  keyboardType: TextInputType.number,
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: const Text('Se deconnecter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(BuildContext context) {
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
          Text(
            'Paramètres',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          _themeToggle(context),
          const SizedBox(height: 16),
          _inputBlock(
            label: 'Timer de départ (s)',
            controller: _startTimerController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Text(
            'Mot de passe',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          _inputBlock(
            label: 'Mot de passe actuel',
            controller: _currentPasswordController,
            keyboardType: TextInputType.text,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          _inputBlock(
            label: 'Nouveau mot de passe',
            controller: _newPasswordController,
            keyboardType: TextInputType.text,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          _inputBlock(
            label: 'Confirmer le nouveau mot de passe',
            controller: _confirmPasswordController,
            keyboardType: TextInputType.text,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: FilledButton(
              onPressed: _canSavePassword && !_isPasswordSaving ? _savePassword : null,
              child: Text(_isPasswordSaving ? 'Enregistrement...' : 'Mettre à jour'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeToggle(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mode sombre',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: isDarkMode,
            onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
          ),
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
          Text(
            'Courbe de poids',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
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
    final startTimerSeconds =
        int.tryParse(_startTimerController.text.trim()) ?? profile.startTimerSeconds;

    final updated = profile.copyWith(
      heightCm: height,
      weightKg: weight,
      startTimerSeconds: startTimerSeconds.clamp(0, 60),
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

  void _onPasswordFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _canSavePassword {
    final current = _currentPasswordController.text.trim();
    final next = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    if (current.isEmpty || next.isEmpty || confirm.isEmpty) return false;
    return true;
  }

  Future<void> _savePassword() async {
    final current = _currentPasswordController.text.trim();
    final next = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    if (next != confirm) {
      _showMessage('Les mots de passe ne correspondent pas.');
      return;
    }
    if (next.length < 8) {
      _showMessage('Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }
    setState(() => _isPasswordSaving = true);
    try {
      await ref.read(appDataProvider.notifier).changePassword(
            currentPassword: current,
            newPassword: next,
            confirmPassword: confirm,
          );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showMessage('Mot de passe mis à jour.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Impossible de mettre à jour le mot de passe.');
    } finally {
      if (!mounted) return;
      setState(() => _isPasswordSaving = false);
    }
  }

  void _syncDirtyFlag(Profile profile) {
    if (!_didInitFromProfile) return;
    final height = int.tryParse(_heightController.text.trim()) ?? profile.heightCm;
    final weightText = _weightController.text.trim();
    final weight = weightText.isEmpty ? profile.weightKg : _parseDecimal(weightText);
    final startTimerSeconds =
        int.tryParse(_startTimerController.text.trim()) ?? profile.startTimerSeconds;
    final hasChanges = height != profile.heightCm ||
        weight != profile.weightKg ||
        startTimerSeconds.clamp(0, 60) != profile.startTimerSeconds;
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
  }) {
    final colors = context.themeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.cardBackgroundAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
