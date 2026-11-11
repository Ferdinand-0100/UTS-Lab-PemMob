import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/constants/app_constants.dart';
import 'package:quiz_app/core/theme/app_colors.dart';
import 'package:quiz_app/domain/entities/app_user.dart';
import 'package:quiz_app/presentation/providers/auth_provider.dart';
import 'package:quiz_app/presentation/widgets/app_widgets.dart';

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
              backgroundColor: AppColors.btnRed,
              content: Text(
                'INVALID ADMIN CODE',
                style: GoogleFonts.silkscreen(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.shellLight,
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
      backgroundColor: AppShell.of(context).body,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Shell top strip ──────────────────────────────────────
            _ConsoleHeader(isRegister: _isRegister),

            // ── CRT screen body ──────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CrtBootScreen(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title on screen with blinking cursor
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              PhosphorText(
                                _isRegister ? 'CREATE ACCOUNT' : 'SIGN IN',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              const SizedBox(width: 6),
                              const BlinkingCursor(fontSize: 14),
                            ],
                          ),
                          const SizedBox(height: 4),
                          PhosphorText(
                            _isRegister
                                ? 'REGISTER A NEW PLAYER'
                                : 'ENTER YOUR CREDENTIALS',
                            fontSize: 8,
                            dim: true,
                          ),
                          const SizedBox(height: 20),
                          const PixelDivider(),
                          const SizedBox(height: 16),

                          // ── Fields ───────────────────────────────
                          if (_isRegister) ...[
                            const AppMonoLabel('DISPLAY NAME'),
                            const SizedBox(height: 6),
                            ConsoleTextField(
                              controller: _displayNameCtrl,
                              hint: 'Your name',
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                          ],

                          const AppMonoLabel('EMAIL'),
                          const SizedBox(height: 6),
                          ConsoleTextField(
                            controller: _emailCtrl,
                            hint: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (!v.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          const AppMonoLabel('PASSWORD'),
                          const SizedBox(height: 6),
                          ConsoleTextField(
                            controller: _passwordCtrl,
                            hint: 'Min 6 characters',
                            obscure: _obscurePassword,
                            isPassword: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (v.length < 6) return 'Min 6 chars';
                              return null;
                            },
                          ),

                          if (_isRegister) ...[
                            const SizedBox(height: 12),
                            _AdminToggle(
                              value: _registerAsAdmin,
                              onChanged: (v) => setState(() {
                                _registerAsAdmin = v;
                                if (!v) _adminCodeCtrl.clear();
                              }),
                            ),
                            if (_registerAsAdmin) ...[
                              const SizedBox(height: 10),
                              const AppMonoLabel('ADMIN CODE'),
                              const SizedBox(height: 6),
                              ConsoleTextField(
                                controller: _adminCodeCtrl,
                                hint: 'Secret code',
                                validator: (v) =>
                                    _registerAsAdmin && (v == null || v.isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                            ],
                          ],

                          const SizedBox(height: 20),
                          const PixelDivider(),
                          const SizedBox(height: 16),

                          if (authState.errorMessage != null) ...[
                            AppErrorBanner(authState.errorMessage!),
                            const SizedBox(height: 12),
                          ],

                          // ── Submit button ────────────────────────
                          authState.loading
                              ? _LoadingButton()
                              : PixelButton(
                                  label: _isRegister ? 'REGISTER' : 'SIGN IN',
                                  onPressed: _submit,
                                  color: AppColors.btnMagenta,
                                  textColor: AppColors.shellLight,
                                  fullWidth: true,
                                  fontSize: 11,
                                ),

                          const SizedBox(height: 16),

                          // ── Toggle mode ──────────────────────────
                          _ModeToggle(
                            isRegister: _isRegister,
                            onToggle: _toggleMode,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Shell footer badge ───────────────────────────────────
            _ShellFooter(),
          ],
        ),
      ),
    );
  }
}

// ── Console header ─────────────────────────────────────────────────

class _ConsoleHeader extends StatelessWidget {
  const _ConsoleHeader({required this.isRegister});
  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    final sh = AppShell.of(context);
    return Container(
      decoration: BoxDecoration(
        color: sh.strip,
        border: Border(
          bottom: BorderSide(color: sh.border, width: AppColors.borderFrame),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Power LED dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.phosphor,
              border: Border.all(color: sh.border, width: 1),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.phosphor.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'QUIZ MASTER  //  ${isRegister ? 'REGISTER' : 'SIGN IN'}',
              style: GoogleFonts.silkscreen(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: sh.onShell,
              ),
            ),
          ),
          Text(
            'V1.0',
            style: GoogleFonts.silkscreen(
              fontSize: 7,
              color: sh.strip.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Admin toggle ───────────────────────────────────────────────────

class _AdminToggle extends StatelessWidget {
  const _AdminToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: value ? AppColors.phosphorDim.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: value ? AppColors.phosphor : AppColors.phosphorDim,
            width: AppColors.borderRule,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: value ? AppColors.phosphor : Colors.transparent,
                border: Border.all(color: AppColors.phosphorDim, width: AppColors.borderRule),
              ),
              child: value
                  ? const Icon(Icons.check, size: 11, color: AppColors.crtBgDeep)
                  : null,
            ),
            const SizedBox(width: 10),
            PhosphorText(
              'REGISTER AS ADMIN',
              fontSize: 9,
              dim: !value,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mode toggle ────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isRegister, required this.onToggle});
  final bool isRegister;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.phosphorDim, width: AppColors.borderRule),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorText(
              isRegister ? 'HAVE AN ACCOUNT?  ' : 'NO ACCOUNT?  ',
              fontSize: 8,
              dim: true,
            ),
            PhosphorText(
              isRegister ? '> SIGN IN' : '> REGISTER',
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading button placeholder ─────────────────────────────────────

class _LoadingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.btnMagenta.withValues(alpha: 0.5),
        border: Border.all(color: AppColors.outline, width: AppColors.borderRule),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.shellLight,
            ),
          ),
          const SizedBox(width: 10),
          ShellText('PROCESSING...', fontSize: 9, color: AppColors.shellLight),
        ],
      ),
    );
  }
}

// ── Shell footer ───────────────────────────────────────────────────

class _ShellFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sh = AppShell.of(context);
    return Container(
      decoration: BoxDecoration(
        color: sh.strip,
        border: Border(
          top: BorderSide(color: sh.border, width: AppColors.borderRule),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'MADE BY FERDINAND  //  NIM 241401080',
            style: GoogleFonts.silkscreen(
              fontSize: 6,
              color: sh.body.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
