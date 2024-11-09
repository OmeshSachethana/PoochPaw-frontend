import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';

class MissingDogReports extends StatefulWidget {
  @override
  _MissingDogReportsState createState() => _MissingDogReportsState();
}

class _MissingDogReportsState extends State<MissingDogReports> {
  bool _receiveMissingDogNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      setState(() {
        _receiveMissingDogNotifications =
            userDoc['receiveMissingDogNotifications'] ?? false;
      });
    }
  }

  Future<void> _toggleMissingDogNotifications(bool value) async {
    setState(() {
      _receiveMissingDogNotifications = value;
    });

    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update(
        {'receiveMissingDogNotifications': _receiveMissingDogNotifications});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Missing Dog Reports',
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
      body: Stack(
        children: [
          // Ensure the background blur takes the full screen
          BackgroundWithBlur(
            child: SizedBox.expand(), // Makes the blur cover the entire screen
          ),
          // The content of the screen
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 90.0,
                    bottom: 50.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'This screen provides updates on reports of missing dogs in your area.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Receive Missing Dog Notifications',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          Switch(
                            value: _receiveMissingDogNotifications,
                            onChanged: _toggleMissingDogNotifications,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('strayDogs')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(child: Text('No stray dogs found.'));
                          }

                          var strayDogs = snapshot.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero, // Ensure no padding
                            itemCount: strayDogs.length,
                            itemBuilder: (context, index) {
                              var dog = strayDogs[index].data()
                                  as Map<String, dynamic>;
                              return Container(
                                margin: EdgeInsets.symmetric(
                                    vertical: 10), // Adjusted margin
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
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Image.network(
                                              dog['image'] ??
                                                  'https://example.com/placeholder.png',
                                              height: 100,
                                              width: 150,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          SizedBox(width: 16.0),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Text(
                                                //   '${dog['breed']}',
                                                //   style: TextStyle(
                                                //     fontSize: 18.0,
                                                //     fontWeight: FontWeight.bold,
                                                //     color: Colors.white
                                                //         .withOpacity(0.7),
                                                //   ),
                                                // ),
                                                Text(
                                                  'Age: ${dog['age']}',
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                                Text(
                                                  'Gender: ${dog['gender']}',
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                                Text(
                                                  'Location: ${dog['location']}',
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                                Text(
                                                  'Category: ${dog['category']}',
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
