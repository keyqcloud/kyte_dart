library kyte_dart;

import 'package:kyte_dart/model_response.dart';

import 'api.dart';
import 'kyte_error_response.dart';

class Kyte {
  static final Kyte _instance = Kyte._internal();
  // final Api api;

  String? endpoint;
  String? identifier;
  String? accountNumber;
  String? publicKey;
  String? secretKey;

  String _sessionToken = "0";
  String _txToken = "0";

  final String _endpoint = const String.fromEnvironment('kyte_endpoint');
  final String _identifier = const String.fromEnvironment('kyte_identifier');
  final String _accountNumber = const String.fromEnvironment('kyte_account');
  final String _publicKey = const String.fromEnvironment('kyte_publickey');
  final String _secretKey = const String.fromEnvironment('kyte_secretkey');

  factory Kyte() {
    return _instance;
  }

  Kyte._internal();

  //
  Future<dynamic> request(dynamic Function(Map<String, dynamic> json) fromJosn,
      KyteRequestType method, String model,
      {String? body,
      String? field,
      String? value,
      Map<String, String>? customHeaders,
      String pageId = "1",
      String pageSize = "0",
      String contentType = "application/json"}) async {
    Api api = Api(
        endpoint ?? _endpoint,
        identifier ?? _identifier,
        accountNumber ?? _accountNumber,
        publicKey ?? _publicKey,
        secretKey ?? _secretKey);

    api.sessionToken = _sessionToken;
    api.txToken = _txToken;

    dynamic response;

    try {
      response = await api.request(fromJosn, method, model,
          body: body,
          field: field,
          value: value,
          customHeaders: customHeaders,
          pageId: pageId,
          pageSize: pageSize,
          contentType: contentType);
    } catch (e) {
      throw Exception(e.toString());
    }

    // retrieve session and tx token and internal update variables
    final dynamic modelResponse = response;
    _sessionToken = (modelResponse as ModelResponse).sessionToken ?? "0";
    _txToken = modelResponse.txToken ?? "0";

    // check response code
    if (modelResponse.responseCode == 400) {
      throw Exception((modelResponse as KyteErrorResponse).message ??
          "Unknown error response from API");
    }
    if (modelResponse.responseCode == 403) {
      throw Exception((modelResponse as KyteErrorResponse).message ??
          "Unauthorized Access");
    }
    if (modelResponse.responseCode != 200) {
      throw Exception((modelResponse as KyteErrorResponse).message ??
          "Unknown error response from API. Error code ${modelResponse.responseCode}.");
    }

    return response;
  }
}
