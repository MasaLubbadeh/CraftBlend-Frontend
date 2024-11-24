class SignUpData {
  String? firstName;
  String? lastName;
  String? email;
  String? phoneNumber;
  String? password;

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "phoneNumber": phoneNumber,
      "password": password,
    };
  }
}
