import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/constants/app_constants.dart';
import 'package:quiz_app/core/theme/app_colors.dart';
import 'package:quiz_app/core/utils/result.dart';
import 'package:quiz_app/data/repositories/quiz_remote_repository_impl.dart';
import 'package:quiz_app/presentation/providers/auth_provider.dart';
import 'package:quiz_app/presentation/providers/quiz_create_provider.dart';
import 'package:quiz_app/presentation/providers/quiz_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';
import 'package:quiz_app/presentation/widgets/app_widgets.dart';

/// Admin-only page for creating a new quiz or editing an existing one.
///
/// Pass [editQuizId] to enter edit mode — the form will pre-populate from
/// the cached quiz data and submit via [QuizCreateNotifier.updateQuiz].
///
/// Anti-Design signature moves:
///  (1) Accent-serif italic in the headline.
///  (3) Tilted stamp on section labels.
///  (5) Hairline crop ticks between sections.
///  (6) Gap swing throughout.
///
/// Uses [AppTopStrip], [AppSectionLabel], [AppMonoLabel], [AppErrorBanner]
/// from the shared widget library.
class QuizCreatePage extends ConsumerStatefulWidget {
  const QuizCreatePage({super.key, this.editQuizId});

  /// When non-null, the page operates in edit mode for this quiz ID.
  final String? editQuizId;

  @override
  ConsumerState<QuizCreatePage> createState() => _QuizCreatePageState();
}

class _QuizCreatePageState extends ConsumerState<QuizCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _passingScoreCtrl = TextEditingController(
    text: AppConstants.passingScorePercent.toStringAsFixed(0),
  );

  // Each question is represented as a map of controllers.
  final List<_QuestionControllers> _questions = [];

  bool _prefilled = false;

  bool get _isEditing => widget.editQuizId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _prefillFromSource();
    } else {
      _addQuestion(); // start with one empty question for create mode
    }
  }

  /// Pre-populates the form by fetching fresh data from the repository.
  ///
  /// Calls [ensureLoaded] first so we always read up-to-date data —
  /// this avoids the stale-cache race where a previous edit's
  /// delete+insert is still in-flight when the cache is re-read.
  void _prefillFromSource() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_prefilled || !mounted) return;
      _prefilled = true;

      // Always ensure the cache is fresh before reading — this guarantees
      // we never read a mid-update snapshot from a previous save's
      // delete+insert race.
      final repo = ref.read(quizRepositoryProvider);
      if (repo is QuizRemoteRepositoryImpl) repo.invalidate();
      try {
        await repo.ensureLoaded();
      } catch (_) {
        // Network error — fall back to a blank question.
        if (mounted) {
          setState(() {
            _questions.clear();
            _addQuestion();
          });
        }
        return;
      }

      if (!mounted) return;

      final result = ref.read(getQuizQuestionsProvider).call(widget.editQuizId!);
      switch (result) {
        case Success(:final value):
          _titleCtrl.text = value.title;
          _descCtrl.text = value.description;
          _passingScoreCtrl.text = value.passingScore.toStringAsFixed(0);
          setState(() {
            _questions.clear();
            for (final q in value.questions) {
              final ctrl = _QuestionControllers();
              ctrl.textCtrl.text = q.text;
              ctrl.explanationCtrl.text = q.explanation ?? '';
              for (var i = 0; i < q.options.length && i < 4; i++) {
                ctrl.optionCtrls[i].text = q.options[i];
              }
              ctrl.correctIndex = q.correctIndex;
              _questions.add(ctrl);
            }
            if (_questions.isEmpty) _addQuestion();
          });
        case FailureResult():
          // Quiz not found even after a fresh load — start with a blank form.
          setState(() {
            _questions.clear();
            _addQuestion();
          });
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _passingScoreCtrl.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() => _questions.add(_QuestionControllers()));
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) return; // keep at least one
    setState(() => _questions[index].dispose());
    setState(() => _questions.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final passingScore =
        double.tryParse(_passingScoreCtrl.text.trim()) ??
        AppConstants.passingScorePercent;

    // Build the payload
    final questions = _questions.asMap().entries.map((e) {
      final i = e.key;
      final q = e.value;
      return QuestionDraft(
        text: q.textCtrl.text.trim(),
        options: q.optionCtrls.map((c) => c.text.trim()).toList(),
        correctIndex: q.correctIndex,
        explanation: q.explanationCtrl.text.trim().isEmpty
            ? null
            : q.explanationCtrl.text.trim(),
        order: i,
      );
    }).toList();

    if (_isEditing) {
      await ref.read(quizCreateNotifierProvider.notifier).updateQuiz(
            quizId: widget.editQuizId!,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            passingScore: passingScore,
            questions: questions,
          );
    } else {
      await ref.read(quizCreateNotifierProvider.notifier).createQuiz(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            passingScore: passingScore,
            questions: questions,
          );
    }

    final state = ref.read(quizCreateNotifierProvider);
    if (state.errorMessage == null && mounted) {
      // Reload home state before navigating so the quiz card reflects the
      // updated question count immediately, without a stale-cache flash.
      await ref.read(homeNotifierProvider.notifier).load();
      if (mounted) context.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;

    // Guard — non-admins should never reach this page, but just in case.
    if (user == null || !user.isAdmin) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Text(
            'ACCESS DENIED.',
            style: GoogleFonts.spaceMono(fontSize: 14, color: AppColors.alarm),
          ),
        ),
      );
    }

    final createState = ref.watch(quizCreateNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Shared top strip ──────────────────────────────────────
            AppTopStrip(
              onBack: () => context.go(AppRouter.home),
              title: 'ADMIN',
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Headline (signature move 1)
                            _Headline(isEditing: _isEditing),
                            const SizedBox(height: AppColors.nudge * 2),
                            // ── Shared AppSectionLabel ────────────────
                            const AppSectionLabel(label: 'QUIZ INFO'),
                            const SizedBox(height: AppColors.nudge),
                            // ── Shared AppMonoLabel ───────────────────
                            const AppMonoLabel('TITLE'),
                            const SizedBox(height: AppColors.gapTight),
                            _CreateField(
                              controller: _titleCtrl,
                              hint: 'e.g. Advanced Flutter',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: AppColors.nudge),
                            const AppMonoLabel('DESCRIPTION'),
                            const SizedBox(height: AppColors.gapTight),
                            _CreateField(
                              controller: _descCtrl,
                              hint: 'Short description of the quiz',
                              maxLines: 3,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: AppColors.nudge),
                            const AppMonoLabel('PASSING SCORE (%)'),
                            const SizedBox(height: AppColors.gapTight),
                            _CreateField(
                              controller: _passingScoreCtrl,
                              hint: '60',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final n = double.tryParse(v?.trim() ?? '');
                                if (n == null || n < 0 || n > 100) {
                                  return 'Enter a number between 0 and 100';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppColors.nudge * 2),
                            const AppSectionLabel(label: 'QUESTIONS'),
                          ],
                        ),
                      ),
                    ),
                    // Question cards
                    SliverList.builder(
                      itemCount: _questions.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _QuestionCard(
                          index: i,
                          controllers: _questions[i],
                          canRemove: _questions.length > 1,
                          onRemove: () => _removeQuestion(i),
                          onCorrectChanged: (idx) => setState(
                              () => _questions[i].correctIndex = idx),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: OutlinedButton(
                          onPressed: _addQuestion,
                          child: const Text('+ ADD QUESTION'),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (createState.errorMessage != null) ...[
                              AppErrorBanner(createState.errorMessage!),
                              const SizedBox(height: AppColors.nudge),
                            ],
                            FilledButton(
                              onPressed: createState.loading ? null : _submit,
                              child: createState.loading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: AppColors.borderFrame,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    )
                                  : Text(_isEditing ? 'SAVE CHANGES' : 'PUBLISH QUIZ'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Headline ───────────────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  const _Headline({required this.isEditing});
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final displaySize =
        (screenW / 6.0).clamp(AppColors.displayMin, AppColors.displayMax);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing ? 'EDIT' : 'CREATE',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: displaySize,
            fontWeight: FontWeight.w800,
            height: AppColors.displayLeading,
            letterSpacing: -2.0,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        // Accent-serif italic (signature move 1)
        Text(
          'Quiz',
          style: GoogleFonts.instrumentSerif(
            fontSize: displaySize * 0.95,
            fontStyle: FontStyle.italic,
            height: AppColors.displayLeading,
            letterSpacing: -1.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Create field ───────────────────────────────────────────────────────────

class _CreateField extends StatelessWidget {
  const _CreateField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.instrumentSans(
        fontSize: AppColors.bodySize,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.instrumentSans(
          fontSize: AppColors.bodySize,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: AppColors.borderRule),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: AppColors.borderFrame),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide:
              BorderSide(color: AppColors.alarm, width: AppColors.borderRule),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide:
              BorderSide(color: AppColors.alarm, width: AppColors.borderFrame),
        ),
        errorStyle: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.alarm),
      ),
      validator: validator,
    );
  }
}

// ── Question card ──────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.controllers,
    required this.canRemove,
    required this.onRemove,
    required this.onCorrectChanged,
  });

  final int index;
  final _QuestionControllers controllers;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<int> onCorrectChanged;

  @override
  Widget build(BuildContext context) {
    final indexStr = (index + 1).toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: AppColors.borderRule),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              Text(
                'Q$indexStr',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: Text(
                    'REMOVE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      letterSpacing: 1.5,
                      color: AppColors.alarm,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppColors.nudge),
          AppMonoLabel('QUESTION TEXT'),
          const SizedBox(height: AppColors.gapTight),
          _CreateField(
            controller: controllers.textCtrl,
            hint: 'Enter the question',
            maxLines: 2,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppColors.nudge),
          AppMonoLabel('OPTIONS  (tap circle to mark correct answer)'),
          const SizedBox(height: AppColors.gapTight),
          ...List.generate(4, (i) {
            final letter = String.fromCharCode(65 + i);
            final isCorrect = controllers.correctIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppColors.gapTight),
              child: Row(
                children: [
                  // Correct answer selector
                  GestureDetector(
                    onTap: () => onCorrectChanged(i),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isCorrect ? AppColors.acid : Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: AppColors.borderRule,
                        ),
                      ),
                      child: isCorrect
                          ? Icon(Icons.check,
                              size: 14, color: Theme.of(context).colorScheme.onSurface)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$letter.',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CreateField(
                      controller: controllers.optionCtrls[i],
                      hint: 'Option $letter',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppColors.gapTight),
          AppMonoLabel('EXPLANATION (optional)'),
          const SizedBox(height: AppColors.gapTight),
          _CreateField(
            controller: controllers.explanationCtrl,
            hint: 'Why is this the correct answer?',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ── Question controllers holder ────────────────────────────────────────────

class _QuestionControllers {
  final textCtrl = TextEditingController();
  final explanationCtrl = TextEditingController();
  final optionCtrls = List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;

  void dispose() {
    textCtrl.dispose();
    explanationCtrl.dispose();
    for (final c in optionCtrls) {
      c.dispose();
    }
  }
}

