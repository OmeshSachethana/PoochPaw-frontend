import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/screen/common/auth/authentication_bloc.dart';
import 'package:poochpaw/screen/common/auth/login/login_screen.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/internet_provider.dart';
import '../../../../core/services/sign_in_provider.dart';
import '../../../../core/utils/snack_bar.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Body extends StatefulWidget {
  final User? user;

  const Body({super.key, this.user});

  @override
  State<Body> createState() => _Bodystate();
}

// Enum representing different types of profile cards
enum ProfileCardType { name, age, gender, email, address, google, signout }

// Extension method to handle tap events for different profile card types
extension ProfileCardTypeExtension on ProfileCardType {
  void handleTap(BuildContext context, SignInProvider sp,
      {required Function(BuildContext) showEditNameDialog,
      showEditEmailDialog,
      showEditAgeDialog,
      showEditGenderDialog,
      showEditAddressDialog}) {
    switch (this) {
      case ProfileCardType.name:
        showEditNameDialog(context); // Show edit name dialog
        break;
      case ProfileCardType.email:
        showEditEmailDialog(context); // Show edit email dialog
        break;
      case ProfileCardType.age:
        showEditAgeDialog(context); // Show edit age dialog
        break;
      case ProfileCardType.gender:
        showEditGenderDialog(context); // Show edit gender dialog
        break;
      case ProfileCardType.address:
        showEditAddressDialog(context); // Show edit address dialog
        break;
      case ProfileCardType.signout:
        sp.userSignOut(); // Sign out user
        Navigator.pushReplacementNamed(
            context, LoginScreen.routeName); // Navigate to login screen
        break;
      case ProfileCardType.google:
        // Maybe you want to handle Google connect/disconnect here
        break;
      default:
        // Handle default or undefined action
        break;
    }
  }
}

class _Bodystate extends State<Body> {
  final RoundedLoadingButtonController googleController =
      RoundedLoadingButtonController();

  Future<void> getData() async {
    final sp = context.read<SignInProvider>();
    await sp.getDataFromSharedPreferences();
  }

  DateTime? selectedTime;

  @override
  void initState() {
    super.initState();
    getData();
  }

  // Function to fetch the latest data from Firestore and update the state
  Future<void> _refreshData() async {
    final sp = context.read<SignInProvider>();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Fetch the latest user data from Firestore
      await sp.getUserDataFromFirestore(user.uid);
    }

    // Set the state to trigger a rebuild with the latest data
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SignInProvider>();
    final blocUser = context.read<AuthenticationBloc>().state.user;

    // Determine which image URL to use
    String imageUrl = sp.imageUrl ?? blocUser?.image_url ?? '';
    String NameUser = sp.name ?? blocUser?.name ?? '';

    return Scaffold(
      body: Stack(
        children: [
          BackgroundWithBlur(
            child: SizedBox.expand(), // Makes the blur cover the entire screen
          ),
          RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                  left: 24.0, right: 24.0, top: 90.0, bottom: 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // const SizedBox(height: 20),
                  buildProfilePicture(imageUrl),

                  const SizedBox(height: 10),
                  buildUserName(NameUser),
                  const SizedBox(height: 20),
                  buildSectionTitle('User Info'),
                  buildProfileCard(context, FontAwesomeIcons.fileSignature,
                      ProfileCardType.name),
                  buildProfileCard(context, Icons.email, ProfileCardType.email),
                  buildProfileCard(
                      context, FontAwesomeIcons.person, ProfileCardType.age),
                  buildProfileCard(context, Icons.contact_page_rounded,
                      ProfileCardType.gender),
                  buildProfileCard(
                      context, Icons.location_city, ProfileCardType.address),
                  buildProfileCard(context, FontAwesomeIcons.rightToBracket,
                      ProfileCardType.signout),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfilePicture(String? imageUrl) {
    return GestureDetector(
      onTap: () async {
        await _updateProfilePictureFromGallery();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 155,
            height: 155,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(colorPrimary),
            ),
          ),
          (imageUrl != null && imageUrl.isNotEmpty && imageUrl != "null")
              ? CircleAvatar(
                  radius: 70,
                  backgroundImage: NetworkImage(imageUrl),
                )
              : const Icon(
                  Icons.account_circle,
                  size: 140,
                  color: Colors.white,
                ),
        ],
      ),
    );
  }

  Future<void> _updateProfilePictureFromGallery() async {
    final sp = context.read<SignInProvider>();
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final blocUser = context.read<AuthenticationBloc>().state.user;
    String userIDBoth = firebaseUser?.uid ?? blocUser?.userID ?? '';
    // ignore: deprecated_member_use
    final pickedImage =
        await ImagePicker().getImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('profilePicture')
          .child('${userIDBoth}.jpg');
      UploadTask uploadTask = ref.putFile(File(pickedImage.path));

      await uploadTask.then((res) async {
        String downloadURL = await res.ref.getDownloadURL();
        await sp.updateProfilePicture(downloadURL, userIDBoth);
      });
    }
  }

  Widget buildUserName(String? displayName) {
    return Align(
      alignment: Alignment.center,
      child: Text(
        displayName ?? "",
        style: const TextStyle(
            fontSize: 26,
            // color: AppColors.colorcolorPrimary,
            fontWeight: FontWeight.w600,
            color: Colors.white),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            // color: AppColors.colorcolorPrimary,
          ),
        ),
      ),
    );
  }

  // Function to show a dialog for editing the name
  void _showEditNameDialog(BuildContext context) {
    final sp = context.read<SignInProvider>();
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final blocUser = context.read<AuthenticationBloc>().state.user;
    String userIDBoth = firebaseUser?.uid ?? blocUser?.userID ?? '';
    // TextEditingController to get the user's input
    TextEditingController _nameController =
        TextEditingController(text: sp.name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  // Update the name in Firestore
                  await sp.updateName(_nameController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Function to show a dialog for editing Email
  void _showEditEmailDialog(BuildContext context) {
    final sp = context.read<SignInProvider>();
    TextEditingController _emailController =
        TextEditingController(text: sp.email);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Email'),
          content: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await sp.updateEmail(_emailController.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditAddressDialog(BuildContext context) {
    final sp = context.read<SignInProvider>();
    TextEditingController _addressController =
        TextEditingController(text: sp.address);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final blocUser = context.read<AuthenticationBloc>().state.user;
    String userIDBoth = firebaseUser?.uid ?? blocUser?.userID ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Address'),
          content: TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Address'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String newAddress = _addressController.text;
                await sp.updateAddress(newAddress, userIDBoth);

                // Save the age to SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                int? addressInt = int.tryParse(newAddress);
                if (addressInt != null) {
                  prefs.setInt('address', addressInt);
                } else {
                  // Handle the case where the address is not a valid integer.
                  // For example, show an error message to the user.
                }

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _generateSubtitleForNull(dynamic fieldValue, String message) {
    if (fieldValue == null) {
      return message;
    } else if (fieldValue is String && fieldValue.isNotEmpty) {
      return fieldValue;
    } else if (fieldValue is DateTime) {
      return DateFormat.jm().format(fieldValue);
    } else {
      return message;
    }
  }

  // Function to show a dialog for editing Age
  void _showEditAgeDialog(BuildContext context) {
    final sp = context.read<SignInProvider>();
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final blocUser = context.read<AuthenticationBloc>().state.user;
    String userIDBoth = firebaseUser?.uid ?? blocUser?.userID ?? '';
    TextEditingController _ageController = TextEditingController(text: sp.age);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Age'),
          content: TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Age'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String newAge = _ageController.text;
                await sp.updateAge(newAge, userIDBoth);

                // Save the age to SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                prefs.setInt('userAge', int.parse(newAge));

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Function to show a dialog for editing Gender
  void _showEditGenderDialog(BuildContext context) {
    final sp = context.read<SignInProvider>();
    TextEditingController _genderController =
        TextEditingController(text: sp.gender);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Gender'),
          content: DropdownButtonFormField<String>(
            value: _genderController.text.isNotEmpty
                ? _genderController.text
                : 'Male', // Set 'Male' as the default value
            items: ['Male', 'Female', 'Other'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              _genderController.text = newValue!;
            },
            decoration: const InputDecoration(labelText: 'Gender'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await sp.updateGender(_genderController.text);

                // Save the gender to SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                prefs.setString('gender', _genderController.text);

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget buildProfileCard(
      BuildContext context, IconData icon, ProfileCardType type) {
    final sp = context.watch<SignInProvider>();
    final blocUser = context.read<AuthenticationBloc>().state.user;
    String NameUser = blocUser?.name ?? '';
    String LastNameUser = blocUser?.lastName ?? '';
    String FullNameUser = '$NameUser $LastNameUser';
    String EmailUser = sp.email ?? blocUser?.email ?? '';
    String AgeUser = sp.age ?? blocUser?.age ?? '';
    String GenderUser = sp.gender ?? blocUser?.gender ?? '';
    String AddressUser = sp.address ?? blocUser?.address ?? '';

    bool isConnected = false;
    String title = "";
    String subtitle = "";

    // Determine the title and subtitle based on the card type
    switch (type) {
      case ProfileCardType.name:
        title = 'Name';
        subtitle = FullNameUser;
        break;
      case ProfileCardType.age:
        title = 'Age';
        subtitle = _generateSubtitleForNull(AgeUser, 'Enter Age');
        break;
      case ProfileCardType.gender:
        title = 'Gender';
        subtitle = _generateSubtitleForNull(GenderUser, 'Enter Gender');
        break;
      case ProfileCardType.signout:
        title = 'Sign Out';
        // subtitle = _generateSubtitleForNull("");
        break;
      case ProfileCardType.google:
        title = 'Google';
        isConnected = sp.provider == "GOOGLE";
        subtitle = isConnected ? "Connected" : "";
        break;
      case ProfileCardType.email:
        title = 'Email';
        subtitle = _generateSubtitleForNull(EmailUser, 'Enter Email');
        break;
      case ProfileCardType.address:
        title = 'Address';
        subtitle = _generateSubtitleForNull(AddressUser, 'Enter Address');
        break;
    }

    return GestureDetector(
        onTap: () => type.handleTap(context, sp,
            showEditNameDialog: _showEditNameDialog,
            showEditEmailDialog: _showEditEmailDialog,
            showEditAgeDialog: _showEditAgeDialog,
            showEditGenderDialog: _showEditGenderDialog,
            showEditAddressDialog: _showEditAddressDialog),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
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
            leading: Icon(
              icon,
              color: const Color(colorPrimary),
              size: 32,
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isConnected
                    ? Colors.white.withOpacity(0.7)
                    : Colors.white.withOpacity(0.7),
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(colorPrimary),
            ),
          ),
        ));
  }

  // handling google sigin in
  Future handleGoogleSignIn() async {
    final sp = context.read<SignInProvider>();
    final ip = context.read<InternetProvider>();
    await ip.checkInternetConnection();

    if (ip.hasInternet == false) {
      openSnackbar(context, "Check your Internet connection", Colors.red);
      googleController.reset();
    } else {
      await sp.signInWithGoogle().then((value) {
        if (sp.hasError == true) {
          openSnackbar(context, sp.errorCode.toString(), Colors.red);
          googleController.reset();
        } else {
          // checking whether user exists or not
          sp.checkUserExists().then((value) async {
            if (value == true) {
              // user exists
              await sp.getUserDataFromFirestore(sp.uid).then((value) => sp
                  .saveDataToSharedPreferences()
                  .then((value) => sp.setSignIn().then((value) {
                        googleController.success();
                        //handleAfterSignIn();
                      })));
            } else {
              // user does not exist
              sp.saveDataToFirestore(selectedTime).then((value) => sp
                  .saveDataToSharedPreferences()
                  .then((value) => sp.setSignIn().then((value) {
                        googleController.success();
                        // handleAfterSignIn();
                      })));
            }
          });
        }
      });
    }
  }
}
