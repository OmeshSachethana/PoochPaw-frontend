import 'package:flutter/material.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/screen/function_2/service/pet_overview_data_stream.dart';

class HeartRateWidget extends StatelessWidget {
  final String petId;
  final String uid;

  const HeartRateWidget({super.key, required this.petId, required this.uid});

  @override
  Widget build(BuildContext context) {
    return PetsOverviewDataStream(
      uid: uid,
      petId: petId,
      heartRateBuilder: (context, currentHeartRate) {
        return currentHeartRate != null
            ? _buildHeartRateDisplay(context, currentHeartRate)
            : const CircularProgressIndicator(); // Show loading if null
      },
    );
  }

  Widget _buildHeartRateDisplay(BuildContext context, num heartRate) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.33,
      height: MediaQuery.of(context).size.height * 0.30,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.fitWidth,
              child: Text(
                'Heart Rate',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$heartRate bpm',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(nav),
              ),
            ),
            const SizedBox(height: 25),
            Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/images/heart.gif',
                width: MediaQuery.of(context).size.width * 0.20,
                height: MediaQuery.of(context).size.height * 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
