import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'dart:async';
import 'package:poochpaw/core/services/sign_in_provider.dart';
import 'package:poochpaw/screen/common/home/home.dart';
import 'package:poochpaw/screen/function_2/pet_overview.dart';
import 'package:poochpaw/core/models/pet_fetch_data.dart';
import 'package:poochpaw/screen/screen.dart';

class AddPet extends StatefulWidget {
  @override
  _AddPetState createState() => _AddPetState();
}

class _AddPetState extends State<AddPet> {
  // Reference to the current user
  final user = FirebaseAuth.instance.currentUser;
  // List of pets
  List<PetData> pets = [];
  // Instance of the SignInProvider
  final signInProvider = SignInProvider();
  // Reference to the FirebaseDatabase
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  // Reference to the root of the database
  final DatabaseReference _dbRef = FirebaseDatabase.instance.reference();
  // Map to store temporary levels
  Map<String, String> tempLevels = {};
  // Map to store battry levels
  Map<String, String> oxyLevels = {};
  // Map to store predicted class H
  Map<String, String> predictedClassH = {};
  // Global pet ID
  String globalPetId = '';
  // Timer to fetch data
  Timer? _dataFetchTimer;
  // Future to fetch pet data
  Future<List<PetData>>? _petDataFuture;
  // StreamSubscription to listen to database changes
  StreamSubscription<DatabaseEvent>? _subscription;
  String selectedGender = '';
  String selectedEnergyLevel = '';

  @override
  void initState() {
    super.initState();

    // Fetch the pet data once
    _petDataFuture = fetchPetDataOnce().then((petsData) {
      // Set the pets data
      pets = petsData;
      // Iterate through the pets and fetch the battry, battry levels and water quality for each pet
      for (var pet in pets) {
        fetchBattryLevelForPet(pet.petid);
        fetchTempLevelsForPet(pet.petid);
        fetchHartRateForPet(pet.petid);
      }
      // Return the pets data
      return petsData;
    });
    // Fetch the pet data once
    _petDataFuture = fetchPetDataOnce();
    // Create a timer to fetch the pet data every 5 seconds
    _dataFetchTimer =
        Timer.periodic(Duration(seconds: 05), (Timer t) => fetchPetData());
  }

  @override
  void dispose() {
    // Cancel the subscription
    _subscription?.cancel();
    // Dispose the super class
    super.dispose();
  }

  Future<List<PetData>> fetchPetDataOnce() async {
    // Get the data from the Realtime Database
    var snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user?.uid)
        .collection("petids")
        .get();

    // Create a list to store the pet data
    List<PetData> petsList = [];
    // Iterate through the data
    for (var doc in snapshot.docs) {
      // Get the pet id
      String petId = doc.id;

      // Add the pet data to the list
      petsList.add(PetData(
        title: doc['pet_name'],
        petid: petId,
        petType: doc['pet_type'],
        petAge: doc['pet_age'],
        petGender: doc['pet_Gender'],
        petEnergylvl: doc['pet_Energylvl'],
        petHealthC: doc['pet_HealthC'],
        petWeight: doc['pet_Weight'],
      ));
    }

    // Return the list of pet data
    return petsList;
  }

  void fetchPetData() {
    // Fetch data for each pet
    for (var pet in pets) {
      fetchBattryLevelForPet(pet.petid);
      fetchTempLevelsForPet(pet.petid);
      fetchHartRateForPet(pet.petid);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return a FutureBuilder to display a loading indicator while the data is being fetched
    return FutureBuilder<List<PetData>>(
      future: _petDataFuture,
      builder: (context, snapshot) {
        // If the connection state is waiting, show a loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        // If there is an error, display it
        if (snapshot.hasError) {
          // If there is an error, display it
          return Text('Error: ${snapshot.error}');
        }

        // Update the pet data list if data is found
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          pets = snapshot.data!;
        }

        // Return the widget tree
        return Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the add pet button regardless of whether pets are found
              buildAddPetButton(),

              // If there is data, show the pet list, else show 'No pets found'
              if (snapshot.hasData && snapshot.data!.isNotEmpty)
                ...buildPetList(snapshot.data!),
              if (snapshot.data == null || snapshot.data!.isEmpty)
                const Text('No pets found.'),
            ],
          ),
        );
      },
    );
  }

  List<Widget> buildPetList(List<PetData> petDataList) {
    // Return a list of widgets to display the pet list
    return [
      const SizedBox(height: 20),
      Text(
        'Pets Overview',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.7),
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 10),
      // Create a column to display the pet list
      Column(
        children: petDataList.map((pet) {
          // Return a card for each pet in the list
          return Column(
            children: [
              buildPetCard(pet),
              const SizedBox(height: 15),
            ],
          );
        }).toList(),
      ),
      const SizedBox(height: 10),
    ];
  }

  Widget buildAddPetButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Add Your Pets Here',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        IconButton(
          icon: Image.asset(
            'assets/icons/+.png',
            width: 27,
            height: 27,
          ),
          onPressed: () {
            _showAddPetDialog(context);
          },
        ),
      ],
    );
  }

  Widget buildPetCard(PetData pet) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetScreen(
                petId: pet.petid,
                pettitle: pet.title,
                petType: pet.petType,
                petAge: pet.petAge,
                petEnergyLvl: pet.petEnergylvl,
                petGender: pet.petGender,
                petHealthC: pet.petHealthC,
                petWeight: pet.petWeight), // Pass the petId
          ),
        );
      },
      onLongPress: () {
        // Show the delete confirmation dialog when long-pressed
        _showDeleteConfirmationDialog(context, pet);
      },
      child: Container(
        height: 85,
        width: 390,
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
          children: [
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
                  Text(
                    pet.title.length > 6
                        ? '${pet.title.substring(0, 6)}...'
                        : pet.title,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Change text color to white
                    ),
                  ),
                  Text(
                    pet.petAge.length > 6
                        ? '${pet.petAge.substring(0, 6)}...'
                        : pet.petAge,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      color: Colors.white, // Change text color to white
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/Scuba Tank.png',
                        height: 20,
                        width: 20,
                        color: Colors.white, // Change icon color to white
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${tempLevels[pet.petid] ?? "N/A"}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Change text color to white
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Battery Level',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: Colors.white, // Change text color to white
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/Temperature High.png',
                        height: 20,
                        width: 20,
                        color: Colors.white, // Change icon color to white
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${oxyLevels[pet.petid] ?? "N/A"}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Change text color to white
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Temperature',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: Colors.white, // Change text color to white
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 60,
              child: Stack(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/icons/coller.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get the latest battry level for the pet
  void fetchBattryLevelForPet(String petId) {
    // Get the battery level reference
    DatabaseReference petBatteryRef =
        _database.reference().child('$petId/Battery');

    print('Battery level reference: $petBatteryRef');

    // Listen for changes to the battery level
    petBatteryRef.onValue.listen((DatabaseEvent event) {
      // Get the latest battery level
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        print('Battery level data: ${snapshot.value}');
        // Parse the value to a double
        double value =
            double.tryParse(snapshot.value.toString().replaceAll('%', '')) ?? 0;
        // Convert the value to a percentage
        String percentage =
            '${(value).round()}%'; // Value already assumed to be a percentage
        // Update the state with the new percentage
        setState(() {
          tempLevels[petId] = percentage;
        });
      } else {
        print('No battery level data found.');
      }
    }).onError((error) {
      print('Error listening to battery level: $error');
    });
  }

  // Fetch the latest battry levels for the pet
  void fetchTempLevelsForPet(String petId) {
    // Get the reference to the battry level
    DatabaseReference petOxyRef = _database.reference().child('$petId/Temp');

    // Listen for changes to the battry level
    petOxyRef.onValue.listen((DatabaseEvent event) {
      // Get the latest battry level
      // Get the latest battry level
      petOxyRef.onValue.listen((DatabaseEvent event) {
        DataSnapshot snapshot = event.snapshot;
        if (snapshot.value != null) {
          // Convert the value to double
          double value = double.tryParse(snapshot.value.toString()) ?? 0;
          // Calculate the percentage
          // Update the state
          setState(() {
            oxyLevels[petId] = value.toStringAsFixed(2);
          });
        }
      });
    });
  }

  void fetchHartRateForPet(String petId) {
    // Get the latest battry level
    DatabaseReference petWaterRef =
        _database.reference().child('$petId/Funtion_1 Task 01/Predicted Class');

    petWaterRef.onValue.listen((DatabaseEvent event) {
      // Get the latest battry level
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        String predictedClass = snapshot.value.toString(); // Handle as a string
        // Do something with the predictedClass
        setState(() {
          // Assuming oxyLevels is a Map<String, String>
          predictedClassH[petId] = predictedClass;
        });
      }
    });
  }

  void checkPetIdsInDatabase() {
    // Get the reference to the pets collection
    final DatabaseReference petIdsRef = _database.reference();

    // Get the latest pet IDs
    petIdsRef.once().then((event) {
      if (event.snapshot.value == null) {
        // No pets in database
      } else {
        // Get the latest pet IDs
        Map<dynamic, dynamic>? petIdsMap =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (petIdsMap != null) {
          List<String> databasePetIds = petIdsMap.keys.cast<String>().toList();

          // Check if any of the pet IDs match the current pets
          for (String petId in databasePetIds) {
            if (pets.any((pet) => pet.petid == petId)) {
              // Pet ID matches, fetch and update battry level
              fetchBattryLevelForPet(petId);
              fetchTempLevelsForPet(petId);
              fetchHartRateForPet(petId);
            }
          }
        } else {}
      }
    }).catchError((error) {});
  }

// This method shows a confirmation dialog to the user when they want to delete a pet
  void _showDeleteConfirmationDialog(BuildContext context, PetData pet) async {
    // Show the dialog with a context and builder
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        // Create an AlertDialog with a title and content
        return AlertDialog(
          title: const Text('Delete Pet'),
          content: const Text('Are you sure you want to delete this pet?'),
          actions: [
            // Create a TextButton for the cancel option
            TextButton(
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            // Create a TextButton for the delete option
            TextButton(
              onPressed: () {
                // Remove the pet from the list
                setState(() {
                  pets.remove(pet);
                });

                // Remove the pet from Firestore
                removePetFromFirestore(pet.petid);

                // Close the dialog
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void removePetFromFirestore(String petId) {
    // Get the user's uid from the Firebase user
    FirebaseFirestore.instance
        .collection("users")
        .doc(user?.uid)
        // Get the pet's id from the Firebase document
        .collection("petids")
        .doc(petId)
        // Delete the document from the Firebase collection
        .delete()
        .then((_) {})
        // Catch any errors that occur
        .catchError((error) {});
  }

  void _showAddPetDialog(BuildContext context) async {
    GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    String newPetTitle = '';
    String newPetId = '';
    String newPetType = '';
    String newPetAge = '';
    String newPetGender = '';
    String newEnergylvl = '';
    String newPetHealthC = '';
    String newPetWeight = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Pet'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Please use Pet Id as your IOT device connected database referance id.\n\nDefault: \n1698404487\n3398404487\n9998404487'),
                  TextFormField(
                    onChanged: (value) => newPetTitle = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a pet name';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(labelText: 'Pet Name'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) {
                      newPetId = value;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Enter Pet Id',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) {
                      newPetType = value;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Enter Pet Type',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) {
                      newPetAge = value;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Enter Pet Age(Months)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: newPetGender.isNotEmpty ? newPetGender : null,
                    decoration: const InputDecoration(
                      labelText: 'Select Pet Gender',
                    ),
                    items: ['Male', 'Female']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        newPetGender = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: newEnergylvl.isNotEmpty ? newEnergylvl : null,
                    decoration: const InputDecoration(
                      labelText: 'Select Pet Energy Level',
                    ),
                    items: ['High', 'Medium', 'Low']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        newEnergylvl = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) {
                      newPetHealthC = value;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Enter Pet Health Concerns',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) {
                      newPetWeight = value;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Enter Pet Weight',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Ensure this method is async
                if (_formKey.currentState!.validate()) {
                  PetData newPet = PetData(
                    title: newPetTitle,
                    petid: newPetId,
                    petType: newPetType,
                    petAge: newPetAge,
                    petGender: newPetGender,
                    petEnergylvl: newEnergylvl,
                    petHealthC: newPetHealthC,
                    petWeight: newPetWeight,
                  );

                  signInProvider.addNewPet(
                      newPetTitle,
                      newPetId,
                      newPetType,
                      newPetAge,
                      newPetGender,
                      newEnergylvl,
                      newPetHealthC,
                      newPetWeight);

                  // Fetch and set battry level
                  fetchBattryLevelForPet(newPetId);
                  fetchTempLevelsForPet(newPetId);
                  fetchHartRateForPet(newPetId);

                  // Update the list of pets and rebuild the widget
                  setState(() {
                    pets.add(newPet);
                  });
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (BuildContext context) => Nav(),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
