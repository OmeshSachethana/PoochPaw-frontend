import 'dart:io';
import 'package:flutter/material.dart';
import 'package:poochpaw/core/services/database.dart';
import 'package:side_sheet/side_sheet.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiseasePrediction extends StatelessWidget {
  final String? diseaseResult;
  final File? selectedImage;
  final double? confidenceScore;

  DiseasePrediction(
      {this.diseaseResult, this.selectedImage, this.confidenceScore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (diseaseResult != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              width: 400,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Disease: $diseaseResult',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Text(
                  //   'Confidence Score: $confidenceScore',
                  //   style: TextStyle(
                  //     fontSize: 16,
                  //     fontFamily: 'Nunito',
                  //     fontWeight: FontWeight.bold,
                  //     color: Colors.white.withOpacity(0.9),
                  //   ),
                  //   textAlign: TextAlign.center,
                  // ),
                  const SizedBox(height: 20),
                  Divider(color: Color(cards), thickness: 2),
                  Text(
                    'Suggested Remedies:',
                    style: TextStyle(
                      fontSize: 17,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    child: Text(
                      _getRandomRemediesForDisease(diseaseResult!),
                      style: TextStyle(
                        fontSize: 17,
                        fontFamily: 'Nunito',
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Only show "Send to Vet" button if disease is not "Healthy"
            if (diseaseResult != 'Healthy')
              Center(
                child: ElevatedButton(
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
                  onPressed: () => _showDogDetailsDialog(context),
                  child: Text(
                    'Send to Vet',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9), // Changed color
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _getRandomRemediesForDisease(String disease) {
    final remedies = {
      'Bacterial Dermatosis': [
        'Regularly clean the affected area.',
        'Apply prescribed ointments.',
        'Avoid allergens.',
        'Use antibacterial soap.',
        'Consult your vet for antibiotics.',
      ],
      'Healthy': [
        'Ensure your dog is getting regular exercise.',
        'Provide a balanced diet with proper nutrition.',
        'Maintain good hygiene and grooming.',
        'Keep vaccinations up to date.',
        'Schedule routine check-ups with the vet.',
      ],
      'default': [
        'Consult with a vet for proper diagnosis and treatment.',
        'Ensure a clean environment for your pet.',
        'Monitor the affected area regularly.',
      ],
    };

    final selectedRemedies = remedies[disease] ?? remedies['default'];
    selectedRemedies?.shuffle();

    return selectedRemedies!.take(5).join('\n');
  }

  void _showDogDetailsDialog(BuildContext context) {
    String? dogYear;
    String? dogBreed;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Dog Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Dog Year'),
                onChanged: (value) {
                  dogYear = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Dog Breed'),
                onChanged: (value) {
                  dogBreed = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Next'),
              onPressed: () {
                Navigator.pop(context);
                if (dogYear != null && dogBreed != null) {
                  _showVetSelectionSheet(context, dogYear, dogBreed);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showVetSelectionSheet(
      BuildContext context, String? dogYear, String? dogBreed) {
    String? selectedVetId; // Track the selected vet ID

    SideSheet.right(
      context: context,
      width: MediaQuery.of(context).size.width * 0.7,
      body: StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a Vet',
                  style: TextStyle(
                    color: Color(nav),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(color: Colors.grey),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'Vet')
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final vets = snapshot.data!.docs;

                      if (vets.isEmpty) {
                        return Center(child: Text('No vets available'));
                      }

                      return ListView.builder(
                        itemCount: vets.length,
                        itemBuilder: (context, index) {
                          final vet = vets[index];
                          final isSelected = vet.id == selectedVetId;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedVetId =
                                      null; // Deselect if already selected
                                } else {
                                  selectedVetId = vet.id; // Select the vet
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Color(nav)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(vet['image_url']),
                                ),
                                title: Text(
                                  '${vet['name']} ${vet['lastName']}'
                                      .toUpperCase(),
                                  style: isSelected
                                      ? TextStyle(color: Colors.white)
                                      : null,
                                ),
                                subtitle: Text(
                                  'ID: ${vet['doctorId']}',
                                  style: isSelected
                                      ? TextStyle(color: Colors.white)
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Divider(color: Colors.grey),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text('Cancel'),
                      style: TextButton.styleFrom(primary: Color(nav)),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: Text('Send'),
                      onPressed: selectedVetId == null
                          ? null
                          : () async {
                              Navigator.pop(context);
                              try {
                                await DatabaseMethods().sendToVet(
                                  selectedImage: selectedImage!,
                                  diseaseResult: diseaseResult!,
                                  vetId: selectedVetId!,
                                  dogYear: dogYear!,
                                  dogBreed: dogBreed!,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Data sent to vet successfully'),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to send data to vet'),
                                  ),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
