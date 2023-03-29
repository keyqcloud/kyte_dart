library kyte_dart;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kyte_dart/http_exception.dart';
import 'package:kyte_dart/model_response.dart';

import 'api.dart';
import 'kyte_error_response.dart';

class Kyte {
  static final Kyte _instance = Kyte._internal();
  String _sessionToken = GetStorage().read('kyteSessionToken') ?? "0";
  String _txToken = GetStorage().read('kyteTxToken') ?? "0";

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
      String pageSize = "50",
      String contentType = "application/json"}) async {
    await dotenv.load(fileName: ".env");
    final String kyteEndpoint = dotenv.env['kyte_endpoint'] ?? "";
    final String kyteIdentifier = dotenv.env['kyte_identifier'] ?? "";
    final String kyteAccount = dotenv.env['kyte_account'] ?? "";
    final String kytePublickey = dotenv.env['kyte_publickey'] ?? "";
    final String kyteSecretkey = dotenv.env['kyte_secretkey'] ?? "";
    final String kyteAppid = dotenv.env['kyte_appid'] ?? "";

    if (kyteEndpoint.isEmpty) {
      throw Exception(
          "Kyte endpoint cannot be empyt. Please define kyte_endpoint in your .env file.");
    }
    if (kyteIdentifier.isEmpty) {
      throw Exception(
          "Kyte identifier cannot be empyt. Please define kyte_identifier in your .env file.");
    }
    if (kyteAccount.isEmpty) {
      throw Exception(
          "Kyte account number cannot be empyt. Please define kyte_account in your .env file.");
    }
    if (kytePublickey.isEmpty) {
      throw Exception(
          "Kyte public key cannot be empyt. Please define kyte_publickey in your .env file.");
    }
    if (kyteSecretkey.isEmpty) {
      throw Exception(
          "Kyte secret key cannot be empyt. Please define kyte_secretkey in your .env file.");
    }

    Api api = Api(kyteEndpoint, kyteIdentifier, kyteAccount, kytePublickey,
        kyteSecretkey, kyteAppid);

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
      rethrow;
    }

    // retrieve session and tx token and internal update variables
    final dynamic modelResponse = response;
    _sessionToken = (modelResponse as ModelResponse).sessionToken ?? "0";
    _txToken = modelResponse.txToken ?? "0";

    GetStorage().write('kyteSessionToken', _sessionToken);
    GetStorage().write('kyteTxToken', _txToken);

    // check response code
    if (modelResponse.responseCode == 400) {
      throw HttpException(
          (modelResponse as KyteErrorResponse).message ??
              "Unknown error response from API",
          responseCode: modelResponse.responseCode);
    }
    if (modelResponse.responseCode == 403) {
      throw HttpException(
          (modelResponse as KyteErrorResponse).message ?? "Unauthorized Access",
          responseCode: modelResponse.responseCode);
    }
    if (modelResponse.responseCode != 200) {
      throw HttpException(
          (modelResponse as KyteErrorResponse).message ??
              "Unknown error response from API. Error code ${modelResponse.responseCode}.",
          responseCode: modelResponse.responseCode);
    }

    return response;
  }
}
