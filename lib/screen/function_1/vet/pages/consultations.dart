import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/services/sign_in_provider.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/auth/authentication_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:poochpaw/screen/common/components/blur_bg.dart';

class ConsultationsScreen extends StatefulWidget {
  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
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

int getLabelValue(String category, String label) {
  final mapping = labelMappings[category];
  if (mapping != null) {
    return mapping.keys
        .firstWhere((key) => mapping[key] == label, orElse: () => -1);
  }
  return -1;
}

class _ConsultationsScreenState extends State<ConsultationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _rating = 0;
  String _comment = '';
  bool _isSendEnabled = false;
  String? _selectedOption;

  Stream<QuerySnapshot> _getConsultations() {
    final sp = context.read<SignInProvider>();
    final blocUser = context.read<AuthenticationBloc>().state.user;
    final doctorId = sp.doctorId ?? blocUser?.doctorId ?? '';

    return _firestore
        .collection('vet_consultations')
        .where('doctorId', isEqualTo: doctorId)
        .where('reviewed', isEqualTo: false)
        .snapshots();
  }

  Future<void> _updateConsultation(DocumentSnapshot consultation) async {
    String? mlIP = dotenv.env['MLIP']?.isEmpty ?? true
        ? dotenv.env['DEFAULT_IP']
        : dotenv.env['MLIP'];
    try {
      // Prepare the request for sentiment prediction
      final sentimentRequestBody = jsonEncode({"text": _comment});
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
          "Disease_Type":
              getLabelValue('Disease_Type', consultation['disease_result']),
          "Treatment": getLabelValue('Treatment', _selectedOption!),
          "Age_Years": consultation['dog_year'],
          "Breed": getLabelValue('Breed', consultation['dog_breed']),
          "Sentiment": getLabelValue('Sentiment', result),
          "Doctor_Rating": _rating,
        });
        print('Recovery Time Request Body: $recoveryRequestBody');
        print('sentiment: $result');

        final response_Cycle = await http.post(
          Uri.parse('http://$mlIP:8001/predict_recovery_time'),
          headers: {"Content-Type": "application/json"},
          body: recoveryRequestBody,
        );

        if (response_Cycle.statusCode == 200) {
          final responseCycleData = jsonDecode(response_Cycle.body);
          final resultCycle = responseCycleData["Predicted Recovery Time"];

          // Show the data in a dialog box for user to edit
          TextEditingController recoveryTimeController =
              TextEditingController(text: resultCycle);

          await showDialog(
            context: context,
            builder: (BuildContext context) {
              String updatedRecoveryTime = resultCycle;
              return AlertDialog(
                title: Text('Edit Recovery Time'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rating: $_rating'),
                    Text('Comment: ${_comment}'),
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
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Update Firestore document
                      await _firestore
                          .collection('vet_consultations')
                          .doc(consultation.id)
                          .update({
                        'reviewed': true,
                        'rating': _rating,
                        'comment': _comment,
                        'sentiment': result,
                        'treatment': _selectedOption,
                        'recovery_time':
                            int.tryParse(updatedRecoveryTime) ?? -1,
                      });

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Consultation updated successfully')),
                      );
                    },
                    child: Text('Save'),
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
  }

  void _updateSendButtonState() {
    setState(() {
      _isSendEnabled = _rating > 0 && _comment.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SignInProvider>();
    final blocUser = context.read<AuthenticationBloc>().state.user;
    String imageUrl =
        sp.imageUrl ?? blocUser?.image_url ?? 'assets/images/placeholder.png';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Vet Consultations',
        actionImage: null,
        onActionPressed: () {
          print("Action icon pressed");
        },
      ),
      extendBodyBehindAppBar: true,
      body: StreamBuilder<QuerySnapshot>(
        stream: _getConsultations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
              color: Color(nav),
            ));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No consultations found.'));
          }

          final consultations = snapshot.data!.docs;

          return Stack(
            children: [
              BackgroundWithBlur(
                child: SizedBox.expand(),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: consultations.length,
                      itemBuilder: (context, index) {
                        final consultation = consultations[index];
                        return GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (BuildContext context) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                          .viewInsets
                                          .bottom),
                                  child: StatefulBuilder(
                                    builder: (BuildContext context,
                                        StateSetter setState) {
                                      return Container(
                                        padding: EdgeInsets.all(16),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  const Text(
                                                    'User Name: ',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    '${consultation['user_name']}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  const Text(
                                                    'Disease:',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    '${consultation['disease_result']}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                    textAlign:
                                                        TextAlign.justify,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  const Text(
                                                    'Breed:',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    '${consultation['dog_breed']}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                    textAlign:
                                                        TextAlign.justify,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  const Text(
                                                    'Year:',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    '${consultation['dog_year']}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                    textAlign:
                                                        TextAlign.justify,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                                child: RatingBar.builder(
                                                  initialRating: _rating,
                                                  minRating: 1,
                                                  itemCount: 5,
                                                  itemSize: 30.0,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return Icon(Icons.star,
                                                        color: Color(nav));
                                                  },
                                                  onRatingUpdate: (rating) {
                                                    setState(() {
                                                      _rating = rating;
                                                      _updateSendButtonState();
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                onChanged: (value) {
                                                  setState(() {
                                                    _comment = value;
                                                    _updateSendButtonState();
                                                  });
                                                },
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Enter your review',
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              DropdownButtonFormField<String>(
                                                value: _selectedOption,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedOption = value;
                                                  });
                                                },
                                                items: [
                                                  DropdownMenuItem(
                                                    value:
                                                        'Anti-allergy medication',
                                                    child: Text(
                                                        'Anti-allergy medication'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'Antibiotics',
                                                    child: Text('Antibiotics'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value:
                                                        'Antifungal medication',
                                                    child: Text(
                                                        'Antifungal medication'),
                                                  ),
                                                ],
                                                decoration: InputDecoration(
                                                  labelText: 'Select an option',
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('Close'),
                                                  ),
                                                  TextButton(
                                                    onPressed: _isSendEnabled
                                                        ? () {
                                                            _updateConsultation(
                                                                consultation);
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          }
                                                        : null,
                                                    child: const Text('Send'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
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
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    NetworkImage(consultation['user_image']),
                              ),
                              title: Text(
                                consultation['user_name'],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Disease: ${consultation['disease_result']}',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.7)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
