class Reciter {
  final int id;
  final String reciterName;
  final String? style; // যেমন "Murattal" / "Mujawwad", null হতে পারে

  const Reciter({
    required this.id,
    required this.reciterName,
    this.style,
  });
}
