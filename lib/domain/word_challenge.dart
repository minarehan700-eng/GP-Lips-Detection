import 'viseme_group.dart';

/// A word turned into the run of mouth shapes needed to say it.
///
/// Why a word can be practised when a letter cannot:
/// a single shape is ambiguous — "p", "b" and "m" are one shape — but a
/// *sequence* of shapes is much less so. "mama" is closed-open-closed-open,
/// and very few words share that pattern. This is how lip reading actually
/// works: not by identifying letters, but by matching a rhythm of shapes
/// against words that could plausibly fit.
///
/// The mapping is for the Latin alphabet. Arabic and other scripts need their
/// own grapheme rules, which is why the built-in library below is English.
class WordChallenge {
  const WordChallenge({required this.word, required this.shapes});

  /// The word being practised.
  final String word;

  /// The shapes to make, in order, with repeats collapsed.
  final List<String> shapes;

  /// Builds a challenge from a word, or null when no letter in it maps to a
  /// shape — a string of digits or punctuation, say.
  ///
  /// Consecutive identical shapes are collapsed: "letter" has two t's, but the
  /// mouth only makes the neutral shape once, and asking the user to make it
  /// twice in a row would be asking for something invisible.
  static WordChallenge? fromWord(String word) {
    final shapes = <String>[];
    for (final rune in word.toLowerCase().split('')) {
      final shape = VisemeGroup.shapeForLetter(rune);
      if (shape == null) {
        continue;
      }
      if (shapes.isEmpty || shapes.last != shape) {
        shapes.add(shape);
      }
    }
    if (shapes.isEmpty) {
      return null;
    }
    return WordChallenge(word: word, shapes: shapes);
  }

  /// How many distinct shapes the user has to make.
  int get length => shapes.length;
}

/// A named set of words to practise, so the library can be browsed by purpose
/// rather than as one long list.
class WordCategory {
  const WordCategory({
    required this.id,
    required this.words,
  });

  /// Key used to look the category's translated name up.
  final String id;

  final List<String> words;
}

/// The built-in word library.
///
/// Chosen rather than scraped: these are words worth being able to mouth when
/// speech is not available — greetings, the digits, and the short phrases that
/// matter in an emergency. Long words are avoided: an eight-shape sequence is
/// a memory test, not a lip-reading one.
class WordLibrary {
  static const List<WordCategory> categories = [
    WordCategory(
      id: 'greetings',
      words: ['hello', 'hi', 'bye', 'please', 'thanks', 'sorry', 'yes', 'no'],
    ),
    WordCategory(
      id: 'numbers',
      // The digits as they are spoken. "Six" is mouthed, not signed, so it is
      // a sequence of shapes like any other word.
      words: [
        'zero', 'one', 'two', 'three', 'four',
        'five', 'six', 'seven', 'eight', 'nine', 'ten',
      ],
    ),
    WordCategory(
      id: 'emergency',
      words: ['help', 'stop', 'pain', 'doctor', 'water', 'call', 'fire'],
    ),
    WordCategory(
      id: 'everyday',
      words: ['mama', 'papa', 'home', 'food', 'good', 'more', 'name', 'time'],
    ),
  ];

  /// Every word in the library, in category order.
  static List<String> get allWords =>
      [for (final category in categories) ...category.words];

  static WordCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }
}
