import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/masail_cubit.dart';
import '../model/masail_model.dart';
import 'package:muslim_app/utils/language_utils.dart';
import 'masail_detail_page.dart';
import 'category_masail_page.dart'; // MasailCard (public)

const Color _primary = Color(0xFF6B1E2E);

class AllMasailPage extends StatefulWidget {
  final String searchQuery;
  const AllMasailPage({super.key, required this.searchQuery});

  @override
  State<AllMasailPage> createState() => _AllMasailPageState();
}

class _AllMasailPageState extends State<AllMasailPage>
    with AutomaticKeepAliveClientMixin {
  List<MasailModel> allMasail = [];
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cubit = context.read<MasailCubit>();
    final data  = await cubit.repository.getAllMasail(
      languageCode: cubit.currentLanguageCode,
      userId:       cubit.userId,
    );
    if (mounted) setState(() { allMasail = data; isLoading = false; });
  }

  List<MasailModel> get _filtered {
    if (widget.searchQuery.isEmpty) return allMasail;
    final q = widget.searchQuery.toLowerCase();
    return allMasail.where((m) =>
    (m.arabic != null && m.arabic!.toLowerCase().contains(q)) ||
        m.question.toLowerCase().contains(q)                       ||
        m.answer.toLowerCase().contains(q)                         ||
        m.categoryTitle.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cubit = context.read<MasailCubit>();
    final isRtl = LanguageUtils.isRtl(cubit.currentLanguageCode);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
      );
    }

    if (_filtered.isEmpty) {
      return _AllMasailEmpty(w: w, h: h);
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: RefreshIndicator(
        color: _primary,
        onRefresh: _load,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.018, w * 0.04, h * 0.04),
          itemCount: _filtered.length,
          itemBuilder: (_, i) => MasailCard(
            masail: _filtered[i],
            index:  i,
            isRtl:  isRtl,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MasailDetailPage(masail: _filtered[i]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Empty state (local — _EmptyMasail in category_masail_page.dart is private) ─
class _AllMasailEmpty extends StatelessWidget {
  final double w, h;
  const _AllMasailEmpty({required this.w, required this.h});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(w * 0.06),
          decoration: const BoxDecoration(
            color: Color(0x146B1E2E),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.menu_book_rounded,
            size:  w * 0.14,
            color: _primary.withOpacity(0.4),
          ),
        ),
        SizedBox(height: h * 0.02),
        Text(
          'No Masail found',
          style: TextStyle(
            color:      const Color(0xFF9C7A82),
            fontSize:   w * 0.042,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}