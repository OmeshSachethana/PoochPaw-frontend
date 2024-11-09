import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'package:poochpaw/screen/common/components/blur_text_field.dart';
import 'package:poochpaw/screen/function_4/components/analysis.dart';

class ViewSearchStrayDogs extends StatefulWidget {
  @override
  _ViewSearchStrayDogsState createState() => _ViewSearchStrayDogsState();
}

class _ViewSearchStrayDogsState extends State<ViewSearchStrayDogs> {
  String? mlIP = dotenv.env['MLIP']?.isEmpty ?? true
      ? dotenv.env['DEFAULT_IP']
      : dotenv.env['MLIP'];
  String? _category;
  // TextEditingController _idController = TextEditingController();
  TextEditingController _genderController = TextEditingController();
  TextEditingController _breedController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;
  XFile? _comparisonImage;
  bool _isComparisonResponseReceived = false;
  List<Map<String, dynamic>> comparisonResults = [];
  List<Map<String, dynamic>> searchResults = [];

  Future<void> _pickComparisonImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _comparisonImage = image;
        _isComparisonResponseReceived = false;
      });

      await _compareWithStrayDogs(image);
    }
  }

  Future<void> _searchDogs() async {
    setState(() {
      _isLoading = true;
    });

    Query query = FirebaseFirestore.instance.collection('strayDogs');

    // if (_idController.text.isNotEmpty) {
    //   query = query.where('id', isEqualTo: _idController.text);
    // }
    if (_breedController.text.isNotEmpty) {
      query = query.where('gender', isEqualTo: _genderController.text);
    }
    // if (_breedController.text.isNotEmpty) {
    //   query = query.where('breed', isEqualTo: _breedController.text);
    // }
    if (_ageController.text.isNotEmpty) {
      query = query.where('age', isEqualTo: _ageController.text);
    }
    if (_locationController.text.isNotEmpty) {
      query = query.where('location', isEqualTo: _locationController.text);
    }
    if (_category != null && _category!.isNotEmpty) {
      query = query.where('category', isEqualTo: _category);
    }

    QuerySnapshot snapshot = await query.get();

    setState(() {
      searchResults = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      _isLoading = false;
    });
  }

  // Predict using the same iamge has in the db
  Future<void> _compareWithStrayDogs(XFile userImage) async {
    setState(() {
      _isLoading = true;
    });

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('strayDogs').get();

    List<Map<String, dynamic>> results = [];
    for (var doc in snapshot.docs) {
      var dogData = doc.data() as Map<String, dynamic>;
      var strayDogImageUrl = dogData['image'];

      // Download the stray dog image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${doc.id}.jpg');
      final response = await http.get(Uri.parse(strayDogImageUrl));
      await tempFile.writeAsBytes(response.bodyBytes);

      // Compare the user uploaded image with the stray dog image
      final uri = Uri.parse('http://$mlIP:8009/compare-images/');
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file1', tempFile.path))
        ..files.add(await http.MultipartFile.fromPath('file2', userImage.path));

      var streamedResponse = await request.send();
      var comparisonResponse = await http.Response.fromStream(streamedResponse);

      if (comparisonResponse.statusCode == 200) {
        var data = jsonDecode(comparisonResponse.body);
        if (data['is_same']) {
          results.add(dogData);
        }
      }
    }

    setState(() {
      comparisonResults = results;
      _isLoading = false;
      _isComparisonResponseReceived = true;
    });

    if (results.isNotEmpty) {
      await _saveStrayDogMatches(results);
    }
  }

  Future<void> _saveStrayDogMatches(
      List<Map<String, dynamic>> matchedDogs) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    CollectionReference matchesCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('strayDogMatches');

    for (var dog in matchedDogs) {
      // Check if the dog already exists in the collection
      bool exists = await _dogExistsInMatches(dog, matchesCollection);
      if (!exists) {
        await matchesCollection.add(dog);
      }
    }
  }

  Future<bool> _dogExistsInMatches(
      Map<String, dynamic> dog, CollectionReference collection) async {
    QuerySnapshot snapshot = await collection
        // .where('id', isEqualTo: dog['id'])
        // .where('breed', isEqualTo: dog['breed'])
        .where('age', isEqualTo: dog['age'])
        .where('gender', isEqualTo: dog['gender'])
        .where('location', isEqualTo: dog['location'])
        .where('category', isEqualTo: dog['category'])
        .get();

    return snapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          title: 'Find Missing Dog',
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
        body: BackgroundWithBlur(
          child: Padding(
            padding: const EdgeInsets.only(
                left: 24.0, right: 24.0, top: 90.0, bottom: 10),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Please provide the details of your missing dog below to search our database.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  // BlurTextField(
                  //     label: 'Dog ID in the collar', controller: _idController),
                  // SizedBox(height: 10),
                  // BlurTextField(
                  //     label: 'Dog Breed', controller: _breedController),
                  SizedBox(height: 10),
                  BlurTextField(label: 'Dog Age', controller: _ageController),
                  SizedBox(height: 10),
                  BlurTextField(
                      label: 'Dog Gender', controller: _genderController),
                  SizedBox(height: 10),
                  BlurTextField(
                      label: 'Location', controller: _locationController),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _searchDogs,
                      child: Text(
                        'Search Missing Dog',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        primary: Colors.white.withOpacity(0.3),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Pet details matching results here:',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  if (_isLoading) CircularProgressIndicator(),
                  if (!_isLoading && searchResults.isNotEmpty)
                    Column(
                      children: searchResults.map((dog) {
                        return Card(
                          elevation: 4.0,
                          margin: EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Padding(
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
                                          //   dog['id'] ?? 'Unknown Id',
                                          //   style: TextStyle(
                                          //     fontSize: 18.0,
                                          //     fontWeight: FontWeight.bold,
                                          //   ),
                                          // ),
                                          SizedBox(height: 8.0),
                                          // Text(
                                          //   '${dog['breed']}',
                                          //   style: TextStyle(
                                          //     fontSize: 18.0,
                                          //     fontWeight: FontWeight.bold,
                                          //   ),
                                          // ),
                                          Text(
                                            'Age: ${dog['age']}',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Age: ${dog['gender']}',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Location: ${dog['location']}',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Category: ${dog['category']}',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.grey[600],
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
                      }).toList(),
                    ),
                  if (!_isLoading && searchResults.isEmpty)
                    Text(
                      'No results found by matching details!',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white.withOpacity(0.3)),
                    ),
                  SizedBox(height: 40),
                  Divider(thickness: 2, color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'Or ',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    'Compare with an Uploaded Image',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Upload an image of your dog to find possible matches in our database.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _pickComparisonImage,
                      child: Text(
                        'Upload Image Of The Dog',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        primary: Colors.white.withOpacity(0.3),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (_comparisonImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: Image.file(
                        File(_comparisonImage!.path),
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  SizedBox(height: 20),
                  Text(
                    'Pet matching results here:',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  if (_isComparisonResponseReceived &&
                      comparisonResults.isNotEmpty)
                    Column(
                      children: comparisonResults.map((dog) {
                        return Card(
                          elevation: 4.0,
                          margin: EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Padding(
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
                                          //   dog['id'] ?? 'Unknown Name',
                                          //   style: TextStyle(
                                          //     fontSize: 18.0,
                                          //     fontWeight: FontWeight.bold,
                                          //   ),
                                          // ),
                                          SizedBox(height: 8.0),
                                          // Text(
                                          //   'Breed: ${dog['breed']}',
                                          //   style: TextStyle(
                                          //     fontSize: 18.0,
                                          //     fontWeight: FontWeight.bold,
                                          //   ),
                                          // ),
                                          Text(
                                            'Age: ${dog['age']}',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Age: ${dog['gender']}',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Location: ${dog['location']}',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Category: ${dog['category']}',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.grey[600],
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
                      }).toList(),
                    ),
                  if (_isComparisonResponseReceived &&
                      comparisonResults.isEmpty)
                    Text('No matching image matches dog found'),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AnalysisScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Stray Dog Analysis',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        primary: Colors.white.withOpacity(0.3),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
