import 'package:http/http.dart';
import 'package:http_interceptor/models/interceptor_contract.dart';
import 'package:logger/logger.dart';
import 'package:socket_chat_client/main.dart';
import 'package:socket_chat_client/services/local_storage_service.dart';

import '../utils.dart';

class AuthInterceptor extends InterceptorContract {

  Logger logger = Logger();

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    logger.i("Request: ${request.toString()}");
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    if (response.statusCode == 401) {
      logger.i("Your session has expired. Please login again.");
      LocalStorage.clear();
      navigatorKey.currentState?.pushNamedAndRemoveUntil("/env", (route) => false);
    }
    return response;
  }
}
