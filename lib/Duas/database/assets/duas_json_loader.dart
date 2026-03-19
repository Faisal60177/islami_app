import 'dart:convert';
import 'package:flutter/services.dart';

Future<List<dynamic>> loadJson() async {
  final data = await rootBundle.loadString('assets/duas.json');
  return json.decode(data);
}