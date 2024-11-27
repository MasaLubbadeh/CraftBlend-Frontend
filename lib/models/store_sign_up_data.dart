class StoreSignUpData {
  String? storeName;
  String? contactEmail;
  String? phoneNumber;
  String? password;
  String? accountType;
  String? selectedGenre;
  String? country;
  String? city;
  bool? allowSpecialOrders;

  StoreSignUpData({
    this.storeName,
    this.contactEmail,
    this.phoneNumber,
    this.password,
    this.accountType,
    this.selectedGenre,
    this.allowSpecialOrders,
    this.city,
    this.country,
  });

  @override
  String toString() {
    return 'StoreSignUpData(storename: $storeName, contactEmail: $contactEmail, allowSpecialOrders: $allowSpecialOrders, phoneNumber: $phoneNumber, password: $password, accountType: $accountType, selectedGenre: $selectedGenre,city: $city,country:$country)';
  }

  Map<String, dynamic> toJson() {
    return {
      "storeName": storeName,
      "contactEmail": contactEmail,
      "phoneNumber": phoneNumber,
      "password": password,
      "accountType": accountType,
      "selectedGenre": selectedGenre,
      "country": country,
      "city": city,
      "allowSpecialOrders": allowSpecialOrders,
    };
  }
}
