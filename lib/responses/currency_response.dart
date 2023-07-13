
import 'package:rider_app/responses/response_requests.dart';
import 'package:rider_app/utils/api_keys.dart';

class CurrencyResponse {
  static Future<double> getUSDToPKRRate()async{
    double usdToPkr = 0;
    String url = 'https://rest.coinapi.io/v1/exchangerate/USD/PKR?apikey=$currencyAPIKey';
    var response = await ResponseRequest().getRequest(url);
    if(response != 'Failed'){
      usdToPkr = response['rate'];
    }
    return usdToPkr;
  }
}