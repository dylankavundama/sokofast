// API Config.dart
class ApiConfig {
  // REMPLACER ces PLACEHOLDERS par vos vraies valeurs de production
  static const String FLEXPAY_GATEWAY_URL = 'http://backend.flexpay.cd/api/rest/v1/paymentService'; 
  static const String MERCHANT_ID = 'STC_SARL'; 
  static const String BEARER_TOKEN ='eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJcL2xvZ2luIiwicm9sZXMiOlsiTUVSQ0hBTlQiXSwiZXhwIjoxODIyODE0NjM1LCJzdWIiOiI0NjEwYmVkZjg5YTdhNjQ5MjdlMDFkYzg4Yjk2MGZlOCJ9.siqrnMclrfpi6XbdIvTulvyLp8PoSrQhw5JPCbRuflE';
  // Base URL de votre backend (utilisée pour le callback)
   static const String BASE_URL = 'http://192.168.1.64/soko/api.php'; 
}

// Assurez-vous d'importer ApiConfig là où il est utilisé.