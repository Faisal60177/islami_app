import 'package:flutter/material.dart';
import 'chapter_juz_picker_sheet.dart';

class AppBarSwitcherTitle extends StatelessWidget {
  final String currentLabel;
  final PickerType pickerType;
  final int? currentChapterNumber;
  final int? currentJuzNumber;

  const AppBarSwitcherTitle({
    super.key,
    required this.currentLabel,
    required this.pickerType,
    this.currentChapterNumber,
    this.currentJuzNumber,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => ChapterJuzPickerSheet.show(
        context,
        initialType: pickerType,
        currentChapterNumber: currentChapterNumber,
        currentJuzNumber: currentJuzNumber,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(currentLabel, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}