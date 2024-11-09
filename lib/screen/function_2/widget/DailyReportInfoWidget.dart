import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/screen/function_2/full_report_screen.dart';

class DailyReportInfoWidget extends StatelessWidget {
  final String uid;
  final String petId;

  const DailyReportInfoWidget({
    Key? key,
    required this.uid,
    required this.petId,
  }) : super(key: key);

  Future<List<String>> fetchBehaviorLabels() async {
    final now = DateTime.now();
    final dateStr = DateTime(now.year, now.month, now.day)
        .toIso8601String()
        .split('T')
        .first;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('petBehavior')
        .doc(petId)
        .collection(dateStr)
        .doc('behaviorData');

    try {
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final behaviorIndexes = data?['behaviorIndexes'] as List<dynamic>?;
        if (behaviorIndexes != null) {
          return behaviorIndexes
              .map((item) => behaviorMapping[item as int] ?? 'Unknown')
              .toList();
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching behavior data: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: fetchBehaviorLabels(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
              ),
            ),
          );
        }

        final behaviorList = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullReportScreen(
                      petId: petId,
                      uid: uid,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                primary: Colors.white.withOpacity(0.3),
                elevation: 0,
                shadowColor: Colors.transparent,
                minimumSize: Size(double.infinity, 50),
              ),
              icon: Icon(Icons.arrow_forward, color: Colors.white),
              label: Text(
                'Goto Full Report',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBehaviorList(List<String>? behaviorList) {
    if (behaviorList == null || behaviorList.isEmpty) {
      return _buildBehaviorRow('Behavior Summary', 'No data available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Behaviors Done:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(nav),
          ),
        ),
        SizedBox(height: 10),
        ...behaviorList.map((behavior) => Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '• $behavior',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            )),
      ],
    );
  }

  Widget _buildBehaviorRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blueAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: ${value ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Define your behavior mapping
const Map<int, String> behaviorMapping = {
  0: 'Bowing',
  1: 'Carrying object',
  2: 'Drinking',
  3: 'Eating',
  4: 'Galloping',
  5: 'Jumping',
  6: 'Lying chest',
  7: 'Pacing',
  8: 'Panting',
  9: 'Playing',
  10: 'Shaking',
  11: 'Sitting',
  12: 'Sniffing',
  13: 'Standing',
  14: 'Trotting',
  15: 'Tugging',
  16: 'Walking'
};
