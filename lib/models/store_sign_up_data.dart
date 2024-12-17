class StoreSignUpData {
  String? storeName;
  String? contactEmail;
  String? phoneNumber;
  String? password;
  String? accountType;
  String? selectedGenreId; // This stores the ID of the selected genre/category
  String? country;
  String? city;
  String? logo;
  bool? allowSpecialOrders;

  StoreSignUpData({
    this.storeName,
    this.contactEmail,
    this.phoneNumber,
    this.password,
    this.accountType,
    this.selectedGenreId,
    this.allowSpecialOrders,
    this.city,
    this.logo,
    this.country,
  });

  @override
  String toString() {
    return 'StoreSignUpData(storename: $storeName, contactEmail: $contactEmail, allowSpecialOrders: $allowSpecialOrders, phoneNumber: $phoneNumber, password: $password, accountType: $accountType, selectedGenreId: $selectedGenreId, city: $city, logo:$logo, country: $country)';
  }

  Map<String, dynamic> toJson() {
    return {
      "storeName": storeName,
      "contactEmail": contactEmail,
      "phoneNumber": phoneNumber,
      "password": password,
      "accountType": accountType,
      "selectedGenreId": selectedGenreId,
      "country": country,
      "city": city,
      "logo": logo,
      "allowSpecialOrders": allowSpecialOrders,
    };
  }
}
