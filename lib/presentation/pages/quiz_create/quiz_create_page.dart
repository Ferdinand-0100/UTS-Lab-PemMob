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

class QuizCreatePage extends ConsumerStatefulWidget {
  const QuizCreatePage({super.key, this.editQuizId});
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
  final List<_QuestionControllers> _questions = [];
  bool _prefilled = false;

  bool get _isEditing => widget.editQuizId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _prefillFromSource();
    } else {
      _addQuestion();
    }
  }

  void _prefillFromSource() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_prefilled || !mounted) return;
      _prefilled = true;

      final repo = ref.read(quizRepositoryProvider);
      if (repo is QuizRemoteRepositoryImpl) repo.invalidate();
      try {
        await repo.ensureLoaded();
      } catch (_) {
        if (mounted) setState(() { _questions.clear(); _addQuestion(); });
        return;
      }
      if (!mounted) return;

      final result =
          ref.read(getQuizQuestionsProvider).call(widget.editQuizId!);
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
          setState(() { _questions.clear(); _addQuestion(); });
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _passingScoreCtrl.dispose();
    for (final q in _questions) q.dispose();
    super.dispose();
  }

  void _addQuestion() => setState(() => _questions.add(_QuestionControllers()));

  void _removeQuestion(int index) {
    if (_questions.length <= 1) return;
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final passingScore =
        double.tryParse(_passingScoreCtrl.text.trim()) ??
        AppConstants.passingScorePercent;

    final questions = _questions.asMap().entries.map((e) {
      final q = e.value;
      return QuestionDraft(
        text: q.textCtrl.text.trim(),
        options: q.optionCtrls.map((c) => c.text.trim()).toList(),
        correctIndex: q.correctIndex,
        explanation: q.explanationCtrl.text.trim().isEmpty
            ? null
            : q.explanationCtrl.text.trim(),
        order: e.key,
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
      await ref.read(homeNotifierProvider.notifier).load();
      if (mounted) {
        context.crtNavigate(
          label: 'PUBLISHING...',
          onDone: () => context.go(AppRouter.home),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null || !user.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.shell,
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: CrtScreen(
            child: Center(
              child: AppErrorBanner('ACCESS DENIED'),
            ),
          ),
        ),
      );
    }

    final createState = ref.watch(quizCreateNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.shell,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Shell top strip ──────────────────────────────────────
            AppTopStrip(
              onBack: () => context.crtNavigate(
                label: 'RETURNING...',
                onDone: () => context.go(AppRouter.home),
              ),
              title: _isEditing ? 'EDIT QUIZ' : 'CREATE QUIZ',
            ),

            // ── CRT screen form ──────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: CrtScreen(
                  padding: EdgeInsets.zero,
                  child: Form(
                    key: _formKey,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PhosphorText(
                                  _isEditing ? 'EDIT QUIZ' : 'NEW QUIZ',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                const SizedBox(height: 4),
                                PhosphorText(
                                  'ADMIN CONSOLE  //  QUIZ EDITOR',
                                  fontSize: 7,
                                  dim: true,
                                ),
                                const SizedBox(height: 14),
                                const PixelDivider(),
                                const SizedBox(height: 12),

                                AppSectionLabel(
                                  label: 'QUIZ INFO',
                                  accentColor: AppColors.btnMagenta,
                                ),
                                const SizedBox(height: 10),

                                const AppMonoLabel('TITLE'),
                                const SizedBox(height: 6),
                                ConsoleTextField(
                                  controller: _titleCtrl,
                                  hint: 'Quiz title',
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                                const SizedBox(height: 10),

                                const AppMonoLabel('DESCRIPTION'),
                                const SizedBox(height: 6),
                                ConsoleTextField(
                                  controller: _descCtrl,
                                  hint: 'Short description',
                                  maxLines: 3,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                                const SizedBox(height: 10),

                                const AppMonoLabel('PASSING SCORE (%)'),
                                const SizedBox(height: 6),
                                ConsoleTextField(
                                  controller: _passingScoreCtrl,
                                  hint: '60',
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    final n = double.tryParse(v?.trim() ?? '');
                                    if (n == null || n < 0 || n > 100) {
                                      return 'Enter 0-100';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                AppSectionLabel(
                                  label: 'QUESTIONS',
                                  accentColor: AppColors.btnMagenta,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Question cards
                        SliverList.builder(
                          itemCount: _questions.length,
                          itemBuilder: (context, i) => Padding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                            child: PixelButton(
                              label: '+ ADD QUESTION',
                              onPressed: _addQuestion,
                              color: AppColors.btnBlue,
                              textColor: AppColors.shellLight,
                              fullWidth: true,
                              fontSize: 9,
                            ),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 14, 12, 24),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                if (createState.errorMessage != null) ...[
                                  AppErrorBanner(
                                      createState.errorMessage!),
                                  const SizedBox(height: 10),
                                ],
                                createState.loading
                                    ? _LoadingBtn()
                                    : PixelButton(
                                        label: _isEditing
                                            ? 'SAVE CHANGES'
                                            : 'PUBLISH QUIZ',
                                        onPressed: _submit,
                                        color: AppColors.btnMagenta,
                                        textColor: AppColors.shellLight,
                                        fullWidth: true,
                                        fontSize: 10,
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom shell ─────────────────────────────────────────
            Container(
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.shell,
                border: Border(
                  top: BorderSide(
                      color: AppColors.outline, width: AppColors.borderFrame),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Question card ──────────────────────────────────────────────────

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
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: AppColors.crtBgDeep,
        border: Border.all(
            color: AppColors.phosphorDim, width: AppColors.borderRule),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: AppColors.phosphorDim,
                child: Text(
                  'Q$indexStr',
                  style: GoogleFonts.silkscreen(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.crtBgDeep,
                  ),
                ),
              ),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.btnRed, width: AppColors.borderRule),
                    ),
                    child: Text(
                      'REMOVE',
                      style: GoogleFonts.silkscreen(
                          fontSize: 7,
                          color: AppColors.btnRed,
                          letterSpacing: 1.0),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          const AppMonoLabel('QUESTION'),
          const SizedBox(height: 6),
          ConsoleTextField(
            controller: controllers.textCtrl,
            hint: 'Enter question text',
            maxLines: 2,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 10),

          const AppMonoLabel('OPTIONS  (tap circle = correct answer)'),
          const SizedBox(height: 6),
          ...List.generate(4, (i) {
            final letter = String.fromCharCode(65 + i);
            final isCorrect = controllers.correctIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  // Correct selector
                  GestureDetector(
                    onTap: () => onCorrectChanged(i),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.phosphor
                            : Colors.transparent,
                        border: Border.all(
                          color: isCorrect
                              ? AppColors.phosphor
                              : AppColors.phosphorDim,
                          width: AppColors.borderRule,
                        ),
                      ),
                      child: isCorrect
                          ? const Icon(Icons.check,
                              size: 13, color: AppColors.crtBgDeep)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 20,
                    height: 20,
                    color: AppColors.phosphorDim.withValues(alpha: 0.3),
                    child: Center(
                      child: Text(
                        letter,
                        style: GoogleFonts.silkscreen(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.phosphorDim),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ConsoleTextField(
                      controller: controllers.optionCtrls[i],
                      hint: 'Option $letter',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
            );
          }),

          const AppMonoLabel('EXPLANATION (OPTIONAL)'),
          const SizedBox(height: 6),
          ConsoleTextField(
            controller: controllers.explanationCtrl,
            hint: 'Why is this the correct answer?',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ── Loading button ─────────────────────────────────────────────────

class _LoadingBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.btnMagenta.withValues(alpha: 0.5),
        border:
            Border.all(color: AppColors.outline, width: AppColors.borderRule),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.shellLight,
            ),
          ),
          const SizedBox(width: 10),
          ShellText('SAVING...', fontSize: 9, color: AppColors.shellLight),
        ],
      ),
    );
  }
}

// ── Question controllers ───────────────────────────────────────────

class _QuestionControllers {
  final textCtrl = TextEditingController();
  final explanationCtrl = TextEditingController();
  final optionCtrls = List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;

  void dispose() {
    textCtrl.dispose();
    explanationCtrl.dispose();
    for (final c in optionCtrls) c.dispose();
  }
}
