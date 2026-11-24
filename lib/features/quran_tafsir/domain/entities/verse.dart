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

class Word {
  final int position; // word's order within the verse (1-based)
  final String textUthmani; // the word itself, Uthmani script
  final String charType; // "word" for normal words, "end" for the
  // trailing ayah-end marker token

  const Word({
    required this.position,
    required this.textUthmani,
    required this.charType,
  });

  bool get isEndMarker => charType == 'end';
}

class AudioSegment {
  final int wordStart;
  final int wordEnd;
  final int startMs;
  final int endMs;

  const AudioSegment({
    required this.wordStart,
    required this.wordEnd,
    required this.startMs,
    required this.endMs,
  });
}

class VerseAudio{
  final String url;
  final List<AudioSegment> segments;

  const VerseAudio({
    required this.url,
    this.segments = const[],
});
}

class Verse {
  final int id;
  final String verseKey;
  final int verseNumber;
  final int chapterId;
  final String textUthmani;
  final List<VerseTranslation> translations;
  final List<Word> words;
  final VerseAudio? audio;

  const Verse({
    required this.id,
    required this.verseKey,
    required this.verseNumber,
    required this.chapterId,
    required this.textUthmani,
    required this.translations,
    this.words = const[],
    this.audio,
});
}