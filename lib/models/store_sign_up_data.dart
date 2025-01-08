class StoreSignUpData {
  String? storeName;
  String? contactEmail;
  String? phoneNumber;
  String? password;
  String? accountType;
<<<<<<< HEAD
  String? selectedGenreId; // This stores the ID of the selected genre/category
  String? country;
  String? city;
  String? logo;
=======
  String? selectedGenre;
  String? country;
  String? city;
>>>>>>> main
  bool? allowSpecialOrders;

  StoreSignUpData({
    this.storeName,
    this.contactEmail,
    this.phoneNumber,
    this.password,
    this.accountType,
<<<<<<< HEAD
    this.selectedGenreId,
    this.allowSpecialOrders,
    this.city,
    this.logo,
=======
    this.selectedGenre,
    this.allowSpecialOrders,
    this.city,
>>>>>>> main
    this.country,
  });

  @override
  String toString() {
<<<<<<< HEAD
    return 'StoreSignUpData(storename: $storeName, contactEmail: $contactEmail, allowSpecialOrders: $allowSpecialOrders, phoneNumber: $phoneNumber, password: $password, accountType: $accountType, selectedGenreId: $selectedGenreId, city: $city, logo:$logo, country: $country)';
=======
    return 'StoreSignUpData(storename: $storeName, contactEmail: $contactEmail, allowSpecialOrders: $allowSpecialOrders, phoneNumber: $phoneNumber, password: $password, accountType: $accountType, selectedGenre: $selectedGenre,city: $city,country:$country)';
>>>>>>> main
  }

  Map<String, dynamic> toJson() {
    return {
      "storeName": storeName,
      "contactEmail": contactEmail,
      "phoneNumber": phoneNumber,
      "password": password,
      "accountType": accountType,
<<<<<<< HEAD
      "selectedGenreId": selectedGenreId,
      "country": country,
      "city": city,
      "logo": logo,
=======
      "selectedGenre": selectedGenre,
      "country": country,
      "city": city,
>>>>>>> main
      "allowSpecialOrders": allowSpecialOrders,
    };
  }
}
