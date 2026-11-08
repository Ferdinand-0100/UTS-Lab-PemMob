import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/constants/app_constants.dart';
import 'package:quiz_app/core/theme/app_colors.dart';
import 'package:quiz_app/domain/entities/app_user.dart';
import 'package:quiz_app/presentation/providers/auth_provider.dart';

/// Authentication page — handles both sign-in and registration.
///
/// Anti-Design signature moves active:
///  (1) Accent-serif italic word in the headline.
///  (3) Tilted mono stamp on the mode toggle strip.
///  (5) Hairline crop ticks above the form area.
///  (6) Gap swing throughout.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _adminCodeCtrl = TextEditingController();

  bool _isRegister = false;
  bool _registerAsAdmin = false;
  bool _showAdminCode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _displayNameCtrl.dispose();
    _adminCodeCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _registerAsAdmin = false;
      _showAdminCode = false;
      _formKey.currentState?.reset();
      _adminCodeCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isRegister) {
      UserRole role = UserRole.user;
      if (_registerAsAdmin) {
        if (_adminCodeCtrl.text.trim() != AppConstants.adminSecretCode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.alarm,
              content: Text(
                'INVALID ADMIN CODE.',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.paper,
                ),
              ),
            ),
          );
          return;
        }
        role = UserRole.admin;
      }
      await ref.read(authNotifierProvider.notifier).register(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            displayName: _displayNameCtrl.text.trim(),
            role: role,
          );
    } else {
      await ref.read(authNotifierProvider.notifier).signIn(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NavStrip(isRegister: _isRegister),
              _HeadlineBlock(isRegister: _isRegister),
              // gap swing: tight
              const SizedBox(height: AppColors.gapTight),
              _ModeToggleStrip(
                isRegister: _isRegister,
                onToggle: _toggleMode,
              ),
              // gap swing: wide
              const SizedBox(height: AppColors.nudge * 2),
              _CropTickDivider(),
              const SizedBox(height: AppColors.nudge),
              // Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isRegister) ...[
                        _MonoLabel('DISPLAY NAME'),
                        const SizedBox(height: AppColors.gapTight),
                        _AuthField(
                          controller: _displayNameCtrl,
                          hint: 'Your name',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: AppColors.nudge),
                      ],
                      _MonoLabel('EMAIL'),
                      const SizedBox(height: AppColors.gapTight),
                      _AuthField(
                        controller: _emailCtrl,
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppColors.nudge),
                      _MonoLabel('PASSWORD'),
                      const SizedBox(height: AppColors.gapTight),
                      _AuthField(
                        controller: _passwordCtrl,
                        hint: 'Min. 6 characters',
                        obscure: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.grid,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 6) return 'Min. 6 characters';
                          return null;
                        },
                      ),
                      // Admin section — register mode only
                      if (_isRegister) ...[
                        const SizedBox(height: AppColors.nudge),
                        _AdminToggleRow(
                          value: _registerAsAdmin,
                          onChanged: (v) => setState(() {
                            _registerAsAdmin = v;
                            _showAdminCode = v;
                            if (!v) _adminCodeCtrl.clear();
                          }),
                        ),
                        if (_showAdminCode) ...[
                          const SizedBox(height: AppColors.gapTight),
                          _MonoLabel('ADMIN CODE'),
                          const SizedBox(height: AppColors.gapTight),
                          _AuthField(
                            controller: _adminCodeCtrl,
                            hint: 'Enter secret code',
                            validator: (v) => _registerAsAdmin &&
                                    (v == null || v.isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ],
                      ],
                      const SizedBox(height: AppColors.nudge * 2),
                      // Error message
                      if (authState.errorMessage != null) ...[
                        Container(
                          color: AppColors.alarm,
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            authState.errorMessage!,
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              color: AppColors.paper,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppColors.nudge),
                      ],
                      // Submit button
                      FilledButton(
                        onPressed: authState.loading ? null : _submit,
                        child: authState.loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: AppColors.borderFrame,
                                  color: AppColors.ink,
                                ),
                              )
                            : Text(_isRegister ? 'REGISTER' : 'SIGN IN'),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav strip ──────────────────────────────────────────────────────────────

class _NavStrip extends StatelessWidget {
  const _NavStrip({required this.isRegister});
  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: AppColors.ink, width: AppColors.borderRule),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            'QUIZ MASTER',
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          Text(
            isRegister ? '02 REGISTER' : '01 SIGN IN',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Headline block ─────────────────────────────────────────────────────────

class _HeadlineBlock extends StatelessWidget {
  const _HeadlineBlock({required this.isRegister});
  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final displaySize =
        (screenW / 5.5).clamp(AppColors.displayMin, AppColors.displayMax);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRegister ? 'CREATE' : 'SIGN',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: displaySize,
              fontWeight: FontWeight.w800,
              height: AppColors.displayLeading,
              letterSpacing: -2.0,
              color: AppColors.ink,
            ),
          ),
          // Accent serif italic (signature move 1)
          Text(
            isRegister ? 'Account' : 'In',
            style: GoogleFonts.instrumentSerif(
              fontSize: displaySize * 0.95,
              fontStyle: FontStyle.italic,
              height: AppColors.displayLeading,
              letterSpacing: -1.5,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode toggle strip (signature move 3) ──────────────────────────────────

class _ModeToggleStrip extends StatelessWidget {
  const _ModeToggleStrip({
    required this.isRegister,
    required this.onToggle,
  });

  final bool isRegister;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.acid,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            isRegister
                ? 'ALREADY HAVE AN ACCOUNT?'
                : 'NO ACCOUNT YET?',
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          // Tilted stamp (signature move 3)
          GestureDetector(
            onTap: onToggle,
            child: ExcludeSemantics(
              child: Transform.rotate(
                angle: AppColors.angleStamp,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppColors.borderRule,
                    ),
                  ),
                  child: Text(
                    isRegister ? 'SIGN IN ->' : 'REGISTER ->',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Crop tick divider (signature move 5) ──────────────────────────────────

class _CropTickDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _tick(),
            Expanded(
              child: Container(
                height: AppColors.borderRule,
                color: AppColors.grid,
              ),
            ),
            _tick(),
          ],
        ),
      ),
    );
  }

  Widget _tick() {
    return SizedBox(
      width: 8,
      height: 8,
      child: CustomPaint(painter: _TickPainter()),
    );
  }
}

class _TickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grid
      ..strokeWidth = AppColors.borderRule
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Mono label ─────────────────────────────────────────────────────────────

class _MonoLabel extends StatelessWidget {
  const _MonoLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.spaceMono(
        fontSize: 9,
        letterSpacing: 2.0,
        color: AppColors.grid,
      ),
    );
  }
}

// ── Auth text field ────────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: GoogleFonts.instrumentSans(
        fontSize: AppColors.bodySize,
        color: AppColors.ink,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.instrumentSans(
          fontSize: AppColors.bodySize,
          color: AppColors.grid,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: AppColors.ink,
            width: AppColors.borderRule,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: AppColors.ink,
            width: AppColors.borderFrame,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: AppColors.alarm,
            width: AppColors.borderRule,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: AppColors.alarm,
            width: AppColors.borderFrame,
          ),
        ),
        errorStyle: GoogleFonts.spaceMono(
          fontSize: 10,
          color: AppColors.alarm,
        ),
      ),
      validator: validator,
    );
  }
}

// ── Admin toggle row ───────────────────────────────────────────────────────

class _AdminToggleRow extends StatelessWidget {
  const _AdminToggleRow({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value ? AppColors.bubblegum : AppColors.paper,
          border: Border.all(
            color: AppColors.ink,
            width: AppColors.borderRule,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value ? AppColors.ink : AppColors.paper,
                border: Border.all(
                  color: AppColors.ink,
                  width: AppColors.borderRule,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, size: 14, color: AppColors.paper)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              'REGISTER AS ADMIN',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
