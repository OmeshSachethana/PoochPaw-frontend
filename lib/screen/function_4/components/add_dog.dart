import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:poochpaw/core/utils/snack_bar.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';

class AddDog extends StatefulWidget {
  @override
  _AddDogState createState() => _AddDogState();
}

class _AddDogState extends State<AddDog> {
  XFile? _image;
  String? mlIP = dotenv.env['MLIP']?.isEmpty ?? true
      ? dotenv.env['DEFAULT_IP']
      : dotenv.env['MLIP'];
  String? _predictedClass;
  String? _category;
  bool _isResponseReceived = false;
  TextEditingController _idController = TextEditingController();
  TextEditingController _breedController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _genderController = TextEditingController();

  List<Map<String, dynamic>> comparisonResults = [];
  String? _uploadedImageUrl;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  XFile? _comparisonImage;
  bool _isComparisonResponseReceived = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = image;
        _isLoading = true;
        _comparisonImage = image;
        _isComparisonResponseReceived = false;
      });

      _uploadedImageUrl = await _uploadImageToFirebase(image);
      await _uploadAndPredictSecondModel(image);
      await _uploadImageToMlAndStrayDogEndpoints(image);

      setState(() {
        _isLoading = false;
        _isResponseReceived = true;
      });
    }
  }

  Future<void> _uploadAndPredictSecondModel(XFile image) async {
    final uri = Uri.parse('http://$mlIP:8010/predict/');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        if (_predictedClass != 'other') {
          _category = data['category'];
        } else {
          _category = null;
        }
        print('Category: $_category');
      });
    } else {
      print('Failed to load prediction from second model');
    }
  }

  Future<void> _compareWithStrayDogs(XFile userImage) async {
    setState(() {
      _isLoading = true;
    });

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('availableDogs').get();

    List<Map<String, dynamic>> results = [];
    for (var doc in snapshot.docs) {
      var dogData = doc.data() as Map<String, dynamic>;
      var strayDogImageUrl = dogData['image'];

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${doc.id}.jpg');
      final response = await http.get(Uri.parse(strayDogImageUrl));
      await tempFile.writeAsBytes(response.bodyBytes);

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
  }

  Future<String> _uploadImageToFirebase(XFile image) async {
    String fileName = path.basename(image.path);
    Reference ref = FirebaseStorage.instance.ref().child('strayDogs/$fileName');
    UploadTask uploadTask = ref.putFile(File(image.path));
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _uploadImageToMlAndStrayDogEndpoints(XFile image) async {
    final uri = Uri.parse('http://$mlIP:8008/predict/');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print(response.body);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        _predictedClass = data['predicted_class'];
      });

      final addDogUri = Uri.parse('http://$mlIP:8010/predict/');
      var addDogRequest = http.MultipartRequest('POST', addDogUri)
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      var addDogStreamedResponse = await addDogRequest.send();
      var addDogResponse =
          await http.Response.fromStream(addDogStreamedResponse);

      if (addDogResponse.statusCode != 200) {
        print('Failed to add stray dog image');
      }
    } else {
      print('Failed to load prediction');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Add Dog Information',
        leadingImage: 'assets/icons/Back.png',
        onLeadingPressed: () {
          Navigator.of(context).pop();
        },
      ),
      extendBodyBehindAppBar: true,
      body: BackgroundWithBlur(
        child: Padding(
          padding: const EdgeInsets.only(
              left: 24.0, right: 24.0, top: 90.0, bottom: 50.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 10),
                      Text(
                        'Please provide the details of the dog you want to add. This is not for stray dogs.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField('Dog Id in the collar', _idController),
                      const SizedBox(height: 15),
                      _buildTextField('Dog Breed', _breedController),
                      const SizedBox(height: 15),
                      _buildTextField('Dog Age', _ageController),
                      const SizedBox(height: 15),
                      _buildTextField('Gender', _genderController),
                      const SizedBox(height: 15),
                      _buildTextField('Location', _locationController),
                      const SizedBox(height: 20),
                      _image != null
                          ? _buildImagePreview(_image!)
                          : const Text(
                              'No image selected.',
                              style: TextStyle(color: Colors.grey),
                            ),
                      const SizedBox(height: 20),
                      if (_isResponseReceived) _buildPredictionCard(),
                      const SizedBox(height: 20),
                      _buildUploadButton(),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: _buildAddDogButton(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for Add Stray Dog button
  Widget _buildAddDogButton() {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : () async {
              if (_idController.text.isEmpty ||
                  _genderController.text.isEmpty ||
                  _breedController.text.isEmpty ||
                  _ageController.text.isEmpty ||
                  _locationController.text.isEmpty ||
                  _image == null) {
                openSnackbar(
                  context,
                  'Please fill all fields and select an image',
                  Colors.red,
                );
                return;
              }

              setState(() {
                _isLoading = true;
              });

              _uploadedImageUrl = await _uploadImageToFirebase(_image!);

              if (_uploadedImageUrl != null) {
                await _compareWithStrayDogs(_image!);

                if (comparisonResults.isNotEmpty &&
                    _predictedClass != 'other') {
                  openSnackbar(
                      context, 'This stray dog already exists!', Colors.red);
                } else if (_predictedClass == 'other') {
                  openSnackbar(
                      context,
                      'This image does not contain a dog. Please try again with a valid image.',
                      Colors.red);
                } else {
                  await _firestore.collection('availableDogs').add({
                    'id': _idController.text,
                    'gender': _genderController.text,
                    'breed': _breedController.text,
                    'age': _ageController.text,
                    'location': _locationController.text,
                    'image': _uploadedImageUrl,
                    'predictedClass': _predictedClass,
                    'category': _category,
                  });

                  openSnackbar(
                      context, 'Stray Dog added successfully!', Colors.green);
                }
              } else {
                openSnackbar(context, 'Failed to upload image', Colors.red);
              }

              setState(() {
                _isLoading = false;
              });
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
      child: _isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              'Add Dog',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

// Helper method to build text fields
  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

// Helper method to display the image preview
  Widget _buildImagePreview(XFile image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: Image.file(
        File(image.path),
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

// Helper method to build prediction card
  Widget _buildPredictionCard() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconRow(Icons.pets, 'Prediction: $_predictedClass'),
          const SizedBox(height: 10),
          if (_category != null)
            _buildIconRow(Icons.category, 'Category: $_category'),
        ],
      ),
    );
  }

// Helper method to build icon and text row
  Widget _buildIconRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange.withOpacity(0.8)),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

// Helper method for upload button
  Widget _buildUploadButton() {
    return ElevatedButton(
      onPressed: _pickImage,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        primary: Colors.white.withOpacity(0.3),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(
            'Upload Image Of The Dog',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
