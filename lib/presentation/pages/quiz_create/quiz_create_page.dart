import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/theme/app_colors.dart';
import 'package:quiz_app/presentation/providers/auth_provider.dart';
import 'package:quiz_app/presentation/providers/quiz_create_provider.dart';
import 'package:quiz_app/presentation/routes/app_router.dart';

/// Admin-only page for creating a new quiz with its questions.
///
/// Anti-Design signature moves:
///  (1) Accent-serif italic in the headline.
///  (3) Tilted stamp on section labels.
///  (5) Hairline crop ticks between sections.
///  (6) Gap swing throughout.
class QuizCreatePage extends ConsumerStatefulWidget {
  const QuizCreatePage({super.key});

  @override
  ConsumerState<QuizCreatePage> createState() => _QuizCreatePageState();
}

class _QuizCreatePageState extends ConsumerState<QuizCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Each question is represented as a map of controllers.
  final List<_QuestionControllers> _questions = [];

  @override
  void initState() {
    super.initState();
    _addQuestion(); // start with one empty question
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
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

    await ref.read(quizCreateNotifierProvider.notifier).createQuiz(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          questions: questions,
        );

    final state = ref.read(quizCreateNotifierProvider);
    if (state.errorMessage == null && mounted) {
      context.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;

    // Guard — non-admins should never reach this page, but just in case.
    if (user == null || !user.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.paper,
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
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopStrip(onBack: () => context.go(AppRouter.home)),
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
                            _Headline(),
                            const SizedBox(height: AppColors.nudge * 2),
                            _SectionLabel(label: 'QUIZ INFO'),
                            const SizedBox(height: AppColors.nudge),
                            _FieldLabel('TITLE'),
                            const SizedBox(height: AppColors.gapTight),
                            _CreateField(
                              controller: _titleCtrl,
                              hint: 'e.g. Advanced Flutter',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: AppColors.nudge),
                            _FieldLabel('DESCRIPTION'),
                            const SizedBox(height: AppColors.gapTight),
                            _CreateField(
                              controller: _descCtrl,
                              hint: 'Short description of the quiz',
                              maxLines: 3,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: AppColors.nudge * 2),
                            _SectionLabel(label: 'QUESTIONS'),
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
                              Container(
                                color: AppColors.alarm,
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  createState.errorMessage!,
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 11,
                                    color: AppColors.paper,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppColors.nudge),
                            ],
                            FilledButton(
                              onPressed: createState.loading ? null : _submit,
                              child: createState.loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: AppColors.borderFrame,
                                        color: AppColors.ink,
                                      ),
                                    )
                                  : const Text('PUBLISH QUIZ'),
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

// ── Top strip ──────────────────────────────────────────────────────────────

class _TopStrip extends StatelessWidget {
  const _TopStrip({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.ink, width: AppColors.borderRule),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Text(
              '<- HOME',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.ink,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'ADMIN',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              letterSpacing: 2.0,
              color: AppColors.grid,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Headline ───────────────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final displaySize =
        (screenW / 6.0).clamp(AppColors.displayMin, AppColors.displayMax);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CREATE',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: displaySize,
            fontWeight: FontWeight.w800,
            height: AppColors.displayLeading,
            letterSpacing: -2.0,
            color: AppColors.ink,
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
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

// ── Section label (signature move 3 + 5) ──────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Tilted stamp (signature move 3)
        ExcludeSemantics(
          child: Transform.rotate(
            angle: AppColors.angleStamp,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.acid,
                border: Border.all(
                    color: AppColors.ink, width: AppColors.borderRule),
              ),
              child: Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Hairline crop tick (signature move 5)
        Expanded(
          child: Container(
            height: AppColors.borderRule,
            color: AppColors.grid,
          ),
        ),
      ],
    );
  }
}

// ── Field label ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
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
        color: AppColors.ink,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.instrumentSans(
          fontSize: AppColors.bodySize,
          color: AppColors.grid,
        ),
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide:
              BorderSide(color: AppColors.ink, width: AppColors.borderRule),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide:
              BorderSide(color: AppColors.ink, width: AppColors.borderFrame),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide:
              BorderSide(color: AppColors.alarm, width: AppColors.borderRule),
        ),
        focusedErrorBorder: const OutlineInputBorder(
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
        border: Border.all(color: AppColors.ink, width: AppColors.borderRule),
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
                  color: AppColors.grid,
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
          _FieldLabel('QUESTION TEXT'),
          const SizedBox(height: AppColors.gapTight),
          _CreateField(
            controller: controllers.textCtrl,
            hint: 'Enter the question',
            maxLines: 2,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppColors.nudge),
          _FieldLabel('OPTIONS  (tap circle to mark correct answer)'),
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
                            isCorrect ? AppColors.acid : AppColors.paper,
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppColors.borderRule,
                        ),
                      ),
                      child: isCorrect
                          ? const Icon(Icons.check,
                              size: 14, color: AppColors.ink)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$letter.',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
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
          _FieldLabel('EXPLANATION (optional)'),
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
