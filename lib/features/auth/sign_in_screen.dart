import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass/gradient_pill_button.dart';
import '../home/widgets/glass_card.dart';
import '../home/widgets/mesh_gradient_background.dart';
import 'auth_providers.dart';

/// Glass-themed sign-in / sign-up screen.
///
/// First impression of the app for new users. Matches the mesh-glass
/// vocabulary used everywhere else so the moment-of-decision (sign in
/// vs skip) feels like part of the same premium product.
///
/// Layout (top to bottom):
///
///  1. Hero amber-on-glass medal disc with the RecapCoach mark.
///  2. 28-32 dp display title: "Welcome back" / "Create your account".
///  3. Single muted subtitle line.
///  4. `GlassCard` holding the email + password fields, the inline
///     error chip (when present), and the primary `GradientPillButton`
///     CTA. The "Already have an account? / New here?" toggle lives
///     directly under the CTA as a quiet `TextButton`.
///  5. "or" divider.
///  6. Glass-pill "Continue with Google" outlined button.
///  7. Quiet "Skip — try it first" text button (anonymous sign-in).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _isSignUp = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _emailFlow() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(authRepositoryProvider);
    final analytics = ref.read(analyticsProvider);
    analytics.track(AnalyticsEvents.signInStart, {'method': 'email'});
    try {
      if (_isSignUp) {
        await repo.signUpWithEmail(_email.text.trim(), _password.text);
      } else {
        await repo.signInWithEmail(_email.text.trim(), _password.text);
      }
      analytics.track(AnalyticsEvents.signInSuccess, {'method': 'email'});
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
      analytics.track(
        AnalyticsEvents.signInFail,
        {'method': 'email', 'code': e.code},
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleFlow() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(authRepositoryProvider);
    final analytics = ref.read(analyticsProvider);
    analytics.track(AnalyticsEvents.signInStart, {'method': 'google'});
    try {
      final user = await repo.signInWithGoogle();
      if (user != null) {
        analytics.track(AnalyticsEvents.signInSuccess, {'method': 'google'});
      }
    } catch (e) {
      setState(() => _error = e.toString());
      analytics.track(AnalyticsEvents.signInFail, {'method': 'google'});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _anonymousFlow() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInAnonymously();
      ref.read(analyticsProvider).track(
        AnalyticsEvents.signInSuccess,
        {'method': 'anonymous'},
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted =
        isDark ? const Color(0xFFD8D4CB) : AppColors.slate500;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MeshGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandMedal(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _isSignUp ? 'Create your account' : 'Welcome back',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: fg,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to sync your data across devices.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fgMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ---- Email + password card ----
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _GlassTextField(
                          controller: _email,
                          label: 'Email',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          fg: fg,
                          fgMuted: fgMuted,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _GlassTextField(
                          controller: _password,
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: true,
                          fg: fg,
                          fgMuted: fgMuted,
                          isDark: isDark,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _ErrorChip(message: _error!),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        GradientPillButton(
                          onPressed: _busy ? null : _emailFlow,
                          loading: _busy,
                          expanded: true,
                          label: _isSignUp ? 'Sign up' : 'Sign in',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp
                                ? 'Already have an account? Sign in'
                                : 'New here? Create an account',
                            style: TextStyle(
                              color: fgMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ---- "or" divider ----
                  _OrDivider(fgMuted: fgMuted, isDark: isDark),
                  const SizedBox(height: AppSpacing.lg),

                  // ---- Google sign-in (glass outlined pill) ----
                  _GoogleButton(
                    onPressed: _busy ? null : _googleFlow,
                    fg: fg,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ---- Skip / anonymous ----
                  Center(
                    child: TextButton(
                      onPressed: _busy ? null : _anonymousFlow,
                      child: Text(
                        'Skip — try it first',
                        style: TextStyle(
                          color: fgMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Brand medal -- amber-on-glass focal point at the top of the screen
// =============================================================================

class _BrandMedal extends StatelessWidget {
  const _BrandMedal();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.amber600, AppColors.amber400],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber400.withValues(alpha: 0.40),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.graphic_eq_rounded,
          color: Colors.white,
          size: 42,
        ),
      ),
    );
  }
}

// =============================================================================
// Glass text field -- mesh-aware TextField wrapper
// =============================================================================

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.fg,
    required this.fgMuted,
    required this.isDark,
    this.keyboardType,
    this.obscureText = false,
    this.autocorrect = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color fg;
  final Color fgMuted;
  final bool isDark;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.55);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: autocorrect,
      style: TextStyle(color: fg, fontSize: 15),
      cursorColor: AppColors.amber600,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: fgMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: fgMuted, size: 20),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.amber600,
            width: 1.5,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
      ),
    );
  }
}

// =============================================================================
// Error chip -- inline red-tinted error message
// =============================================================================

class _ErrorChip extends StatelessWidget {
  const _ErrorChip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.error600.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error600.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error600,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// "or" divider -- two hairlines with a centred label
// =============================================================================

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.fgMuted, required this.isDark});

  final Color fgMuted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'or',
            style: TextStyle(
              color: fgMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1)),
      ],
    );
  }
}

// =============================================================================
// Google button -- glass-outlined pill with G icon
// =============================================================================

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.onPressed,
    required this.fg,
    required this.isDark,
  });

  final VoidCallback? onPressed;
  final Color fg;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.55);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.10);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Opacity(
          opacity: onPressed == null ? 0.55 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.g_mobiledata_rounded, color: fg, size: 28),
                const SizedBox(width: 6),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
