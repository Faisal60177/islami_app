import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../cubit/inspiration_cubit.dart';
import '../cubit/inspiration_state.dart';
import '../model/inspiration_model.dart';
import '../model/inspiration_category_model.dart';
import 'inspiration_detail_page.dart';
import 'bookmarked_inspirations_page.dart';

// ── Predefined gradient colors per category index ──────────────
const List<List<Color>> kCategoryGradients = [
  [Color(0xFF0D3B35), Color(0xFF1A6B5A)],
  [Color(0xFF1A1A4E), Color(0xFF2D2D8F)],
  [Color(0xFF2D1B4E), Color(0xFF6B3FA0)],
  [Color(0xFF1A3A1A), Color(0xFF2D7A2D)],
  [Color(0xFF3B1A0D), Color(0xFF8B4513)],
  [Color(0xFF0D1A3B), Color(0xFF1A3A6B)],
  [Color(0xFF2D1A1A), Color(0xFF8B2020)],
  [Color(0xFF1A2D3B), Color(0xFF2D6B8B)],
];

List<Color> gradientForIndex(int index) =>
    kCategoryGradients[index % kCategoryGradients.length];

class InspirationPage extends StatefulWidget {
  const InspirationPage({super.key});

  @override
  State<InspirationPage> createState() => _InspirationPageState();
}

class _InspirationPageState extends State<InspirationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<InspirationCategoryModel> _categories = [];
  int _selectedCategoryId = -1; // -1 = All

  // ── Track whether categories were already loaded once ──────────
  // Prevents listener from re-calling loadAllInspirations on every
  // toggle emit (toggleFavorite/toggleBookmark emit InspirationLoaded([]))
  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    // ── Load SQLite instantly; sync Firestore silently ───────────
    context.read<InspirationCubit>().loadCategoriesIfEmpty();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onCategorySelected(int categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    final cubit = context.read<InspirationCubit>();
    if (categoryId == -1) {
      cubit.loadAllInspirations();
    } else {
      cubit.loadInspirationsByCategory(categoryId);
    }
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
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Inspiration',
          style: TextStyle(
            color:      Colors.white,
            fontSize:   20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded,
                color: Colors.white, size: 24),
            onPressed: () {
              // ── Navigate to dedicated bookmarks page ───────────
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<InspirationCubit>(),
                    child: const BookmarkedInspirationsPage(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<InspirationCubit, InspirationState>(
        listener: (context, state) {
          // ── Only rebuild categories once on first load ─────────
          // Do NOT re-trigger loadAllInspirations on every state
          // change — that caused the spinner loop
          if (state is InspirationCategoriesLoaded &&
              !_categoriesLoaded) {
            _categoriesLoaded = true;
            setState(() {
              _categories = state.categories;
              _tabController = TabController(
                length: state.categories.length + 1,
                vsync: this,
              );
            });
            // ── Do NOT call loadAllInspirations here ─────────────
            // loadCategoriesIfEmpty already emits InspirationLoaded
            // right after InspirationCategoriesLoaded
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              _buildCategoryTabs(),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final allCategories = [
      InspirationCategoryModel(
          categoryId: -1, categoryTitle: 'All', categoryIcon: ''),
      ..._categories,
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final cat        = allCategories[index];
          final isSelected = cat.categoryId == _selectedCategoryId;
          return GestureDetector(
            onTap: () => _onCategorySelected(cat.categoryId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin:  const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF132E25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF1E4535),
                  width: 1,
                ),
              ),
              child: Text(
                cat.categoryTitle,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF071A15)
                      : Colors.white70,
                  fontSize:   13,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(InspirationState state) {
    if (state is InspirationLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: Color(0xFF2ECC71), strokeWidth: 2),
      );
    }

    if (state is InspirationError) {
      return Center(
        child: Text(state.message,
            style: const TextStyle(color: Colors.white54)),
      );
    }

    if (state is InspirationLoaded) {
      if (state.inspirations.isEmpty) {
        return const Center(
          child: Text('No inspirations found.',
              style: TextStyle(color: Colors.white38, fontSize: 14)),
        );
      }
      return _buildGrid(state.inspirations);
    }

    return const SizedBox.shrink();
  }

  Widget _buildGrid(List<InspirationModel> inspirations) {
    return MasonryGridView.count(
      crossAxisCount:  2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: inspirations.length,
      itemBuilder: (context, index) {
        return _InspirationCard(
          inspiration:    inspirations[index],
          gradientColors: gradientForIndex(index),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InspirationDetailPage(
                inspirations: inspirations,
                initialIndex: index,
              ),
            ),
          ),
          onFavoriteTap: () => context
              .read<InspirationCubit>()
              .toggleFavorite(inspirations[index]),
        );
      },
    );
  }
}

// ── Inspiration Card ────────────────────────────────────────────
class _InspirationCard extends StatelessWidget {
  final InspirationModel inspiration;
  final List<Color>      gradientColors;
  final VoidCallback     onTap;
  final VoidCallback     onFavoriteTap;

  const _InspirationCard({
    required this.inspiration,
    required this.gradientColors,
    required this.onTap,
    required this.onFavoriteTap,
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
                  color:       Colors.white54,
                  fontSize:    10,
                  fontWeight:  FontWeight.w400,
                  letterSpacing: 0.3,
                ),
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

            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: onFavoriteTap,
                child: Icon(
                  inspiration.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: inspiration.isFavorite
                      ? Colors.redAccent
                      : Colors.white38,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}