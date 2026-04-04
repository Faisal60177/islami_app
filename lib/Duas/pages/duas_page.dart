import 'package:flutter/material.dart';
import 'all_duas_page.dart';
import 'category_page.dart';
import 'favorite_page.dart';
import 'bookmark_page.dart';

class DuasPage extends StatefulWidget {
  const DuasPage({super.key});

  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> tabs = [
    {'label': 'All', 'icon': Icons.auto_stories_rounded},
    {'label': 'Category', 'icon': Icons.grid_view_rounded},
    {'label': 'Favorite', 'icon': Icons.favorite_rounded},
    {'label': 'Bookmark', 'icon': Icons.bookmark_rounded},
  ];

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: h * 0.22,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0D6E6E),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A5C5C), Color(0xFF0D8585)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative Arabic pattern circles
                    Positioned(
                      top: -h * 0.04,
                      right: -w * 0.08,
                      child: Container(
                        width: w * 0.45,
                        height: w * 0.45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.08), width: 2),
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.02,
                      right: w * 0.05,
                      child: Container(
                        width: w * 0.25,
                        height: w * 0.25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: h * 0.05,
                      left: -w * 0.05,
                      child: Container(
                        width: w * 0.3,
                        height: w * 0.3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                    ),
                    // Gold accent line
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFD4AF37), Color(0xFFF5D76E), Color(0xFFD4AF37)],
                          ),
                        ),
                      ),
                    ),
                    // Title content
                    Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + h * 0.015,
                        left: w * 0.05,
                        right: w * 0.05,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.menu_book_rounded, color: const Color(0xFFD4AF37), size: w * 0.06),
                              ),
                              SizedBox(width: w * 0.03),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Duas & Adhkar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: w * 0.055,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'الأدعية والأذكار',
                                    style: TextStyle(
                                      color: const Color(0xFFD4AF37),
                                      fontSize: w * 0.04,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: h * 0.018),
                          // Search bar
                          Container(
                            height: h * 0.055,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search duas...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: w * 0.037,
                                ),
                                prefixIcon: Icon(Icons.search_rounded,
                                    color: const Color(0xFF0D6E6E), size: w * 0.055),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                  icon: Icon(Icons.close_rounded, size: w * 0.045, color: Colors.grey),
                                  onPressed: () => _searchController.clear(),
                                )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: h * 0.013),
                              ),
                              style: TextStyle(fontSize: w * 0.038, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(h * 0.065),
              child: Container(
                color: const Color(0xFF0A5C5C),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFD4AF37),
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  isScrollable: false,
                  labelPadding: EdgeInsets.zero,
                  tabs: List.generate(tabs.length, (index) {
                    final isSelected = _tabController.index == index;
                    return Tab(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: w * 0.01),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tabs[index]['icon'] as IconData,
                              size: w * 0.048,
                              color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.55),
                            ),
                            SizedBox(height: 2),
                            Text(
                              tabs[index]['label'] as String,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.55),
                                fontSize: w * 0.028,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: [
            AllDuasPage(searchQuery: searchQuery),
            CategoryPage(searchQuery: searchQuery),
            FavoriteDuasPage(searchQuery: searchQuery),
            BookmarkedDuasPage(searchQuery: searchQuery),
          ],
        ),
      ),
    );
  }
}