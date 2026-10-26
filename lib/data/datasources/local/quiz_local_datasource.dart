import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:quiz_app/core/errors/failures.dart';
import 'package:quiz_app/data/models/quiz_model.dart';

/// Reads quiz data from a bundled JSON asset.
///
/// The data source is the only place that knows *where* data comes
/// from. Swapping in an API-backed data source later would not touch
/// the repository or domain layers.
class QuizLocalDataSource {
  const QuizLocalDataSource({this.assetPath = 'assets/data/quizzes.json'});

  final String assetPath;

  /// Loads and decodes the bundled JSON, returning the raw list of
  /// quiz maps. Throws a [FormatFailure] on decode errors and an
  /// [UnexpectedFailure] on asset load errors.
  Future<List<Map<String, dynamic>>> loadRaw() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatFailure('Expected a JSON array of quizzes.');
      }
      return decoded.cast<Map<String, dynamic>>();
    } on FormatFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure();
    }
  }

  /// Convenience: load full [QuizModel]s including questions.
  Future<List<QuizModel>> loadAll() async {
    final raw = await loadRaw();
    return raw.map(QuizModel.fromJson).toList(growable: false);
  }

  /// Convenience: load quiz summaries (no questions).
  Future<List<QuizModel>> loadSummaries() async {
    final raw = await loadRaw();
    return raw.map(QuizModel.summaryFromJson).toList(growable: false);
  }
}
