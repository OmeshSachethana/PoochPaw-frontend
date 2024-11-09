class PetIdManager {
  static PetIdManager? _instance;

  String? _petId;
  String? _petName;
  String? _petType;
  String? _petAge;
  String? _petGender;
  String? _petEnergylvl;
  String? _petHealthC;
  String? _petWeight;

  factory PetIdManager() {
    _instance ??= PetIdManager._();
    return _instance!;
  }

  PetIdManager._();

  String? get petId => _petId;
  String? get petName => _petName;
  String? get petType => _petType;
  String? get petAge => _petAge;
  String? get petGender => _petGender;
  String? get petEnergylvl => _petEnergylvl;
  String? get petHealthC => _petHealthC;
  String? get petWeight => _petWeight;

  void setPetId(String? newPetId) {
    _petId = newPetId;
  }

  void setPetName(String? newPetName) {
    _petName = newPetName;
  }

  void setPetType(String? newPetType) {
    _petType = newPetType;
  }

  void setPetAge(String? newPetAge) {
    _petAge = newPetAge;
  }

  void setPetGender(String? newPetGender) {
    _petGender = newPetGender;
  }

  void setPetEnergylvl(String? newPetEnergylvl) {
    _petEnergylvl = newPetEnergylvl;
  }

  void setPetHealthC(String? newPetHealthC) {
    _petHealthC = newPetHealthC;
  }

  void setPetWeight(String? newPetWeight) {
    _petWeight = newPetWeight;
  }
}
