import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/services/sign_in_provider.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/auth/authentication_bloc.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'consultation_details_modal.dart';
import 'review_item.dart';

class ReviewedConsultationsScreen extends StatefulWidget {
  const ReviewedConsultationsScreen({super.key});

  @override
  State<ReviewedConsultationsScreen> createState() =>
      _ReviewedConsultationsScreenState();
}

class _ReviewedConsultationsScreenState
    extends State<ReviewedConsultationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> _getConsultations() {
    final sp = context.read<SignInProvider>();
    final blocUser = context.read<AuthenticationBloc>().state.user;
    final doctorId = sp.doctorId ?? blocUser?.doctorId ?? '';

    return _firestore
        .collection('vet_consultations')
        .where('doctorId', isEqualTo: doctorId)
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
        title: 'Reviewed Consultations',
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
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: consultations.length,
                      itemBuilder: (context, index) {
                        final consultation = consultations[index];
                        return GestureDetector(
                          onTap: () async {
                            final pendingReviews =
                                await _getPendingReviews(consultation.id);
                            if (pendingReviews.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'No pending reviews for this consultation.')),
                              );
                              return;
                            }

                            final reviewId = pendingReviews
                                .first.id; // Get the first pending review ID

                            // ignore: use_build_context_synchronously
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (BuildContext context) {
                                return ConsultationDetailsModal(
                                  consultation: consultation,
                                  firestore: _firestore,
                                );
                              },
                            );
                          },
                          child: Column(
                            children: [
                              ReviewItem(consultation: consultation),
                            ],
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

// Get the pending reviews for a consultation
  Future<List<DocumentSnapshot>> _getPendingReviews(
      String consultationId) async {
    final reviewsQuery = _firestore
        .collection('vet_consultations')
        .doc(consultationId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();

    final snapshot = await reviewsQuery.first;
    if (snapshot.docs.isEmpty) {
      final consultationSnapshot = await _firestore
          .collection('vet_consultations')
          .doc(consultationId)
          .get();
      return [consultationSnapshot];
    }

    return snapshot.docs;
  }
}
