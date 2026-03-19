import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  // 🔹 Use controller for reactive search
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);

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

  Widget _buildTab(String title, bool isSelected) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.teal : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 4),
          if (isSelected) const Icon(Icons.check, color: Colors.teal, size: 18),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duas App'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // 🔹 Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Duas...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
              // 🔹 Tab bar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.transparent,
                tabs: List.generate(
                  tabs.length,
                      (index) => _buildTab(tabs[index], _tabController.index == index),
                ),
                onTap: (_) => setState(() {}), // rebuild tabs to show check icon
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
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