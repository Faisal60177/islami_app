import 'package:flutter/services.dart';
import 'dart:convert';
import '../database/local/duas_sqflite.dart';
import '../model/duas_model.dart';
import '../model/category_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DuasRepository {
  final DuasSqflite dbHelper = DuasSqflite();

  /// 🔹 Categories
  Future<List<CategoryModel>> getAllCategories() async {
    final data = await dbHelper.getAllCategories();
    return data.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<void> insertCategory(CategoryModel cat) async {
    await dbHelper.insertCategory(cat.toMap());
  }

  Future<void> syncCategoriesFromJson(String assetPath) async {
    final jsonData = await rootBundle.loadString(assetPath);
    final List<dynamic> categoriesList = json.decode(jsonData);

    for (var catMap in categoriesList) {
      final category = CategoryModel.fromMap(catMap);
      await insertCategory(category); // insert only new categories
    }
  }

  /// 🔹 Firestore → SQLite (Categories) ✅ SAME STYLE AS JSON
  Future<void> syncCategoriesFromFirestore() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('categories duas').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final category = CategoryModel.fromMap({
        'category': data['category'],
        'category_title': data['category_title'],
        'category_icon': data['category_icon'],
      });

      await insertCategory(category); // same as JSON
    }
  }


  /// 🔹 Duas
  Future<List<DuasModel>> getAllDuas() async {
    final data = await dbHelper.getAllDuas();
    return data.map((e) => DuasModel.fromMap(e)).toList();
  }

  Future<void> insertDua(DuasModel dua) async {
    await dbHelper.insertDua(dua.toMap());
  }

  Future<void> updateDua(DuasModel dua) async {
    await dbHelper.updateDua(dua.toMap(), dua.id);
  }

  Future<void> deleteDua(int id) async {
    await dbHelper.deleteDua(id);
  }

  /// 🔹 Toggle favorite
  Future<void> toggleFavorite(DuasModel dua) async {
    dua.isFavorite = !dua.isFavorite;
    await updateDua(dua);
  }

  /// 🔹 Toggle bookmark
  Future<void> toggleBookmark(DuasModel dua) async {
    dua.isBookmarked = !dua.isBookmarked;
    await updateDua(dua);
  }

  /// 🔹 Sync Duas from JSON
  Future<void> syncDuasFromJson(String assetPath) async {
    final dbDuas = await getAllDuas();
    final existingMap = {for (var d in dbDuas) d.id: d};

    final jsonData = await rootBundle.loadString(assetPath);
    final List<dynamic> duasList = json.decode(jsonData);

    for (var duaMap in duasList) {
      final dua = DuasModel.fromMap({
        'id': duaMap['id'],
        'category': duaMap['category'],
        'arabic': duaMap['arabic'],
        'transliteration': duaMap['transliteration'],
        'translation_en': duaMap['translation']['en'],
        'translation_bn': duaMap['translation']['bn'],
        'reference': duaMap['reference'],
        'tags': (duaMap['tags'] as List).join(','),
        'audio_url': duaMap['audio_url'],
      });

      if (!existingMap.containsKey(dua.id)) {
        // 🆕 Insert new dua
        await insertDua(dua);
      } else {
        // 🔄 Update existing but preserve user data
        final old = existingMap[dua.id]!;
        final updated = DuasModel(
          id: dua.id,
          category: dua.category,
          arabic: dua.arabic,
          transliteration: dua.transliteration,
          translation: dua.translation,
          reference: dua.reference,
          tags: dua.tags,
          audioUrl: dua.audioUrl,
          isFavorite: old.isFavorite,
          isBookmarked: old.isBookmarked,
        );
        await updateDua(updated);
      }
    }
  }

  /// 🔥 Firestore → SQLite (Duas) ✅ NOW EXACTLY SAME AS JSON
  Future<void> syncDuasFromFirestore() async {
    final dbDuas = await getAllDuas();
    final existingMap = {for (var d in dbDuas) d.id: d};

    final snapshot =
    await FirebaseFirestore.instance.collection('duas').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final dua = DuasModel.fromMap({
        'id': data['id'],
        'category': data['category'],
        'arabic': data['arabic'],
        'transliteration': data['transliteration'],
        'translation_en': data['translation_en'],
        'translation_bn': data['translation_bn'],
        'reference': data['reference'],
        'tags': data['tags'], // ✅ SAME AS JSON
        'audio_url': data['audio_url'],
      });

      if (!existingMap.containsKey(dua.id)) {
        // 🆕 INSERT
        await insertDua(dua);
      } else {
        // 🔄 UPDATE (preserve user data)
        final old = existingMap[dua.id]!;

        final updated = DuasModel(
          id: dua.id,
          category: dua.category,
          arabic: dua.arabic,
          transliteration: dua.transliteration,
          translation: dua.translation,
          reference: dua.reference,
          tags: dua.tags,
          audioUrl: dua.audioUrl,
          isFavorite: old.isFavorite,
          isBookmarked: old.isBookmarked,
        );

        await updateDua(updated);
      }
    }
  }
}