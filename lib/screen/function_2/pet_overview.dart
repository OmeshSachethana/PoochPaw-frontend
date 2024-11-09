import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/models/pet_Id_manager.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'package:poochpaw/screen/function_2/widget/AnomalyWidget.dart';
import 'package:poochpaw/screen/function_2/widget/DailyReportInfoWidget.dart';
import 'package:poochpaw/screen/function_2/widget/HeartRateWidget.dart';
import 'package:poochpaw/screen/function_2/widget/anomaly.dart';
import 'widget/appbar.dart';
import 'widget/BehaviorInfoWidget.dart';

class PetScreen extends StatefulWidget {
  static String routeName = '/home';
  final String? petId;
  final String? pettitle;
  final String? petType;
  final String? petAge;
  final String? petEnergyLvl;
  final String? petGender;
  final String? petHealthC;
  final String? petWeight;
  final String? anomalyAlert;

  const PetScreen({
    Key? key,
    this.petId,
    this.pettitle,
    this.petType,
    this.petAge,
    this.petEnergyLvl,
    this.petGender,
    this.petHealthC,
    this.petWeight,
    this.anomalyAlert,
  }) : super(key: key);

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  late String userId;
  bool isGeneratingData = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    PetIdManager().setPetId(widget.petId);
    PetIdManager().setPetName(widget.pettitle);
    PetIdManager().setPetType(widget.petType);
    PetIdManager().setPetAge(widget.petAge);
    PetIdManager().setPetGender(widget.petGender);
    PetIdManager().setPetHealthC(widget.petHealthC);
    PetIdManager().setPetWeight(widget.petWeight);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Pet Overview',
        leadingImage: 'assets/images/placeholder.png',
        actionImage: null,
        onLeadingPressed: () {
          Navigator.pop(context);
        },
        onActionPressed: () {
          print("Action icon pressed");
        },
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
              bottom: 50.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Container(
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
                      Row(
                        children: [
                          const Icon(Icons.pets, color: Colors.orangeAccent),
                          const SizedBox(width: 10),
                          Text(
                            'Pet Name: ${widget.pettitle}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      infoRow('Pet ID', widget.petId),
                      infoRow('Type', widget.petType),
                      infoRow('Age', widget.petAge),
                      infoRow('Energy Level', widget.petEnergyLvl),
                      infoRow('Gender', widget.petGender),
                      infoRow('Health Condition', widget.petHealthC),
                      infoRow('Weight', '${widget.petWeight} kg'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Column(
                      children: [
                        BehaviorInfoWidget(
                          petId: widget.petId!,
                          uid: userId,
                        ),
                        const SizedBox(height: 20),
                        // AnomalyWidget(
                        //   petId: widget.petId!,
                        //   gender: widget.petGender!,
                        //   petAge: widget.petAge!,
                        //   breed: widget.petType!,
                        //   uid: userId,
                        // ),
                        AnomalyHeartWidget(
                          petId: widget.petId!,
                          gender: widget.petGender!,
                          petAge: widget.petAge!,
                          breed: widget.petType!,
                          uid: userId,
                        )
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: HeartRateWidget(
                        petId: widget.petId!,
                        uid: userId,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                DailyReportInfoWidget(
                  uid: userId,
                  petId: widget.petId!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.label,
            color: Color(nav),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
