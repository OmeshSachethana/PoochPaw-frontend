import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'line_chart_sample.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ConsultationsList extends StatelessWidget {
  final List<QueryDocumentSnapshot> consultations;

  ConsultationsList({required this.consultations});

  //get doctor details from doctorId in consultation
  Future<DocumentSnapshot?> _getDoctorDetails(String doctorId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('doctorId', isEqualTo: doctorId)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    }
    return null;
  }

  Future<void> _updatePhoto(
    BuildContext context,
    QueryDocumentSnapshot consultation,
  ) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
      return;
    }

    try {
      final file = File(image.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('vet_consultations')
          .child('${consultation.id}')
          .child('review_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(file);

      // Show CircularProgressIndicator while uploading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFF08950),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Uploading image...'),
                ],
              ),
            ),
          );
        },
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Add a new review document to the 'reviews' subcollection
      final reviewRef = FirebaseFirestore.instance
          .collection('vet_consultations')
          .doc(consultation.id)
          .collection('reviews')
          .doc();

      await reviewRef.set({
        'image_url': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'comment': '',
        'reviewed': false,
        'rating': '',
        'sentiment': '',
      });

      Navigator.pop(context); // Close the CircularProgressIndicator dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo updated successfully.')),
      );
    } catch (e) {
      Navigator.pop(context); // Close the CircularProgressIndicator dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: consultations.length,
      itemBuilder: (context, index) {
        final consultation = consultations[index];
        return FutureBuilder<DocumentSnapshot?>(
          future: _getDoctorDetails(consultation['doctorId']),
          builder: (context, doctorSnapshot) {
            if (doctorSnapshot.hasError) {
              return Center(child: Text('Error: ${doctorSnapshot.error}'));
            }

            final doctorData =
                doctorSnapshot.data?.data() as Map<String, dynamic>?;
            final doctorName = doctorData != null
                ? '${doctorData['name']} ${doctorData['lastName']}'
                : 'Unknown Doctor';
            final doctorImageUrl = doctorData != null
                ? doctorData['image_url']
                : 'assets/images/placeholder.png';

            return GestureDetector(
              onTap: () {
                showFlexibleBottomSheet(
                  bottomSheetColor: Colors.transparent.withOpacity(0.4),
                  minHeight: 0,
                  initHeight: 0.7,
                  maxHeight: 1,
                  context: context,
                  builder: (context, scrollController, bottomSheetOffset) =>
                      buildBottomSheet(
                          context, scrollController, consultation, doctorName),
                  anchors: [0, 0.5, 1],
                  isSafeArea: true,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                padding: const EdgeInsets.all(10),
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
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(doctorImageUrl),
                  ),
                  title: Text(
                    doctorName,
                    style: const TextStyle(
                        color: Color(nav), fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Disease: ${consultation['disease_result']}',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildBottomSheet(
    BuildContext context,
    ScrollController scrollController,
    QueryDocumentSnapshot consultation,
    String doctorName,
  ) {
    Future<List<FlSpot>> _getProgressSpots(String consultationId) async {
      final spots = <FlSpot>[];
      try {
        // Fetch consultation document
        final consultationDoc = await FirebaseFirestore.instance
            .collection('vet_consultations')
            .doc(consultationId)
            .get();

        if (consultationDoc.exists) {
          final consultationData =
              consultationDoc.data() as Map<String, dynamic>;
          final double rating =
              double.tryParse(consultationData['rating']?.toString() ?? '') ??
                  0.0;
          final double recoveryTime = double.tryParse(
                  consultationData['recovery_time']?.toString() ?? '') ??
              0.0;

          spots.add(FlSpot(recoveryTime, rating));

          // Fetch reviews collection
          final reviewsSnapshot = await FirebaseFirestore.instance
              .collection('vet_consultations')
              .doc(consultationId)
              .collection('reviews')
              .orderBy('timestamp', descending: false)
              .get();

          double cumulativeWeeks = recoveryTime;
          for (var reviewDoc in reviewsSnapshot.docs) {
            final review = reviewDoc.data() as Map<String, dynamic>;
            final reviewRating = review['rating']?.toDouble() ?? 0;
            final reviewWeeks = review['recovery_time']?.toDouble() ?? 0;

            cumulativeWeeks += reviewWeeks;
            spots.add(FlSpot(cumulativeWeeks, reviewRating));
          }
        }
      } catch (e) {
        print('Error fetching progress spots: $e');
      }
      return spots;
    }

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  Text(
                    'Dr. $doctorName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(nav),
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('vet_consultations')
                        .doc(consultation.id)
                        .collection('reviews')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      final reviews = snapshot.data?.docs ?? [];
                      return Column(
                        children: reviews.map((reviewDoc) {
                          final review =
                              reviewDoc.data() as Map<String, dynamic>;
                          final imageUrl = review['image_url'];
                          final rating = review['rating'] is String &&
                                  review['rating'].isEmpty
                              ? 0.0
                              : (review['rating']?.toDouble() ?? 0.0);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey, // Color of the border
                                  width: 1.0, // Border width
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    if (imageUrl.isNotEmpty)
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        clipBehavior: Clip.hardEdge,
                                        child: Image.network(
                                          review['image_url'],
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 10),
                                        Center(
                                          child: RatingBarIndicator(
                                            rating: rating,
                                            itemBuilder: (context, index) =>
                                                const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ),
                                            itemCount: 5,
                                            itemSize: 30.0,
                                            direction: Axis.horizontal,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Text(
                                              'Disease:',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              '${consultation['disease_result']}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey[600],
                                              ),
                                              textAlign: TextAlign.justify,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Text(
                                              'Treatment:',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              review['treatment']?.isNotEmpty ==
                                                      true
                                                  ? '${review['treatment']}'
                                                  : 'Pending review',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey[600],
                                              ),
                                              textAlign: TextAlign.justify,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Review:',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                review['comment']?.isNotEmpty ==
                                                        true
                                                    ? '${review['comment']}'
                                                    : 'Pending review',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey[700],
                                                ),
                                                maxLines: 99999,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.justify,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Text(
                                              'Sentiment:',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              review['sentiment']?.isNotEmpty ==
                                                      true
                                                  ? '${review['sentiment'][0].toUpperCase()}${review['sentiment'].substring(1)}'
                                                  : 'Pending review',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey[600],
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const SizedBox(height: 10),
                                            Text(
                                              'Predicting Cycle:',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              '${review['recovery_time']} Week',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey[600],
                                              ),
                                              textAlign: TextAlign.justify,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey, // Color of the border
                        width: 1.0, // Border width
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Image.network(
                              consultation['image_url'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: RatingBarIndicator(
                              rating: consultation['rating'].toDouble(),
                              itemBuilder: (context, index) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 30.0,
                              direction: Axis.horizontal,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                'Disease:',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${consultation['disease_result']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                'Treatment:',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${consultation['treatment']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Review:',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${consultation['comment']}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 99999,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                'Sentiment:',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${consultation['sentiment'][0].toUpperCase()}${consultation['sentiment'].substring(1)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const SizedBox(height: 10),
                              Text(
                                'Predicting Cycle:',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${consultation['recovery_time']} Week',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<FlSpot>>(
                    future: _getProgressSpots(consultation.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      final spots = snapshot.data ?? [];
                      return Container(
                        height: 200,
                        color: Colors.white,
                        child: LineChartSample2(spots: spots),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  primary: Colors.white.withOpacity(0.3),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                onPressed: () => _updatePhoto(context, consultation),
                child: const Text(
                  'Request Another Review',
                  style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
