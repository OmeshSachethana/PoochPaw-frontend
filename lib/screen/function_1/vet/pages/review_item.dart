import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReviewItem extends StatelessWidget {
  final DocumentSnapshot consultation;

  const ReviewItem({required this.consultation, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(consultation['user_image']),
          radius: 30,
        ),
        title: Text(
          consultation['user_name'],
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disease: ${consultation['disease_result']}',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
      ),
    );
  }
}
