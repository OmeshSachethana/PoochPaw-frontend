import 'package:flutter/material.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

class VolunteerEmergencyNotifications extends StatefulWidget {
  @override
  _VolunteerEmergencyNotificationsState createState() =>
      _VolunteerEmergencyNotificationsState();
}

class _VolunteerEmergencyNotificationsState
    extends State<VolunteerEmergencyNotifications> {
  List<Map<String, dynamic>> matchedDogs = [];
  bool _isLoading = true;
  bool _receivePushNotifications = false;

  @override
  void initState() {
    super.initState();
    _fetchMatchedDogs();
  }

  Future<void> _fetchMatchedDogs() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('strayDogMatches')
        .get();

    setState(() {
      matchedDogs = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _togglePushNotifications(bool value) async {
    if (value) {
      // Request notification permissions
      var status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() {
          _receivePushNotifications = value;
        });

        // Save the updated notification setting to Firestore
        String uid = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'receivePushNotifications': _receivePushNotifications});
      } else {
        // Permission denied
        print("Notification permission denied");
      }
    } else {
      setState(() {
        _receivePushNotifications = value;
      });

      // Save the updated notification setting to Firestore
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'receivePushNotifications': _receivePushNotifications});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Emergency Notifications',
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                BackgroundWithBlur(
                  child: SizedBox
                      .expand(), // Makes the blur cover the entire screen
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      left: 24.0, right: 24.0, top: 90.0, bottom: 50.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 10),
                      Text(
                        'This screen shows notifications and updates about stray dogs that you might have matched with. ',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Receive Push Notifications',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              Switch(
                                value: _receivePushNotifications,
                                onChanged: _togglePushNotifications,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ...matchedDogs.map((dog) {
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
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 20),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
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
                                        //     color:
                                        //         Colors.white.withOpacity(0.7),
                                        //   ),
                                        // ),
                                        Text(
                                          'Age: ${dog['age']}',
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                        Text(
                                          'Gender: ${dog['gender']}',
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                        Text(
                                          'Location: ${dog['location']}',
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                        Text(
                                          'Category: ${dog['category']}',
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
