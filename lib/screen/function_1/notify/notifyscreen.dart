import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/services/sign_in_provider.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/auth/authentication_bloc.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'doctor_details_widget.dart';

class NotifyScreen extends StatefulWidget {
  @override
  State<NotifyScreen> createState() => _NotifyScreenState();
}

class _NotifyScreenState extends State<NotifyScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> _getConsultations() {
    final sp = context.read<SignInProvider>();
    final blocUser = context.read<AuthenticationBloc>().state.user;
    final doctorId = sp.doctorId ?? blocUser?.doctorId ?? '';

    return _firestore
        .collection('vet_consultations')
        .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('reviewed', isEqualTo: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SignInProvider>();
    final blocUser = context.read<AuthenticationBloc>().state.user;
    String imageUrl =
        sp.imageUrl ?? blocUser?.image_url ?? 'assets/images/placeholder.png';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Vet Consultation',
        leadingImage: 'assets/icons/Back.png',
        actionImage: null,
        onLeadingPressed: () {
          Navigator.of(context).pop();
        },
        onActionPressed: () {
          print("Action icon pressed");
        },
      ),
      extendBodyBehindAppBar: true,
      body: StreamBuilder<QuerySnapshot>(
        stream: _getConsultations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Color(nav),
            ));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No consultations found.'));
          }

          final consultations = snapshot.data!.docs;

          return Stack(
            children: [
              BackgroundWithBlur(
                child:
                    SizedBox.expand(), // Makes the blur cover the entire screen
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 90.0,
                  bottom: 50.0,
                ),
                child: Column(
                  children: [
                    ConsultationsList(consultations: consultations),
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
