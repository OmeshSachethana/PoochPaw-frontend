import 'package:flutter/material.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/screen/function_2/service/ml_service.dart';
import 'package:poochpaw/screen/function_2/service/notification.dart';
import 'package:poochpaw/screen/function_2/service/pet_overview_data_stream.dart';

class AnomalyWidget extends StatelessWidget {
  final String petId;
  final String gender;
  final String petAge;
  final String breed;
  final String uid;

  const AnomalyWidget({
    super.key,
    required this.petId,
    required this.gender,
    required this.petAge,
    required this.breed,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return PetsOverviewDataStream(
      petId: petId,
      uid: uid,
      heartRateBuilder: (context, currentHeartRate) {
        if (currentHeartRate == null) {
          return const Center(child: Text('Loading heart rate...'));
        }

        final requestData = {
          "input_list": [
            currentHeartRate.toString(), // Convert num to String
            gender.toLowerCase().trim(),
            petAge,
            breed.trim(),
          ]
        };

        return AnomalyStatusWidget(
          requestData: requestData,
        );
      },
    );
  }
}

class AnomalyStatusWidget extends StatelessWidget {
  final Map<String, dynamic> requestData;

  const AnomalyStatusWidget({
    required this.requestData,
  });

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Container(
      width: MediaQuery.of(context).size.width * 0.5,
      height: MediaQuery.of(context).size.height * 0.14,
      padding: const EdgeInsets.all(20),
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
      child: FutureBuilder<String>(
        future: MLAnomalyCheck(requestData),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Color(nav),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final status = snapshot.data ?? 'No behavior data found';

            if (status == "Anomaly") {
              notificationService.showNotification(
                'Anomaly Detected',
                'An anomaly was detected in your pet\'s heart rate!',
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.05,
                          fontWeight: FontWeight.w500,
                          color: Color(nav),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Opacity(
                  opacity: 1,
                  child: Image.asset(
                    'assets/images/walking_dog.gif',
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.height * 0.2,
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text('No behavior data found.'));
          }
        },
      ),
    );
  }
}
