import fitz   # PyMuPDF
import os
import sys

# ─────────────────────────────────────────────────────────────
#  EDIT THESE TWO LINES TO MATCH YOUR COMPUTER
# ─────────────────────────────────────────────────────────────

PDF_PATH = r"F:\Projects\islamic_app\quran_hifz.pdf"
# Replace with the actual path to your PDF file
# Example: r"C:\Users\Ahmed\Desktop\quran_15lines.pdf"

OUT_DIR = r"F:\Projects\islamic_app\assets\quran\pages"
# Replace with the path to your Flutter project's assets folder
# Example: r"C:\Users\Ahmed\AndroidStudioProjects\islamic_app\assets\quran\pages"

# ─────────────────────────────────────────────────────────────
#  SETTINGS — do not change unless needed
# ─────────────────────────────────────────────────────────────

DPI          = 200    # 200 is sharp enough for phones, keeps file size small
                      # Use 300 for very high quality (larger files)
JPEG_QUALITY = 88     # 88 is excellent quality. Use 75 to save space.

# ─────────────────────────────────────────────────────────────
#  SCRIPT — do not edit below this line
# ─────────────────────────────────────────────────────────────

def main():
    # Check PDF exists
    if not os.path.exists(PDF_PATH):
        print(f"\n  ERROR: PDF not found at:\n  {PDF_PATH}")
        print("\n  Please check the PDF_PATH at the top of this script.")
        input("\n  Press Enter to close...")
        sys.exit(1)

    # Create output folder if it doesn't exist
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f"\n  Output folder: {OUT_DIR}")

    # Open PDF
    doc = fitz.open(PDF_PATH)
    total = len(doc)
    print(f"  PDF has {total} pages total")
    print(f"  Saving all {total} pages as images (001.jpg to {total:03d}.jpg)")
    print(f"  DPI: {DPI}  |  JPEG quality: {JPEG_QUALITY}")
    print(f"\n  Starting conversion...\n")

    matrix = fitz.Matrix(DPI / 72, DPI / 72)
    saved  = 0
    skipped = 0

    for i, page in enumerate(doc):
        page_num = i + 1
        filename = f"{page_num:03d}.jpg"
        out_path = os.path.join(OUT_DIR, filename)

        # Skip if file already exists (resume support)
        if os.path.exists(out_path):
            skipped += 1
            print(f"  skip  [{page_num:03d}/{total}] {filename} (already exists)")
            continue

        # Render page to image
        pix = page.get_pixmap(matrix=matrix, alpha=False)

        # Save as JPEG
        pix.save(out_path, jpg_quality=JPEG_QUALITY)
        saved += 1

        size_kb = os.path.getsize(out_path) // 1024
        print(f"  saved [{page_num:03d}/{total}] {filename}  "
              f"{pix.width}x{pix.height}px  {size_kb} KB")

    doc.close()

    print(f"\n  ─────────────────────────────────")
    print(f"  Done!")
    print(f"  Saved:   {saved} new images")
    print(f"  Skipped: {skipped} (already existed)")
    print(f"  Total:   {total} images in {OUT_DIR}")
    print(f"  ─────────────────────────────────")
    print(f"\n  Now run: flutter pub get")
    print(f"  Then build your app normally.\n")
    input("  Press Enter to close...")

if __name__ == "__main__":
    main()