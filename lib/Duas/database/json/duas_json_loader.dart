import 'dart:convert';
import 'package:flutter/services.dart';

Future<List<dynamic>> loadCategories() async {
  final data = await rootBundle.loadString('assets/json/categories.json');
  return json.decode(data);
}

Future<List<dynamic>> loadDuas() async {
  final data = await rootBundle.loadString('assets/json/duas.json');
  return json.decode(data);
}

