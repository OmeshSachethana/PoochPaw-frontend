import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'dart:convert';

import 'package:poochpaw/screen/function_1/notify/line_chart_sample.dart';

class ConsultationDetailsModal extends StatefulWidget {
  final DocumentSnapshot consultation;
  final FirebaseFirestore firestore;

  const ConsultationDetailsModal({
    required this.consultation,
    required this.firestore,
    super.key,
  });

  @override
  _ConsultationDetailsModalState createState() =>
      _ConsultationDetailsModalState();
}

final labelMappings = {
  'Disease_Type': {
    0: 'Bacterial Dermatosis',
    1: 'Fungal Infections',
    2: 'Hypersensitivity Allergic'
  },
  'Treatment': {
    0: 'Anti-allergy medication',
    1: 'Antibiotics',
    2: 'Antifungal medication'
  },
  'Breed': {
    0: 'Beagle',
    1: 'Bulldog',
    2: 'German Shepherd',
    3: 'Labrador',
    4: 'Poodle'
  },
  'Sentiment': {0: 'negative', 1: 'neutral', 2: 'positive'},
  'Recovery Time (Weeks)': {
    0: '1 week',
    1: '2 weeks',
    2: '3 weeks',
    3: '4 weeks'
  }
};

// Get the label value from the label mappings
int getLabelValue(String category, String label) {
  final mapping = labelMappings[category];
  if (mapping != null) {
    return mapping.keys
        .firstWhere((key) => mapping[key] == label, orElse: () => -1);
  }
  return -1;
}

class _ConsultationDetailsModalState extends State<ConsultationDetailsModal> {
  final _commentController = TextEditingController();
  double _rating = 0;
  String? _selectedOption;
  late final Stream<QuerySnapshot> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _reviewsStream = widget.firestore
        .collection('vet_consultations')
        .doc(widget.consultation.id)
        .collection('reviews')
        .snapshots();
  }

  Future<void> _submitReview(String reviewId) async {
    String? mlIP = dotenv.env['MLIP']?.isEmpty ?? true
        ? dotenv.env['DEFAULT_IP']
        : dotenv.env['MLIP'];
    try {
      // Prepare the request for sentiment prediction
      final sentimentRequestBody =
          jsonEncode({"text": _commentController.text});
      print('Sentiment Request Body: $sentimentRequestBody');

      final response = await http.post(
        Uri.parse('http://$mlIP:8000/predict'), // ML endpoint URL
        headers: {"Content-Type": "application/json"},
        body: sentimentRequestBody,
      );

      if (response.statusCode == 200) {
        // Extract the sentiment result from the response
        final responseData = jsonDecode(response.body);
        final result = responseData['sentiment'];

        // Prepare the request for recovery time prediction
        final recoveryRequestBody = jsonEncode({
          "Disease_Type": getLabelValue(
              'Disease_Type', widget.consultation['disease_result']),
          "Treatment": getLabelValue('Treatment', _selectedOption!),
          "Age_Years": widget.consultation['dog_year'],
          "Breed": getLabelValue('Breed', widget.consultation['dog_breed']),
          "Sentiment": getLabelValue('Sentiment', result),
          "Doctor_Rating": _rating,
        });
        print('Recovery Time Request Body: $recoveryRequestBody');
        print('Sentiment: $result');

        final responseCycle = await http.post(
          Uri.parse('http://$mlIP:8001/predict_recovery_time'),
          headers: {"Content-Type": "application/json"},
          body: recoveryRequestBody,
        );

        if (responseCycle.statusCode == 200) {
          final responseCycleData = jsonDecode(responseCycle.body);
          final resultCycle = responseCycleData["Predicted Recovery Time"];

          // Show dialog with details
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              String updatedRecoveryTime = resultCycle;
              return AlertDialog(
                title: const Text('Review Details'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rating: $_rating'),
                    Text('Comment: ${_commentController.text}'),
                    Text('Sentiment: $result'),
                    Text('Treatment: $_selectedOption'),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Recovery Time',
                      ),
                      onChanged: (value) {
                        updatedRecoveryTime = value;
                      },
                      controller: TextEditingController(
                          text: resultCycle.replaceAll(' weeks', '')),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Update Firestore document
                      await widget.firestore
                          .collection('vet_consultations')
                          .doc(widget.consultation.id)
                          .collection('reviews')
                          .doc(
                              reviewId) // Ensure you're updating the correct review
                          .update({
                        'reviewed': true,
                        'rating': _rating,
                        'comment': _commentController.text,
                        'sentiment': result,
                        'treatment': _selectedOption,
                        'recovery_time':
                            int.tryParse(updatedRecoveryTime) ?? -1,
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Consultation updated successfully')),
                      );

                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        } else {
          throw Exception('Failed to get recovery time from ML endpoint');
        }
      } else {
        throw Exception('Failed to get sentiment from ML endpoint');
      }
    } catch (e) {
      print('Error updating consultation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update consultation: $e')),
      );
    }

    // Clear the text controller after submitting
    _commentController.clear();
    _rating = 0;

    Navigator.of(context).pop(); // Close the bottom sheet after submission
  }

  @override
  Widget build(BuildContext context) {
    final consultation = widget.consultation;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _reviewsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(nav)));
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final reviews = snapshot.data?.docs ?? [];
                return Stack(
                  children: [
                    BackgroundWithBlur(
                      child: SizedBox
                          .expand(), // Makes the blur cover the entire screen
                    ),
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Consultation Details',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...reviews.map((reviewDoc) {
                          final review =
                              reviewDoc.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Date:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      DateTime.fromMillisecondsSinceEpoch(
                                              review['timestamp']
                                                      ?.millisecondsSinceEpoch ??
                                                  0)
                                          .toLocal()
                                          .toIso8601String()
                                          .split('T')
                                          .first,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                      textAlign: TextAlign.justify,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      'Rating:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${review['rating']}' ?? "",
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.6)),
                                      textAlign: TextAlign.justify,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      'Recovery Time:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${review['recovery_time'] ?? ""} weeks',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.6)),
                                      textAlign: TextAlign.justify,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: Image.network(
                                    review['image_url'],
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (!review['reviewed'])
                                  RatingBar.builder(
                                    initialRating: _rating,
                                    minRating: 1,
                                    itemCount: 5,
                                    itemSize: 30,
                                    itemBuilder: (context, index) {
                                      return const Icon(Icons.star,
                                          color: Color(nav));
                                    },
                                    onRatingUpdate: (rating) {
                                      setState(() {
                                        _rating = rating;
                                      });
                                    },
                                  ),
                                const SizedBox(height: 12),
                                if (!review['reviewed'])
                                  TextFormField(
                                    controller: _commentController,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: "Enter your comment",
                                      labelStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.7)),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        // Handle comment update
                                      });
                                    },
                                  ),
                                const SizedBox(height: 10),
                                if (!review['reviewed'])
                                  Container(
                                    child: DropdownButtonFormField<String>(
                                      dropdownColor: Colors.grey[800],
                                      value: _selectedOption,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedOption = value;
                                        });
                                      },
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Anti-allergy medication',
                                          child:
                                              Text('Anti-allergy medication'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Antibiotics',
                                          child: Text('Antibiotics'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Antifungal medication',
                                          child: Text('Antifungal medication'),
                                        ),
                                      ],
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Select an option',
                                        labelStyle: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7)),
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.1),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                SizedBox(height: 15),
                                if (!review['reviewed'])
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 24),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        primary: Colors.white.withOpacity(0.3),
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                      ),
                                      onPressed: () {
                                        _submitReview(reviewDoc.id);
                                      },
                                      child: const Text(
                                        'Send',
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
                          );
                        }).toList(),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Date:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        DateTime.fromMillisecondsSinceEpoch(
                                                consultation['timestamp']
                                                        ?.millisecondsSinceEpoch ??
                                                    0)
                                            .toLocal()
                                            .toIso8601String()
                                            .split('T')
                                            .first,
                                        style: TextStyle(
                                            fontSize: 16,
                                            color:
                                                Colors.white.withOpacity(0.6)),
                                        textAlign: TextAlign.justify,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        'Rating:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${consultation['rating']}',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color:
                                                Colors.white.withOpacity(0.6)),
                                        textAlign: TextAlign.justify,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        'Recovery Time:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${consultation['recovery_time'] ?? ""} weeks',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color:
                                                Colors.white.withOpacity(0.6)),
                                        textAlign: TextAlign.justify,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
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
                                  FutureBuilder<List<FlSpot>>(
                                    future: _getProgressSpots(consultation.id),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      }
                                      if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      }

                                      final spots = snapshot.data ?? [];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 20),
                                        child: Container(
                                          height: 200,
                                          color: Colors.white,
                                          child: LineChartSample2(spots: spots),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<FlSpot>> _getProgressSpots(String consultationId) async {
  final spots = <FlSpot>[];
  try {
    print(
        'Fetching vet consultation details for consultation ID: $consultationId');

    // Fetch vet consultation document
    final consultationDoc = await FirebaseFirestore.instance
        .collection('vet_consultations')
        .doc(consultationId)
        .get();

    if (consultationDoc.exists) {
      final consultationData = consultationDoc.data() as Map<String, dynamic>;
      final rating = consultationData['rating']?.toDouble() ?? 0;
      final recoveryTime = consultationData['recovery_time']?.toDouble() ?? 0;

      print(
          'Fetched consultation details: rating: $rating, recovery_time: $recoveryTime');

      // Add the consultation data to the spots list
      spots.add(FlSpot(recoveryTime, rating));

      // Fetch reviews collection
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('vet_consultations')
          .doc(consultationId)
          .collection('reviews')
          .orderBy('timestamp', descending: false)
          .get();

      print(
          'Reviews snapshot fetched. Number of documents: ${reviewsSnapshot.docs.length}');

      double cumulativeWeeks = recoveryTime;
      for (var reviewDoc in reviewsSnapshot.docs) {
        final review = reviewDoc.data() as Map<String, dynamic>;
        final reviewRating = review['rating']?.toDouble() ?? 0;
        final reviewWeeks = review['recovery_time']?.toDouble() ?? 0;

        // Adjust cumulative weeks by adding the current review recovery time
        cumulativeWeeks += reviewWeeks;

        print(
            'Retrieved review rating: $reviewRating, cumulative weeks: $cumulativeWeeks'); // Debug print

        // Add adjusted review data to the spots list
        spots.add(FlSpot(cumulativeWeeks, reviewRating));
      }
    } else {
      print('Consultation document not found.');
    }

    print('Spots: $spots');
  } catch (e) {
    print('Error fetching progress spots: $e');
  }
  return spots;
}
