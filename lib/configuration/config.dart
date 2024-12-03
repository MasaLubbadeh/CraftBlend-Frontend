import 'dart:ui';

// All the URLs that point to the Node.js backend API
const String url = 'http://192.168.1.17:3000/';
bool isLoggedIn = false;
const String login = '${url}login';
const String registration = '${url}registration';
const String validateTokenEndpoint = '${url}validateToken';
const String resetPassword = '${url}resetPassword';
const String forgotPassword = '${url}forgotPassword';
const String getPersonalInfo = '${url}getPersonalInfo';
const String updateUserPersonalInfo = '${url}updateUserPersonalInfo';
const String addCreditCard = '${url}addCreditCard';
const String getCreditCardData = '${url}getCreditCardData'; //check-email
const String checkEmail = '${url}check-email';

const String addNewPastryProduct = '${url}product/addNewPastryProduct';
const String getAllProducts = '${url}product/getAllProducts';
const String updateProductInfo = '${url}product/updateProductInfo';
const String deleteProductByID = '${url}product/deleteProduct';

const String addNewCategory = '${url}category/add';
const String deleteCategory = '${url}category/delete';
const String getAllCategories = '${url}category/all';
const String getAllStoresAndCategories =
    '${url}category/categories-and-stores'; //getStoresByCategory
const String getStoresByCategory = '${url}category';

const String storeRegistration = '${url}store/registration';
const String getStoreProducts =
    '${url}store/getAllProducts'; //categories-and-stores ////getProductsByStoreId
const String getStoreProductsForUser = '${url}store/getProductsByStoreId';
const String getStoreDetails = '${url}store/details';

const Color myColor = Color.fromARGB(
    255, 122, 104, 135); //Color(0xff6B4F4F); //Color(0xff456268);

const Color primaryColor = Color(0xffA47551); // A warm brown color
const Color accentColor = Color(0xffD9C4B1); // A lighter beige accent
const Color backgroundColor = Color(0xffF2E9E4); // Light background color
const Color textColor = Color(0xff6B4F4F); // Darker brown for text
const Color buttonColor =
    Color(0xff8C6E58); // Slightly darker for button shadows

// Function to retrieve the token from SharedPreferences
/*
Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token'); // Retrieve the token
}
*/
