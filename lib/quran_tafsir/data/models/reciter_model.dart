import '../../domain/entities/reciter.dart';

class ReciterModel extends Reciter {
  const ReciterModel({
    required super.id,
    required super.reciterName,
    super.style,
  });

  factory ReciterModel.fromJson(Map<String, dynamic> json) {
    return ReciterModel(
      id: json['id'] as int,
      reciterName: json['reciter_name'] as String? ?? '',
      style: json['style'] as String?,
    );
  }
}
