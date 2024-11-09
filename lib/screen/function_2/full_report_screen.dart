import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/screen/function_2/widget/appbar.dart';
import 'package:poochpaw/screen/function_3/components/line_chart.dart';

class FullReportScreen extends StatelessWidget {
  final String uid;
  final String petId;

  const FullReportScreen({required this.petId, required this.uid, super.key});

  Future<List<Map<String, dynamic>>> fetchBehaviorData() async {
    final now = DateTime.now();
    final dateStrList = List.generate(3, (index) {
      final date = now.subtract(Duration(days: index));
      return DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .split('T')
          .first;
    });

    final behaviorData = <Map<String, dynamic>>[];

    for (final dateStr in dateStrList) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('petBehavior')
          .doc(petId)
          .collection(dateStr)
          .doc('behaviorData');

      try {
        print('Fetching data from $docRef');
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          print('Data for $dateStr: $data');
          if (data != null) {
            final behaviors = data['behaviors'] as List<dynamic>? ?? [];
            final behaviorLabels = behaviors.map((item) {
              final index = item['index'] as int?;
              final label = behaviorMapping[index] ?? 'Unknown';
              return {'label': label}; // Remove duration
            }).toList();
            behaviorData.add({
              'date': dateStr,
              'behaviors': behaviorLabels,
            });
          } else {
            print('No data found for $dateStr');
          }
        } else {
          print('No document found for $dateStr');
        }
      } catch (e) {
        print('Error fetching behavior data for $dateStr: $e');
      }
    }

    print('Fetched behavior data: $behaviorData');
    return behaviorData;
  }

  Future<void> generateAndDownloadPDF(
      List<Map<String, dynamic>> behaviorData) async {
    final pdf = PdfDocument();
    final page = pdf.pages.add();

    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final titleFont =
        PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);

    // Add Title
    page.graphics.drawString('Full Report', titleFont,
        bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 30));

    // Add Data
    double yPosition = 40;
    for (final data in behaviorData) {
      final date = data['date'];
      final behaviors = data['behaviors'] as List<Map<String, dynamic>>;

      page.graphics.drawString('Date: $date', titleFont,
          bounds: Rect.fromLTWH(0, yPosition, page.getClientSize().width, 30));
      yPosition += 30;

      if (behaviors.isNotEmpty) {
        for (final behavior in behaviors) {
          final label = behavior['label'] as String;

          page.graphics.drawString('- $label', font,
              bounds:
                  Rect.fromLTWH(0, yPosition, page.getClientSize().width, 30));
          yPosition += 20;
        }
      } else {
        page.graphics.drawString('- No behaviors recorded', font,
            bounds:
                Rect.fromLTWH(0, yPosition, page.getClientSize().width, 30));
        yPosition += 20;
      }

      yPosition += 10; // Add extra space between dates
    }

    // Save PDF
    final pdfHelper = PdfHelper();
    final path = await pdfHelper.savePdf(pdf);

    // Notify the user
    print('PDF saved to $path');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Full Report',
        leadingImage: 'assets/icons/Back.png',
        actionImage: null,
        onLeadingPressed: () {
          Navigator.of(context).pop();
        },
        onActionPressed: () {
          print("Action icon pressed");
        },
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          BackgroundWithBlur(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchBehaviorData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No behavior data available.'));
                } else {
                  final behaviorData = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      top: 90.0,
                      bottom: 50.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // _buildHeader(),
                        const SizedBox(height: 16),
                        Text(
                          'Behavior',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.7)),
                        ),
                        const SizedBox(height: 16),
                        Expanded(child: _buildBehaviorList(behaviorData)),
                        const SizedBox(height: 16),
                        const Text(
                          'Heart Rate',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(nav)),
                        ),
                        const SizedBox(height: 16),
                        HeartbeatChart(petId: petId),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await generateAndDownloadPDF(behaviorData);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PDF downloaded successfully!'),
                                ),
                              );
                            },
                            icon:
                                const Icon(Icons.download, color: Colors.white),
                            label: const Text(
                              'Download Report',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              primary: Colors.white.withOpacity(0.3),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text('Last Day', style: TextStyle(fontSize: 16)),
        const Spacer(),
        Text(DateFormat('dd/MM/yyyy').format(DateTime.now()),
            style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildBehaviorList(List<Map<String, dynamic>> behaviorData) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: behaviorData.length,
      itemBuilder: (context, index) {
        final data = behaviorData[index];
        final date = data['date'];
        final behaviors = data['behaviors'] as List<Map<String, dynamic>>;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: $date',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: behaviors.map((behavior) {
                      final label = behavior['label'] as String;

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_right,
                              size: 16,
                              color: Color(nav),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '$label',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.5)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Define your behavior mapping
const Map<int, String> behaviorMapping = {
  0: 'Eating',
  1: 'Galloping',
  2: 'Jumping',
  3: 'Lying on chest',
  4: 'Panting',
  5: 'Shaking',
  6: 'Sitting',
  7: 'Sleeping',
  8: 'Sniffing',
  9: 'Standing',
  10: 'Walking',
};

class PdfHelper {
  Future<String> savePdf(PdfDocument pdf) async {
    final output = await _getOutputFile();
    final file = File(output);
    await file.writeAsBytes(await pdf.save());
    return output;
  }

  Future<String> _getOutputFile() async {
    final directory = await getExternalStorageDirectory();
    final path =
        '${directory?.path}/full_report_${DateTime.now().toIso8601String()}.pdf';
    return path;
  }
}
