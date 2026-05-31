import '../services/storage_service.dart';

class UserSession {
  static final UserSession instance = UserSession._internal();
  UserSession._internal();

  bool canViewPrices = true;
  String userType = 'CUSTOMER';

  Future<void> load() async {
    final storage = StorageService();
    final userData = await storage.getUserData();
    userType = await storage.getUserType() ?? 'CUSTOMER';
    if (userData != null) {
      if (userType == 'CUSTOMER_EMP' || userData['type'] == 'CUSTOMER_EMP') {
        var viewPrices = userData['canViewPrices'];
        if (viewPrices == 0 || viewPrices == '0' || viewPrices == false) {
          canViewPrices = false;
        } else {
          canViewPrices = true;
        }
      } else {
        canViewPrices = true;
      }
    } else {
      canViewPrices = true;
    }
  }
}
