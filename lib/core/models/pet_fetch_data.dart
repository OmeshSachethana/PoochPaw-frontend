class PetData {
  // The title of the pet
  final String title;
  // The id of the pet
  final String petid;

  // The type of the pet
  final String petType;
  // The petAge of the pet
  final String petAge;
  // The petGender of the pet
  final String petGender;
  // The petEnergylvl of the pet
  final String petEnergylvl;
  // The petHealthC of the pet
  final String petHealthC;
  // The petWeight of the pet
  final String petWeight;

  PetData({
    required this.title,
    required this.petid,
    required this.petType,
    required this.petAge,
    required this.petGender,
    required this.petEnergylvl,
    required this.petHealthC,
    required this.petWeight,
  });

  // Convert the object to a json object
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'petid': petid,
      'petType': petType,
      'petAge': petAge,
      'petGender': petGender,
      'petEnergylvl': petEnergylvl,
      'petHealthC': petHealthC,
      'petWeight': petWeight,
    };
  }

  // Create a new PetData object from a json object
  factory PetData.fromJson(Map<String, dynamic> json) {
    return PetData(
      title: json['title'],
      petid: json['petid'],
      petType: json['petType'],
      petAge: json['petAge'],
      petGender: json['petGender'],
      petEnergylvl: json['petEnergylvl'],
      petHealthC: json['petHealthC'],
      petWeight: json['petWeight'],
    );
  }
}
