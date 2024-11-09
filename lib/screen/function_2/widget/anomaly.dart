import 'package:flutter/material.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/screen/function_2/service/ml_service.dart';
import 'package:poochpaw/screen/function_2/service/notification.dart';
import 'package:poochpaw/screen/function_2/service/pet_overview_data_stream.dart';

class AnomalyHeartWidget extends StatelessWidget {
  final String petId;
  final String gender;
  final String petAge;
  final String breed;
  final String uid;

  const AnomalyHeartWidget({
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
      heartRateBuilder: (context, currentHeartRate) =>
          _buildWithBehavior(context, currentHeartRate),
    );
  }

  Widget _buildWithBehavior(BuildContext context, num? heartRate) {
    return PetsOverviewDataStream(
      petId: petId,
      uid: uid,
      behaviorBuilder:
          (context, ANeck_x, ANeck_y, ANeck_z, GNeck_x, GNeck_y, GNeck_z) {
        if (heartRate == null) {
          return const Center(child: Text('Loading heart rate...'));
        }

        // Prepare behavior data
        final behaviorDataList = [
          {
            "ANeck_x": ANeck_x,
            "ANeck_y": ANeck_y,
            "ANeck_z": ANeck_z,
            "GNeck_x": GNeck_x,
            "GNeck_y": GNeck_y,
            "GNeck_z": GNeck_z,
          }
        ];

        // Use FutureBuilder to await ML response
        return FutureBuilder<int>(
          future: sendDataToML(behaviorDataList),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              debugPrint('Error occurred: ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final behaviorIndex = snapshot.data ?? 'Unknown';
              debugPrint('Behavior Index: $behaviorIndex');

              // Prepare request data to match the API requirements
              final requestData = {
                "Behavior": behaviorIndex, // Add behavior index here
                "Heartbeat": heartRate, // Add heart rate here
              };
              debugPrint('Request Data: $requestData');

              return AnomalyHeartStatusWidget(
                requestData: requestData,
              );
            } else {
              debugPrint('No behavior data found.');
              return const Center(child: Text('No behavior data found.'));
            }
          },
        );
      },
    );
  }
}

class AnomalyHeartStatusWidget extends StatelessWidget {
  final Map<String, dynamic> requestData;

  const AnomalyHeartStatusWidget({
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
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: FutureBuilder<String>(
        future: MLAnomalyHeart(requestData), // Pass the requestData directly
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
