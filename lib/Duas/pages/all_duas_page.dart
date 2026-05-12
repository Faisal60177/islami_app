import 'package:flutter/material.dart';
import 'duas_detail_page.dart';
import '../model/duas_model.dart';
import '../repository/duas_repository.dart';

class AllDuasPage extends StatefulWidget {
  final String searchQuery;
  const AllDuasPage({super.key, required this.searchQuery});

  @override
  State<AllDuasPage> createState() => _AllDuasPageState();
}

class _AllDuasPageState extends State<AllDuasPage> with AutomaticKeepAliveClientMixin {
  final DuasRepository repository = DuasRepository();
  List<DuasModel> allDuas = [];
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadDuas();
  }

  Future<void> loadDuas() async {
    final duas = await repository.getAllDuas();
    setState(() {
      allDuas = duas;
      isLoading = false;
    });
  }

  List<DuasModel> get filteredDuas {
    if (widget.searchQuery.isEmpty) return allDuas;
    final query = widget.searchQuery.toLowerCase();
    return allDuas.where((dua) =>
    dua.arabic.toLowerCase().contains(query) ||
        dua.transliteration.toLowerCase().contains(query) ||
        dua.categoryTitle.toLowerCase().contains(query)).toList();
  }

  String getShortDescription(String text, [int limit = 55]) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: w * 0.12,
              height: w * 0.12,
              child: CircularProgressIndicator(
                color: const Color(0xFF0D6E6E),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: h * 0.02),
            Text(
              'Loading duas...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: w * 0.038,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredDuas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: w * 0.15, color: Colors.grey[300]),
            SizedBox(height: h * 0.02),
            Text(
              'No duas found',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: w * 0.045,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.018, w * 0.04, h * 0.03),
      itemCount: filteredDuas.length,
      itemBuilder: (context, index) {
        final dua = filteredDuas[index];
        return _DuaCard(
          dua: dua,
          index: index,
          onTap: () async {
            // ✅ await the push — user may toggle in detail page
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DuasDetailPage(dua: dua)),
            );
            // no reload needed — all duas list cards have no favorite/bookmark icons
          },
        );
      },
    );
  }
}

class _DuaCard extends StatelessWidget {
  final DuasModel dua;
  final int index;
  final VoidCallback onTap;

  const _DuaCard({required this.dua, required this.index, required this.onTap});

  String getShortDescription(String text, [int limit = 55]) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    // Alternating subtle accent colors for variety
    final List<Color> avatarColors = [
      const Color(0xFF0D6E6E),
      const Color(0xFF1A7A5E),
      const Color(0xFF2E6B8A),
      const Color(0xFF6B5E2E),
    ];
    final accentColor = avatarColors[index % avatarColors.length];

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.014),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color(0xFF0D6E6E).withOpacity(0.08),
          highlightColor: const Color(0xFF0D6E6E).withOpacity(0.04),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: h * 0.016,
            ),
            child: Row(
              children: [
                // Number badge
                Container(
                  width: w * 0.12,
                  height: w * 0.12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      dua.id.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: w * 0.035),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arabic preview (right-aligned)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          getShortDescription(dua.tags),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A2B2B),
                            height: 1.4,
                          ),
                        ),
                      ),
                      SizedBox(height: h * 0.006),

                      // Category chip
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: w * 0.025,
                              vertical: h * 0.004,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D6E6E).withOpacity(0.09),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.label_rounded,
                                  size: w * 0.03,
                                  color: const Color(0xFF0D6E6E),
                                ),
                                SizedBox(width: w * 0.01),
                                Text(
                                  dua.categoryTitle,
                                  style: TextStyle(
                                    fontSize: w * 0.03,
                                    color: const Color(0xFF0D6E6E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: w * 0.02),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[350],
                  size: w * 0.055,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}