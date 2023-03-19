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
      String pageSize = "0",
      String contentType = "application/json"}) async {
    await dotenv.load(fileName: ".env");
    final String kyte_endpoint = dotenv.env['kyte_endpoint'] ?? "";
    final String kyte_identifier = dotenv.env['kyte_identifier'] ?? "";
    final String kyte_account = dotenv.env['kyte_account'] ?? "";
    final String kyte_publickey = dotenv.env['kyte_publickey'] ?? "";
    final String kyte_secretkey = dotenv.env['kyte_secretkey'] ?? "";
    final String kyte_appid = dotenv.env['kyte_appid'] ?? "";

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
      throw e;
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
