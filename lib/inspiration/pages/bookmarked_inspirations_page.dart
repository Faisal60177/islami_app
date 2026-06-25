import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../cubit/inspiration_cubit.dart';
import '../model/inspiration_model.dart';
import 'inspiration_detail_page.dart';
import 'inspiration_page.dart' show gradientForIndex;

class BookmarkedInspirationsPage extends StatefulWidget {
  const BookmarkedInspirationsPage({super.key});

  @override
  State<BookmarkedInspirationsPage> createState() =>
      _BookmarkedInspirationsPageState();
}

class _BookmarkedInspirationsPageState
    extends State<BookmarkedInspirationsPage> {
  List<InspirationModel> _bookmarked = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final cubit  = context.read<InspirationCubit>();
    final userId = cubit.userId;

    // Sync Firestore for logged-in users
    if (userId != 'guest') {
      await cubit.repository.syncUserInteractionsFromFirestore(userId);
    }

    final data = await cubit.repository.getBookmarkedForUser(
      userId:       userId,
      languageCode: cubit.currentLanguageCode,
    );

    if (!mounted) return;
    setState(() {
      _bookmarked = data;
      _isLoading  = false;
    });
  }

  Future<void> _removeBookmark(InspirationModel inspiration) async {
    inspiration.isBookmarked = false;
    context.read<InspirationCubit>().toggleBookmark(inspiration);
    setState(() => _bookmarked.removeWhere((x) => x.id == inspiration.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A15),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved',
          style: TextStyle(
            color:      Colors.white,
            fontSize:   20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(
              color: Color(0xFF2ECC71), strokeWidth: 2))
          : _bookmarked.isEmpty
          ? const Center(
        child: Text(
          'No saved inspirations yet.',
          style: TextStyle(
              color: Colors.white38, fontSize: 14),
        ),
      )
          : MasonryGridView.count(
        physics: const ClampingScrollPhysics(),
          crossAxisCount:   2,
          mainAxisSpacing:  10,
          crossAxisSpacing: 10,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: _bookmarked.length,
          itemBuilder: (context, index) {
            final inspiration = _bookmarked[index];
            return _BookmarkCard(
              inspiration:    inspiration,
              gradientColors: gradientForIndex(index),
              onRemove: () => _removeBookmark(inspiration),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InspirationDetailPage(
                    inspirations: _bookmarked,
                    initialIndex: index,
                  ),
                ),
              ),
            );
          },
        ),

    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final InspirationModel inspiration;
  final List<Color>      gradientColors;
  final VoidCallback     onRemove;
  final VoidCallback     onTap;

  const _BookmarkCard({
    required this.inspiration,
    required this.gradientColors,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reference — only if present
            if (inspiration.reference != null &&
                inspiration.reference!.isNotEmpty)
              Text(
                inspiration.reference!,
                maxLines:  1,
                overflow:  TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 10),
              ),

            const SizedBox(height: 4),

            Text(
              inspiration.title,
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   13,
                fontWeight: FontWeight.w600,
                height:     1.3,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              inspiration.quoteText,
              maxLines:  4,
              overflow:  TextOverflow.ellipsis,
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   15,
                fontWeight: FontWeight.w700,
                height:     1.4,
              ),
            ),

            const SizedBox(height: 10),

            // Tap bookmark to remove
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Color(0xFF2ECC71),
                  size:  20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}