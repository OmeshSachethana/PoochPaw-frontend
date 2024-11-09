import 'package:flutter/material.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/screen/function_2/service/ml_service.dart';
import 'package:poochpaw/screen/function_2/service/pet_overview_data_stream.dart';

// Updated Label Mapping
const Map<int, String> labelMapping = {
  0: 'Eating',
  1: 'Lying',
  2: 'Jumping',
  3: 'Galloping',
  4: 'Panting',
  5: 'Shaking',
  6: 'Sitting',
  7: 'Sleeping',
  8: 'Sniffing',
  9: 'Standing',
  10: 'Walking',
};

class BehaviorInfoWidget extends StatelessWidget {
  final String petId;
  final String uid;

  BehaviorInfoWidget({super.key, required this.petId, required this.uid});

  @override
  Widget build(BuildContext context) {
    return PetsOverviewDataStream(
      petId: petId,
      uid: uid,
      behaviorBuilder:
          (context, ANeck_x, ANeck_y, ANeck_z, GNeck_x, GNeck_y, GNeck_z) {
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

        return FutureBuilder<int>(
          future: sendDataToML(behaviorDataList),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                color: Color(nav),
              ));
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              final behaviorIndex = snapshot.data;
              final behaviorText = labelMapping[behaviorIndex] ?? 'Unknown';

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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Text(
                            'Behavior',
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.05,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Text(
                            behaviorText,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.05,
                              fontWeight: FontWeight.w500,
                              color: Color(nav),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Opacity(
                      opacity: 0.5,
                      child: Image.asset(
                        'assets/images/dog_gif.gif',
                        width: MediaQuery.of(context).size.width * 0.15,
                        height: MediaQuery.of(context).size.height * 0.2,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return const Text('No behavior data found.');
            }
          },
        );
      },
    );
  }
}
