library kyte_dart;

import 'package:dotenv/dotenv.dart';
import 'package:kyte_dart/model_response.dart';

import 'api.dart';
import 'kyte_error_response.dart';

class Kyte {
  static final Kyte _instance = Kyte._internal();
  String _sessionToken = "0";
  String _txToken = "0";

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
    var env = DotEnv(includePlatformEnvironment: true)..load();
    final String kyte_endpoint = env['kyte_endpoint'] ?? "";
    final String kyte_identifier = env['kyte_identifier'] ?? "";
    final String kyte_account = env['kyte_account'] ?? "";
    final String kyte_publickey = env['kyte_publickey'] ?? "";
    final String kyte_secretkey = env['kyte_secretkey'] ?? "";
    final String kyte_appid = env['kyte_appid'] ?? "";

    if (kyte_endpoint.isEmpty) {
      throw Exception(
          "Kyte endpoint cannot be empyt. Please define kyte_endpoint in your .env file.");
    }
    if (kyte_identifier.isEmpty) {
      throw Exception(
          "Kyte identifier cannot be empyt. Please define kyte_identifier in your .env file.");
    }
    if (kyte_account.isEmpty) {
      throw Exception(
          "Kyte account number cannot be empyt. Please define kyte_account in your .env file.");
    }
    if (kyte_publickey.isEmpty) {
      throw Exception(
          "Kyte public key cannot be empyt. Please define kyte_publickey in your .env file.");
    }
    if (kyte_secretkey.isEmpty) {
      throw Exception(
          "Kyte secret key cannot be empyt. Please define kyte_secretkey in your .env file.");
    }

    Api api = Api(kyte_endpoint, kyte_identifier, kyte_account, kyte_publickey,
        kyte_secretkey, kyte_appid);

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
