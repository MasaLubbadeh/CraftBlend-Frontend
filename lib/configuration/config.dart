import 'dart:ui';

// All the URLs that point to the Node.js backend API
const String url = 'http://192.168.1.22:3000/';
bool isLoggedIn = false;
const String login = '${url}login';
const String registration = '${url}registration';
const String validateTokenEndpoint = '${url}validateToken';
const String resetPassword = '${url}resetPassword';
const String forgotPassword = '${url}forgotPassword';
const String getPersonalInfo = '${url}getPersonalInfo';
const String updateUserPersonalInfo = '${url}updateUserPersonalInfo';
const String addCreditCard = '${url}addCreditCard';
const String getCreditCardData = '${url}getCreditCardData';
const String checkEmail = '${url}check-email';

const String addFavoriteStore = '${url}favoriteStores';
const String removeFavoriteStore = '${url}favoriteStores';
const String checkIfFavoriteStore = '${url}favoriteStores/checkIfFav';
const String getFavStoresProducts = '${url}favoriteStores/getStoresProducts';

const String addToWishlist = '${url}wishlist';
const String removeFromWishlist = '${url}wishlist';
const String checkIfInWishlist = '${url}wishlist/checkIfExist';
const String getWishlistProducts = '${url}wishlist/getList';

const String getRecommendedStoresByCategory =
    '${url}getRecommendedStoresByCategory';

const String addNewPastryProduct = '${url}product/addNewPastryProduct';
const String getAllProducts = '${url}product/getAllProducts';
const String updateProductInfo = '${url}product/updateProductInfo';
const String deleteProductByID = '${url}product/deleteProduct';
const String reduceProductQuantity = '${url}product/reduce-quantity';
const String getMostSearched = '${url}product/getMostSearched';
const String rateProduct = '${url}product/rateProduct';

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
const String getStoreDeliveryCities = '${url}store/getDelivery-cities';
const String getStoreDeliveryCitiesByID = '${url}store/getDelivery-citiesByID';

const String updateDeliveryCitiesUrl = '${url}store/UpdateDelivery-cities';
const String getAllStores = '${url}store/getAllStores';
const String checkIfAllowSpecialOrders =
    '${url}store/checkIfAllowSpecialOrders';
const String rateStore = '${url}store/rateStore';

const String addNewCartItem = '${url}cart/addNewCartItem';
const String getCartData = '${url}cart/getCartData';
const String updateCartItem = '${url}cart/updateCartItem';
const String fetchInstantCartItems = '${url}cart/fetchInstantItems';
const String fetchScheduledCartItems = '${url}cart/fetchScheduledItems';
const String removeCartItem = '${url}cart/removeCartItems';

const String placeOrder = '${url}order/placeOrder';
const String getOrdersByStoreId = '${url}order/getOrdersByStoreId';
const String getUserOrders = '${url}order/getUserOrders';
const String updateOrderStatusUrl = '${url}order';
const String updateOrderItemsStatusUrl = '${url}order/updateItemStatus';

const String incrementItemSearchCounts = '${url}search/incrementSearchCounts';
const String getSuggestedProducts =
    '${url}search/getSuggestedProducts'; // from search and wishList

const String getUserActivity = '${url}userActivity/getActivity';
const String updateLastVisitedCategory =
    '${url}userActivity/updateLastVisitedCategory';
const String addProductVisit = '${url}userActivity/addProductVisit';
const String addSearchHistory = '${url}userActivity/addSearchHistory';
const String addStoreView = '${url}userActivity/addStoreView';
const String getRecentlyViewedProducts =
    '${url}userActivity/getRecentlyViewedProducts';
const String getFirstLast = '${url}getFullName';
const String createUserPost = '${url}posts/userCreate';
const String createStorePost = '${url}posts/storeCreate';

const String fetchAllPosts = '${url}fetchAllPosts';
const String likes = '${url}';
const String upvotes = '${url}';
const String downvotes = '${url}';
const String comments = '${url}';

const String addNewAdvertisement = '${url}advertisement/add';
const String getAllAdvertisements = '${url}advertisement/getAll';
const String getStoreAdvertisements = '${url}advertisement/getSoreAd';
const String removeAdvertisement = '${url}advertisement/removeAdvertisement';

const String profile = '${url}profile';
const String getID = '${url}getID';
const String getAllCities = '${url}city/getAll';
const String incrementCityStoreCount = '${url}city/';

const String submitNewSuggestion =
    '${url}categorySuggestion/submitNewSuggestion';
const String getAllSuggestions = '${url}categorySuggestion/getAllSuggestions';
const String updateSuggestionStatus =
    '${url}categorySuggestion/updateSuggestionStatus';

const String fetchProfileInfo = '${url}store/fetchProfileInfo';
const String fetchAccountPosts = '${url}posts/fetchAccountPosts';

const Color myColor = Color.fromARGB(
    255, 122, 104, 135); //Color(0xff6B4F4F); //Color(0xff456268);
const myColor2 = myColor;

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
