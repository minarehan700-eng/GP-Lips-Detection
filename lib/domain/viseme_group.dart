/// What each mouth shape actually corresponds to in speech.
///
/// Why this exists:
/// the detector reports five shapes, A to E, and on its own that tells a
/// learner very little. A shape is not a letter — it is a *group* of letters
/// that look identical on the lips. "p", "b" and "m" are made in different
/// places in the mouth but the lips do exactly the same thing, so no amount of
/// looking will separate them.
///
/// That is the central fact of lip reading, and stating it is more useful than
/// hiding it: a learner who knows that a closed mouth means "p or b or m" can
/// use context to choose, while one who is told it means "B" has been misled.
///
/// The five shapes below cover the whole alphabet and every digit between
/// them. Nothing is missing — the letters are grouped, not dropped.
class VisemeGroup {
  const VisemeGroup({
    required this.shape,
    required this.name,
    required this.letters,
    required this.exampleWords,
    required this.mouthHint,
  });

  /// The shape code the detector reports: A, B, C, D or E.
  final String shape;

  /// A short name for the shape, e.g. "closed".
  final String name;

  /// Every letter or sound that produces this shape.
  final List<String> letters;

  /// Words a learner can say to feel the shape.
  final List<String> exampleWords;

  /// What the mouth is doing, in one phrase.
  final String mouthHint;

  /// The five shapes, in the order the reference chart shows them.
  static const List<VisemeGroup> all = [
    VisemeGroup(
      shape: 'A',
      name: 'open',
      letters: ['a', 'ah', 'aa'],
      exampleWords: ['car', 'father', 'hat'],
      mouthHint: 'jaw dropped, mouth wide',
    ),
    VisemeGroup(
      shape: 'B',
      name: 'closed',
      // The clearest example of why a shape is not a letter: three different
      // consonants, one identical pair of lips.
      letters: ['p', 'b', 'm'],
      exampleWords: ['pat', 'bat', 'mat'],
      mouthHint: 'lips pressed together',
    ),
    VisemeGroup(
      shape: 'C',
      name: 'rounded',
      letters: ['o', 'u', 'w', 'oo', 'ow'],
      exampleWords: ['boot', 'go', 'we'],
      mouthHint: 'lips pushed forward into a circle',
    ),
    VisemeGroup(
      shape: 'D',
      name: 'neutral',
      // The largest group by far. These sounds are made with the tongue and
      // the teeth, which the lips barely report, so they all look alike from
      // outside. A five-shape model also folds "f" and "v" in here; with more
      // shapes they would be their own group, since the top teeth touching the
      // bottom lip is genuinely visible.
      letters: [
        't', 'd', 'n', 'l', 's', 'z', 'k', 'g',
        'r', 'h', 'j', 'c', 'q', 'x', 'th', 'f', 'v',
      ],
      exampleWords: ['ten', 'dog', 'sun'],
      mouthHint: 'slightly open, tongue doing the work',
    ),
    VisemeGroup(
      shape: 'E',
      name: 'spread',
      letters: ['e', 'i', 'y', 'ee'],
      exampleWords: ['see', 'be', 'city'],
      mouthHint: 'lips pulled wide, like a small smile',
    ),
  ];

  /// The shape a single letter produces, or null when it is not a letter this
  /// model has an opinion about.
  static String? shapeForLetter(String letter) {
    final lower = letter.toLowerCase();
    for (final group in all) {
      if (group.letters.contains(lower)) {
        return group.shape;
      }
    }
    return null;
  }

  static VisemeGroup? forShape(String shape) {
    for (final group in all) {
      if (group.shape == shape) {
        return group;
      }
    }
    return null;
  }

  /// Every letter this model covers, so a test can prove nothing was left out.
  static Set<String> get coveredLetters =>
      {for (final group in all) ...group.letters};
}
