import '../services/storage_service.dart';

class UserSession {
  static final UserSession instance = UserSession._internal();
  UserSession._internal();

  bool canViewPrices = true;
  String userType = 'CUSTOMER';

  // MANSTOCK & general permissions
  bool canAccessStockApp = false;
  bool canPurchaseDelivery = false;
  bool canReturnDelivery = false;
  bool canStockCount = false;
  bool canViewItemCard = false;
  bool canChangeLocation = false;
  bool canReviewDeliveryInvoices = false;

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

      // Load MANSTOCK permissions
      canAccessStockApp = _toBool(userData['canAccessStockApp']);
      canPurchaseDelivery = _toBool(userData['canPurchaseDelivery']);
      canReturnDelivery = _toBool(userData['canReturnDelivery']);
      canStockCount = _toBool(userData['canStockCount']);
      canViewItemCard = _toBool(userData['canViewItemCard']);
      canChangeLocation = _toBool(userData['canChangeLocation']);
      canReviewDeliveryInvoices = _toBool(userData['canReviewDeliveryInvoices']);
    } else {
      canViewPrices = true;
      _resetPermissions();
    }
  }

  bool _toBool(dynamic value) {
    if (value == null) return false;
    return value == 1 || value == '1' || value == true || value.toString() == 'true';
  }

  void _resetPermissions() {
    canAccessStockApp = false;
    canPurchaseDelivery = false;
    canReturnDelivery = false;
    canStockCount = false;
    canViewItemCard = false;
    canChangeLocation = false;
    canReviewDeliveryInvoices = false;
  }
}
