import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/services/sign_in_provider.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/auth/authentication_bloc.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'package:poochpaw/screen/function_3/chatScreen.dart';
import 'package:poochpaw/screen/function_3/components/pdf_save.dart';
import 'package:poochpaw/screen/function_3/exercise.dart';
import 'package:poochpaw/screen/function_3/services/ml_service.dart';
import 'package:poochpaw/screen/function_3/services/weight.dart';
import 'chatbot_screen.dart';
import 'components/exercise_recommendations.dart';
import 'components/line_chart.dart';
import 'components/txtwelcome.dart';
import 'services/pet_service.dart';

class BrowseKnowledgeBase extends StatefulWidget {
  @override
  _BrowseKnowledgeBaseState createState() => _BrowseKnowledgeBaseState();
}

class _BrowseKnowledgeBaseState extends State<BrowseKnowledgeBase> {
  bool isExerciseModeOn = false;
  String recommendationTime = '';
  List<String> recommendedExercises = [];
  List<String> petTypes = [];
  String selectedPet = '';
  bool isLoading = true;
  List<double> weightGoals = [];
  double? selectedWeightGoal;
  String petId = '';
  String breed = '';
  int ageMonths = 0;
  double weightLb = 0.0;
  String gender = '';
  String energyLevel = '';
  String healthConcerns = '';
  String underweight = '';
  String overweight = '';
  bool isUnderweight = false;
  bool isOverweight = false;

  @override
  void initState() {
    super.initState();
    fetchPetTypes();
  }

  void fetchPetTypes() async {
    petTypes = await PetService().fetchPetTypes();
    setState(() {
      isLoading = false;
    });
  }

  List<double> getWeightRangeForBreedAndAge(String breed, int ageMonths) {
    breed = breed.trim();
    print('Checking breed: "$breed"');

    if (dogHealthData['breeds'].containsKey(breed)) {
      print('Breed found: $breed');

      String ageCategory = ageMonths <= 24
          ? '0-2'
          : ageMonths <= 84
              ? '3-7'
              : '8+';
      print('Age Category: $ageCategory');

      if (dogHealthData['breeds'][breed]['age'] != null &&
          dogHealthData['breeds'][breed]['age'].containsKey(ageCategory)) {
        print('Age category data found.');

        final weightRange =
            dogHealthData['breeds'][breed]['age'][ageCategory]['weightRange'];
        final normalRange = weightRange['normal'] as String;

        print('Normal Range: $normalRange');

        final parts = normalRange.split('-');
        if (parts.length == 2) {
          final minWeight =
              double.tryParse(parts[0].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          final maxWeight =
              double.tryParse(parts[1].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

          return List<double>.generate(
            (maxWeight - minWeight + 1).toInt(),
            (i) => minWeight + i.toDouble(),
          );
        }
      } else {
        print("Age category $ageCategory not found for breed $breed.");
      }
    } else {
      print('No data found for breed: $breed');
    }
    return [];
  }

  void fetchPetDetails(String petType) async {
    try {
      final details = await PetService().fetchPetDetails(petType);
      setState(() {
        breed = details['pet_type'].trim();
        ageMonths = int.tryParse(details['pet_age']) ?? 0;
        weightLb = double.tryParse(details['pet_Weight']) ?? 0.0;
        gender = details['pet_Gender'];
        energyLevel = details['pet_Energylvl'];
        healthConcerns = details['pet_HealthC'];
        petId = details['pet_id'];

        print("Checking breed: \"$breed\"");
        print("Available breeds: ${dogHealthData['breeds'].keys.toList()}");

        if (dogHealthData['breeds'].containsKey(breed)) {
          print('Breed found: $breed');

          weightGoals = getWeightRangeForBreedAndAge(breed, ageMonths);
          selectedWeightGoal = null;

          final ageCategory = ageMonths <= 24
              ? '0-2'
              : ageMonths <= 84
                  ? '3-7'
                  : '8+';

          final breedData = dogHealthData['breeds'][breed];
          if (breedData != null) {
            print("Breed data found for: $breed");

            final weightRangeData =
                breedData['age'][ageCategory]['weightRange'];
            if (weightRangeData != null) {
              final unhealthyRange = weightRangeData['unhealthy'];
              if (unhealthyRange != null) {
                final underweightLimit = double.tryParse(
                        unhealthyRange['underweight']
                            ?.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                    0.0;
                final overweightLimit = double.tryParse(
                        unhealthyRange['overweight']
                            ?.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                    double.infinity;

                if (weightLb < underweightLimit) {
                  isUnderweight = true;
                  isOverweight = false;
                } else if (weightLb > overweightLimit) {
                  isUnderweight = false;
                  isOverweight = true;
                } else {
                  isUnderweight = false;
                  isOverweight = false;
                }

                print("Pet weight: $weightLb kg");
                print(
                    "Underweight threshold: <$underweightLimit kg, Overweight threshold: >$overweightLimit kg");
                print(
                    "Is Underweight: $isUnderweight, Is Overweight: $isOverweight");

                if (isUnderweight) {
                  print("Pet is underweight.");
                } else if (isOverweight) {
                  print("Pet is overweight.");
                } else {
                  print("Pet weight is within a healthy range.");
                }
              } else {
                print(
                    "Unhealthy weight range data not found for breed: $breed and age category: $ageCategory");
              }
            } else {
              print(
                  "Weight range data not found for age category: $ageCategory for breed: $breed");
            }
          } else {
            print("Breed data not found for: $breed");
          }
        } else {
          print("Breed not found in health data: $breed");
        }
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SignInProvider>();
    final blocUser = context.read<AuthenticationBloc>().state.user;
    String imageUrl =
        sp.imageUrl ?? blocUser?.image_url ?? 'assets/images/placeholder.png';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Knowledge Base',
        leadingImage: imageUrl,
        actionImage: null,
        onLeadingPressed: () => print("Leading icon pressed"),
        onActionPressed: () => print("Action icon pressed"),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          BackgroundWithBlur(
            child: SizedBox.expand(),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 90.0,
              bottom: 120.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TxtWelcome(),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Turn on the exercise mode to monitor pet exercise recommendations!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(
                    'Exercise Mode',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  value: isExerciseModeOn,
                  onChanged: (value) {
                    setState(() {
                      isExerciseModeOn = value;
                    });
                  },
                  activeColor: Color(nav),
                ),
                if (isExerciseModeOn) ...[
                  const SizedBox(height: 24),
                  _buildGlassCard(
                    title: 'Select Your Pet',
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      value: selectedPet.isNotEmpty ? selectedPet : null,
                      dropdownColor: Colors.grey[800],
                      hint: Text('Select Pet',
                          style: TextStyle(color: Colors.white)),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPet = newValue!;
                          recommendedExercises = [];
                          recommendationTime = '';
                          fetchPetDetails(selectedPet);
                        });
                      },
                      items: petTypes
                          .map<DropdownMenuItem<String>>((String petType) {
                        return DropdownMenuItem<String>(
                          value: petType,
                          child: Text(
                            petType,
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (selectedPet.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: PetService().fetchPetDataFromFirestore(petId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (snapshot.hasData && snapshot.data != null) {
                          final petData = snapshot.data!;
                          if (petData.containsKey('recommendedExercises') &&
                              petData['recommendedExercises'].isNotEmpty) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      primary: Colors.white.withOpacity(0.3),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ExerciseScreen(
                                            petId: petId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Go to Exercise Recommendations',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      primary: Colors.white.withOpacity(0.3),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    ),
                                    onPressed: () async {
                                      await PetService()
                                          .deleteRecommendedExercisesFromFirestore(
                                              petId);
                                      setState(() {
                                        selectedPet = '';
                                        recommendedExercises = [];
                                        recommendationTime = '';
                                        selectedWeightGoal = null;
                                      });
                                    },
                                    child: Text(
                                      'Start Over',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.3)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 15,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: _buildHealthStatusCard(),
                                ),
                                const SizedBox(height: 20),
                                _buildGlassCard(
                                  title: 'Set a Weight Goal for Your Pet',
                                  child: DropdownButtonFormField<double>(
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    value: selectedWeightGoal,
                                    dropdownColor: Colors.grey[800],
                                    hint: Text('Select Weight Goal',
                                        style: TextStyle(color: Colors.white)),
                                    onChanged: (double? newValue) {
                                      setState(() {
                                        selectedWeightGoal = newValue!;
                                      });
                                    },
                                    items: weightGoals
                                        .map<DropdownMenuItem<double>>(
                                            (double value) {
                                      return DropdownMenuItem<double>(
                                        value: value,
                                        child: Text(value.toString(),
                                            style:
                                                TextStyle(color: Colors.white)),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildSummaryCard(),
                                const SizedBox(height: 24),
                                _buildPredictExerciseButton(),
                                if (recommendationTime.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  ExerciseRecommendations(
                                    recommendationTime: recommendationTime,
                                    selectedPet: selectedPet,
                                    petId: petId,
                                    recommendedExercises: recommendedExercises,
                                    cardColor: Color(cards),
                                    textColor: Colors.black,
                                  ),
                                ],
                              ],
                            );
                          }
                        } else {
                          return Center(child: Text('No pet data found.'));
                        }
                      },
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                _buildHeartbeatChart(),
                const SizedBox(height: 24),
                _buildDownloadPdfButton(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  Widget _buildHealthStatusCard() {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          if (weightLb < weightGoals.first || weightLb > weightGoals.last) ...[
            if (isUnderweight) ...[
              Text(
                'Your pet is underweight',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
            ] else if (isOverweight) ...[
              Text(
                'Your pet is overweight',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
            ] else ...[
              Text(
                'Your pet is unhealthy',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
            ]
          ] else ...[
            Text(
              'Your pet is healthy',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Padding(
      padding: EdgeInsets.only(bottom: 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(nav),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ChatBotScreen())),
              child: Icon(Icons.chat, color: Colors.white),
              splashColor: Color(nav),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Color(nav),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => VetChatScreen())),
              child: Icon(Icons.pets, color: Colors.white),
              splashColor: Color(nav),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pet Details',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(colorPrimary)),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey),
          const SizedBox(height: 10),
          _buildPetDetailRow('Breed', breed),
          _buildPetDetailRow('Age in Months', ageMonths.toString()),
          _buildPetDetailRow('Weight in lbs', weightLb.toString()),
          _buildPetDetailRow('Gender', gender),
          _buildPetDetailRow('Energy Level', energyLevel),
          _buildPetDetailRow('Health Concerns', healthConcerns),
        ],
      ),
    );
  }

  Widget _buildPetDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
          Text(value,
              style: TextStyle(
                  fontSize: 16, color: Colors.white.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ],
    );
  }

  Widget _buildPredictExerciseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (selectedPet.isNotEmpty && selectedWeightGoal != null) {
            sendPetDetailsToMlModel(
              petId: petId,
              energyLevel: energyLevel,
              healthConcerns: healthConcerns,
              breed: breed,
              gender: gender,
              ageMonths: ageMonths,
              weightLb: weightLb,
              weightGoal: selectedWeightGoal!,
              onResponse: (String recommendationTime,
                  List<String> recommendedExercises) {
                setState(() {
                  this.recommendationTime = recommendationTime;
                  this.recommendedExercises = recommendedExercises;
                });
              },
            );
            PetService().calculateAndSaveExercisingPeriodAccelValues(
                petId: petId, recommendationTime: recommendationTime);
          } else {
            print('Please select a pet and set a weight goal.');
          }
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          primary: Colors.white.withOpacity(0.3),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          'Predict Exercise Time',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeartbeatChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Heartbeat Activity',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        HeartbeatChart(petId: petId),
      ],
    );
  }

  Widget _buildDownloadPdfButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => savePdf(petId, context),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          primary: Colors.white.withOpacity(0.3),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        icon: Icon(Icons.download, color: Colors.white),
        label: Text(
          'Download PDF',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
