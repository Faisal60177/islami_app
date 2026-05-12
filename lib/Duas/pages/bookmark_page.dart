import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/duas_cubit.dart';
import '../model/duas_model.dart';
import 'duas_detail_page.dart';

class BookmarkedDuasPage extends StatefulWidget {
  final String searchQuery;
  const BookmarkedDuasPage({super.key, required this.searchQuery});

  @override
  State<BookmarkedDuasPage> createState() => _BookmarkedDuasPageState();
}

class _BookmarkedDuasPageState extends State<BookmarkedDuasPage>
    with AutomaticKeepAliveClientMixin {
  List<DuasModel> bookmarkDuas = [];
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadBookmarks();
  }

  Future<void> loadBookmarks() async {
    setState(() => isLoading = true);
    final cubit = context.read<DuasCubit>();
    final userId = cubit.userId;

    if (userId != 'guest') {
      await cubit.repository.syncUserInteractionsFromFirestore(userId);
    }

    final data = await cubit.repository.getBookmarkedForUser(userId);
    setState(() {
      bookmarkDuas = data;
      isLoading = false;
    });
  }

  List<DuasModel> get filteredDuas {
    if (widget.searchQuery.isEmpty) return bookmarkDuas;
    final query = widget.searchQuery.toLowerCase();
    return bookmarkDuas
        .where((dua) =>
    dua.arabic.toLowerCase().contains(query) ||
        dua.categoryTitle.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(
              color: Color(0xFF0D6E6E), strokeWidth: 3));
    }

    if (bookmarkDuas.isEmpty) {
      return const _EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'No bookmarks yet',
        subtitle: 'Tap the bookmark on any dua to save it here',
        iconColor: Color(0xFFE57373),
      );
    }

    if (filteredDuas.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        subtitle: 'Try a different search term',
        iconColor: Colors.grey[400]!,
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0D6E6E),
      onRefresh: loadBookmarks,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  w * 0.05, h * 0.02, w * 0.05, h * 0.01),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.03, vertical: h * 0.007),
                decoration: BoxDecoration(
                  color: const Color(0xFFE57373).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_rounded,
                        size: w * 0.04, color: const Color(0xFFE57373)),
                    SizedBox(width: w * 0.015),
                    Text(
                      '${filteredDuas.length} saved',
                      style: TextStyle(
                        fontSize: w * 0.034,
                        color: const Color(0xFFE57373),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding:
            EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.03),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final dua = filteredDuas[index];
                  return _BookmarkCard(
                    dua: dua,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DuasDetailPage(dua: dua)),
                      );
                      // ✅ reload after returning — user may have un-favorited
                      loadBookmarks();
                    },
                  );
                },
                childCount: filteredDuas.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final DuasModel dua;
  final VoidCallback onTap;
  const _BookmarkCard({required this.dua, required this.onTap});

  String getShortText(String text, [int limit = 50]) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.014),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFFE57373).withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFE57373).withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.04, vertical: h * 0.016),
            child: Row(
              children: [
                Container(
                  width: w * 0.12,
                  height: w * 0.12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE57373).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(Icons.bookmark_rounded,
                        color: const Color(0xFFE57373),
                        size: w * 0.055),
                  ),
                ),
                SizedBox(width: w * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        getShortText(dua.arabic),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: w * 0.042,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A2B2B),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: h * 0.006),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: w * 0.025, vertical: h * 0.004),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D6E6E).withOpacity(0.09),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(dua.categoryTitle,
                            style: TextStyle(
                                fontSize: w * 0.03,
                                color: const Color(0xFF0D6E6E),
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: w * 0.02),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[350], size: w * 0.055),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.06),
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: w * 0.14, color: iconColor),
            ),
            SizedBox(height: h * 0.025),
            Text(title,
                style: TextStyle(
                    fontSize: w * 0.048,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A2B2B)),
                textAlign: TextAlign.center),
            SizedBox(height: h * 0.01),
            Text(subtitle,
                style: TextStyle(
                    fontSize: w * 0.036,
                    color: Colors.grey[400],
                    height: 1.5),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}