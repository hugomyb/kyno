import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/push_notifications_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/push_notifications_types.dart';
import '../theme/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/custom_app_bar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _startTimerController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _didInitFromProfile = false;
  bool _timerDirty = false;
  bool _isSavingTimer = false;
  bool _isPasswordSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(appDataProvider).profile;
    _startTimerController = TextEditingController(
      text: profile.startTimerSeconds.toString(),
    );
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _startTimerController.addListener(_onTimerChanged);
    _currentPasswordController.addListener(_onPasswordFieldChanged);
    _newPasswordController.addListener(_onPasswordFieldChanged);
    _confirmPasswordController.addListener(_onPasswordFieldChanged);

    Future.microtask(() => ref.read(pushNotificationsProvider.notifier).refresh());

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated == true && !next.isAuthenticated && mounted) {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _startTimerController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(appDataProvider).profile;

    if (!_didInitFromProfile && profile.id != 'profile') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startTimerController.text = profile.startTimerSeconds.toString();
        setState(() {
          _didInitFromProfile = true;
          _timerDirty = false;
        });
      });
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Paramètres',
        subtitle: 'Préférences et sécurité',
        showBackButton: true,
        onBackPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/profile');
          }
        },
      ),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                _sectionCard(
                  context,
                  title: 'Apparence',
                  icon: Icons.palette_outlined,
                  child: _themeToggle(context),
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  context,
                  title: 'Séance',
                  icon: Icons.timer_outlined,
                  child: Column(
                    children: [
                      _inputBlock(
                        label: 'Timer de départ (s)',
                        controller: _startTimerController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        icon: Icons.timer_outlined,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _timerDirty && !_isSavingTimer ? _saveTimer : null,
                          child: Text(_isSavingTimer ? 'Enregistrement...' : 'Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  context,
                  title: 'Notifications push',
                  icon: Icons.notifications_active_outlined,
                  child: _pushNotificationsBlock(context),
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  context,
                  title: 'Mot de passe',
                  icon: Icons.lock_outline,
                  child: Column(
                    children: [
                      _inputBlock(
                        label: 'Mot de passe actuel',
                        controller: _currentPasswordController,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        icon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 12),
                      _inputBlock(
                        label: 'Nouveau mot de passe',
                        controller: _newPasswordController,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        icon: Icons.lock_reset,
                      ),
                      const SizedBox(height: 12),
                      _inputBlock(
                        label: 'Confirmer le nouveau mot de passe',
                        controller: _confirmPasswordController,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        icon: Icons.lock_reset,
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
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  context,
                  title: 'Compte',
                  icon: Icons.person_outline,
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Se déconnecter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.themeColors.error,
                        side: BorderSide(color: context.themeColors.error.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _buildVersionLabel(),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.themeColors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildVersionLabel() {
    const buildStamp = String.fromEnvironment('BUILD_STAMP', defaultValue: 'dev');
    return 'Version: $buildStamp';
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
                child: Icon(icon, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
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
          child,
        ],
      ),
    );
  }

  Widget _pushNotificationsBlock(BuildContext context) {
    final colors = context.themeColors;
    final state = ref.watch(pushNotificationsProvider);

    final status = switch (state.permission) {
      PushPermission.granted => 'Autorisees',
      PushPermission.denied => 'Refusees',
      PushPermission.prompt => 'A autoriser',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recevoir les notifications',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Switch.adaptive(
              value: state.isEnabled,
              onChanged: state.supported && !state.isLoading
                  ? (value) => ref.read(pushNotificationsProvider.notifier).toggle(value)
                  : null,
              activeColor: colors.primary,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          state.supported
              ? 'Statut: $status'
              : (state.supportReason ?? 'Non disponible sur ce navigateur'),
          style: TextStyle(
            fontSize: 13,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dernier check: ${state.lastCheckedAt ?? 'jamais'}',
          style: TextStyle(
            fontSize: 10,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: state.isLoading
                ? null
                : () => ref.read(pushNotificationsProvider.notifier).refresh(),
            child: const Text('Relancer diagnostic'),
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 6),
          Text(
            state.error!,
            style: TextStyle(
              fontSize: 12,
              color: colors.error,
            ),
          ),
        ],
        if (state.diagnostics != null) ...[
          const SizedBox(height: 8),
          Text(
            'Diag: notif=${state.diagnostics!.notificationsSupported ? 'ok' : 'no'} | '
            'sw=${state.diagnostics!.serviceWorkerSupported ? 'ok' : 'no'} | '
            'ready=${state.diagnostics!.serviceWorkerReady ? 'ok' : 'no'} | '
            'push=${state.diagnostics!.pushManagerSupported ? 'ok' : 'no'}',
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
            ),
          ),
          if (state.diagnostics!.serviceWorkerError != null &&
              state.diagnostics!.serviceWorkerError!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'SW error: ${state.diagnostics!.serviceWorkerError}',
              style: TextStyle(
                fontSize: 10,
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ],
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

  void _onTimerChanged() {
    final profile = ref.read(appDataProvider).profile;
    final startTimerSeconds =
        int.tryParse(_startTimerController.text.trim()) ?? profile.startTimerSeconds;
    final dirty = startTimerSeconds.clamp(0, 60) != profile.startTimerSeconds;
    if (dirty != _timerDirty && mounted) {
      setState(() => _timerDirty = dirty);
    }
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

  Future<void> _saveTimer() async {
    final profile = ref.read(appDataProvider).profile;
    final startTimerSeconds =
        int.tryParse(_startTimerController.text.trim()) ?? profile.startTimerSeconds;
    final updated = profile.copyWith(
      startTimerSeconds: startTimerSeconds.clamp(0, 60),
    );
    setState(() => _isSavingTimer = true);
    try {
      await ref.read(appDataProvider.notifier).updateProfile(updated);
      if (!mounted) return;
      setState(() => _timerDirty = false);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Impossible de sauvegarder le timer.');
    } finally {
      if (!mounted) return;
      setState(() => _isSavingTimer = false);
    }
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
