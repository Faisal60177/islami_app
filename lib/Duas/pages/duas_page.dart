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
  final List<String> tabs = ['All', 'Category', 'Favorite', 'Bookmark'];

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);

    // Only rebuild for check icon when tab fully changed
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildTab(String title, bool isSelected, double screenWidth) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.teal : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: screenWidth * 0.038,
              ),
            ),
          ),
          if (isSelected) ...[
            SizedBox(width: screenWidth * 0.01),
            Icon(Icons.check, color: Colors.teal, size: screenWidth * 0.045),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.04;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Duas',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: screenWidth * 0.05),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(screenHeight * 0.15),
          child: Column(
            children: [
              // 🔹 Responsive Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: screenHeight * 0.01),
                child: SizedBox(
                  height: screenHeight * 0.055,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Duas...',
                      hintStyle: TextStyle(fontSize: screenWidth * 0.038),
                      prefixIcon: Icon(Icons.search, size: screenWidth * 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
                    ),
                    style: TextStyle(fontSize: screenWidth * 0.038),
                  ),
                ),
              ),

              // 🔹 Fixed-width tabs (non-scrollable, smooth, responsive)
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.transparent,
                isScrollable: false, // best for 4 tabs
                tabs: List.generate(
                  tabs.length,
                      (index) => _buildTab(tabs[index], _tabController.index == index, screenWidth),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(), // smooth swipe
        children: [
          AllDuasPage(searchQuery: searchQuery),
          CategoryPage(searchQuery: searchQuery),
          FavoriteDuasPage(searchQuery: searchQuery),
          BookmarkedDuasPage(searchQuery: searchQuery),
        ],
      ),
    );
  }
}