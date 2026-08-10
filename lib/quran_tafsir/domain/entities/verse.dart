class VerseTranslation {
  final int resourceId;
  final String resourceName;
  final String text;

  const VerseTranslation({
    required this.resourceId,
    required this.resourceName,
    required this.text,
});
}

class VerseAudio{
  final String url;

  const VerseAudio({
    required this.url,
});
}

class Verse {
  final int id;
  final String verseKey;
  final int verseNumber;
  final int chapterId;
  final String textUthmani;
  final List<VerseTranslation> translations;
  final VerseAudio? audio;

  const Verse({
    required this.id,
    required this.verseKey,
    required this.verseNumber,
    required this.chapterId,
    required this.textUthmani,
    required this.translations,
    this.audio,
});
}