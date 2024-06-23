import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:http_interceptor/models/interceptor_contract.dart';
import 'package:logger/logger.dart';
import 'package:socket_chat_client/main.dart';

import '../utils.dart';
import 'local_storage_service.dart';

class AuthInterceptor extends InterceptorContract {
  AuthInterceptor();

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
    logger.i("Response: ${response.toString()}");
    if (response.statusCode == 401) {
      await LocalStorage.clear();
      Utils.showSnackBarWithoutContext("Session expired. Please login again.");
      navigatorKey.currentState!
          .pushNamedAndRemoveUntil("/", (Route<dynamic> route) => false);
    }
    return response;
  }
}
