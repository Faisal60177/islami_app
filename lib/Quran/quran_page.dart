import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:qcf_quran/qcf_quran.dart';


class QuranPage extends StatefulWidget {
  const QuranPage({Key? key}) : super(key: key);

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final PdfViewerController _controller = PdfViewerController();
  final int totalPages = 619; // total pages of your PDF
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    // Jump to first page after widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.jumpToPage(currentPage);
    });
  }

  void _goNextPage() {
    if (currentPage < totalPages) {
      currentPage++;
      _controller.jumpToPage(currentPage);
    }
  }

  void _goPreviousPage() {
    if (currentPage > 1) {
      currentPage--;
      _controller.jumpToPage(currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Al Quran"),
        centerTitle: true,
        actions: [
          // Show current page
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "$currentPage / $totalPages",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: SfPdfViewer.asset(
        'assets/pdf/quran.pdf',
        controller: _controller,
        scrollDirection: PdfScrollDirection.horizontal, // horizontal swipe
        pageLayoutMode: PdfPageLayoutMode.single, // one page at a time
        canShowScrollHead: false,    // hide top page bar
        canShowScrollStatus: false,  // hide bottom page number
        onPageChanged: (details) {
          setState(() {
            currentPage = details.newPageNumber; // update current page
          });
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 30), // spacing from edge
          FloatingActionButton(
            heroTag: "prevBtn",
            onPressed: _goPreviousPage,
            child: const Icon(Icons.arrow_back),
          ),
          FloatingActionButton(
            heroTag: "nextBtn",
            onPressed: _goNextPage,
            child: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}