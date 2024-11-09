import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

Future<void> savePdf(String petId, BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Downloading PDF..."),
            ],
          ),
        ),
      );
    },
  );

  try {
    final petReport = await FirebaseFirestore.instance
        .collection('pet-reports')
        .doc(petId)
        .get();

    final data = petReport.data();

    if (data != null) {
      final PdfDocument document = PdfDocument();

      final PdfPage page = document.pages.add();

      final PdfGraphics graphics = page.graphics;

      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);

      graphics.drawString(
        'Report Structure for Dog ID ${data['dog_id']}: Dog\'s Health and Activity Monitoring',
        font,
        bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
      );

      graphics.drawString(
        'DOG ID ${data['dog_id']} DETAILS:',
        font,
        bounds: Rect.fromLTWH(0, 60, page.getClientSize().width, 30),
      );

      graphics.drawString(
        '1. Dog\'s Profile\n'
        '• Breed: ${data['breed'] ?? "N/A"}\n'
        '• Age: ${data['ageMonths'] ?? "N/A"} Months\n'
        '• Weight: ${data['weightLb'] ?? "N/A"} lbs (${(data['weightLb'] ?? 0 * 0.453592).toStringAsFixed(2)} Kilograms)\n'
        '• Gender: ${data['gender'] ?? "N/A"}',
        font,
        bounds: Rect.fromLTWH(0, 100, page.getClientSize().width, 100),
      );

      graphics.drawString(
        '2. Health and Activity Data\n'
        '• Normal Heartbeat: ${data['heart_beat'] ?? "N/A"} BPM\n'
        '• Exercise Time:\n'
        '  o Recommended: ${data['recommendationTime'] ?? "N/A"} Minutes\n'
        '  o Actual: ${data['actualTime'] ?? "N/A"} Minutes',
        font,
        bounds: Rect.fromLTWH(0, 200, page.getClientSize().width, 200),
      );

      final directory = await getExternalStorageDirectory();
      final outputFilePath = '${directory?.path}/Download/pet_id_$petId.pdf';

      final downloadDir = Directory('${directory?.path}/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final file = File(outputFilePath);
      Uint8List pdfBytes = Uint8List.fromList(await document.save());

      await file.writeAsBytes(pdfBytes);

      // Upload PDF to Firebase Storage
      final storageRef =
          FirebaseStorage.instance.ref().child('pet_reports/$petId.pdf');
      final uploadTask = await storageRef.putData(pdfBytes);

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update Firestore with the download URL
      await FirebaseFirestore.instance
          .collection('pet-reports')
          .doc(petId)
          .set({
        'pdfUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('PDF saved to $outputFilePath and uploaded to Firebase Storage.');

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF downloaded successfully!'),
          backgroundColor: Color(nav),
        ),
      );
    } else {
      print('No data found for pet ID: $petId');
      Navigator.of(context).pop();
    }
  } catch (e) {
    print('Error creating PDF: $e');
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to download PDF. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void generatePdfReport(Map<String, dynamic> data, PdfDocument document) {
  // Add a page to the document
  final PdfPage page = document.pages.add();
  final PdfGraphics graphics = page.graphics;

  // Define fonts with different sizes for titles, sections, and content
  final PdfFont titleFont =
      PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
  final PdfFont sectionFont =
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
  final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 12);

  // Define colors
  final PdfBrush titleBrush = PdfSolidBrush(PdfColor(34, 40, 49)); // Dark Gray
  final PdfBrush sectionBrush =
      PdfSolidBrush(PdfColor(57, 62, 70)); // Medium Gray
  final PdfBrush contentBrush =
      PdfSolidBrush(PdfColor(100, 120, 140)); // Light Gray

  // Define section and content padding
  const double sectionPadding = 50.0;
  const double contentPadding = 20.0;

  // Title
  graphics.drawString(
    'Dog Health and Activity Report for ID: ${data['dog_id']}',
    titleFont,
    brush: titleBrush,
    bounds: Rect.fromLTWH(0, 20, page.getClientSize().width, 30),
    format: PdfStringFormat(alignment: PdfTextAlignment.center),
  );

  // Section 1: Dog Profile
  graphics.drawString(
    '1. Dog Profile',
    sectionFont,
    brush: sectionBrush,
    bounds: Rect.fromLTWH(0, 80, page.getClientSize().width, 20),
    format: PdfStringFormat(alignment: PdfTextAlignment.left),
  );
  graphics.drawString(
    '• Breed: ${data['breed'] ?? "N/A"}\n'
    '• Age: ${data['ageMonths'] ?? "N/A"} months\n'
    '• Weight: ${data['weightLb'] ?? "N/A"} lbs (${(data['weightLb'] ?? 0 * 0.453592).toStringAsFixed(2)} kg)\n'
    '• Gender: ${data['gender'] ?? "N/A"}',
    contentFont,
    brush: contentBrush,
    bounds: Rect.fromLTWH(0, 110, page.getClientSize().width, 80),
    format: PdfStringFormat(alignment: PdfTextAlignment.left),
  );

  // Section 2: Health and Activity Data
  graphics.drawString(
    '2. Health and Activity Data',
    sectionFont,
    brush: sectionBrush,
    bounds: Rect.fromLTWH(0, 200, page.getClientSize().width, 20),
    format: PdfStringFormat(alignment: PdfTextAlignment.left),
  );
  graphics.drawString(
    '• Heartbeat: ${data['heart_beat'] ?? "N/A"} BPM\n'
    '• Recommended Exercise Time: ${data['recommendationTime'] ?? "N/A"} min\n'
    '• Actual Exercise Time: ${data['actualTime'] ?? "N/A"} min',
    contentFont,
    brush: contentBrush,
    bounds: Rect.fromLTWH(0, 230, page.getClientSize().width, 80),
    format: PdfStringFormat(alignment: PdfTextAlignment.left),
  );

  // Add spacing between sections
  const double sectionSpacing = 30;
  graphics.drawString(
    '3. Additional Information',
    sectionFont,
    brush: sectionBrush,
    bounds: Rect.fromLTWH(0, 320, page.getClientSize().width, 20),
    format: PdfStringFormat(alignment: PdfTextAlignment.left),
  );
  graphics.drawString(
    '• Comments: ${data['comments'] ?? "No additional comments"}',
    contentFont,
    brush: contentBrush,
    bounds: Rect.fromLTWH(0, 350, page.getClientSize().width, 60),
    format: PdfStringFormat(alignment: PdfTextAlignment.left),
  );
}

Future<void> showLoadingDialog(BuildContext context, String message) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void openPdfViewer(BuildContext context, String pdfUrl) {
  // Open the PDF or use a package to display the PDF in-app
  print("Opening PDF from URL: $pdfUrl");
}
