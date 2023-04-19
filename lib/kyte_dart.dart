// Copyright 2023 KeyQ, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// kyte_dart package.
///
/// kyte_dart is a Flutter package that enables seamless communication between
/// your app and a Kyte API endpoint, whether deployed by Kyte Shipyard or
/// custom deployment using KytePHP.
library kyte_dart;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kyte_dart/kyte_http_exception.dart';
import 'package:kyte_dart/model_response.dart';

import 'api.dart';
import 'kyte_error_response.dart';

class Kyte {
  /// The singleton class, only initialized once
  static final Kyte _instance = Kyte._internal();

  /// The session token, which defaults to "0" when there is no active session.
  String _sessionToken = GetStorage().read('kyteSessionToken') ?? "0";

  /// The transaction token, which defaults to "0" when there is no active session.
  String _txToken = GetStorage().read('kyteTxToken') ?? "0";

  /// Constructor returns itself
  factory Kyte() {
    return _instance;
  }

  Kyte._internal();

  /// Makes an HTTP request to the Kyte API backend and returns model data
  /// from JSON.
  ///
  /// the [fromJson] method must be defined for your model and passed along with
  /// [method], which is the HTTP method defined as a KyteRequestType, and the
  /// name of your model as a string [model].
  ///
  /// All other arguments are optional but may be required for the specific type
  /// of call you are making to the backend.
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
      /// If the endpoint is empty, throw and exception and inform user that it must be defined in the .env file
      throw Exception(
          "Kyte endpoint cannot be empyt. Please define kyte_endpoint in your .env file.");
    }
    if (kyteIdentifier.isEmpty) {
      /// If the account identifier is empty, throw and exception and inform user that it must be defined in the .env file
      throw Exception(
          "Kyte identifier cannot be empyt. Please define kyte_identifier in your .env file.");
    }
    if (kyteAccount.isEmpty) {
      throw Exception(

          /// If the account number is empty, throw and exception and inform user that it must be defined in the .env file
          "Kyte account number cannot be empyt. Please define kyte_account in your .env file.");
    }
    if (kytePublickey.isEmpty) {
      /// If the public key is empty, throw and exception and inform user that it must be defined in the .env file
      throw Exception(
          "Kyte public key cannot be empyt. Please define kyte_publickey in your .env file.");
    }
    if (kyteSecretkey.isEmpty) {
      /// If the private key is empty, throw and exception and inform user that it must be defined in the .env file
      throw Exception(
          "Kyte secret key cannot be empyt. Please define kyte_secretkey in your .env file.");
    }

    /// Instantiate Api class with the provided Kyte parameters
    Api api = Api(kyteEndpoint, kyteIdentifier, kyteAccount, kytePublickey,
        kyteSecretkey, kyteAppid);

    /// Set session and transaction tokens to default or what is stored from a past transaction
    api.sessionToken = _sessionToken;
    api.txToken = _txToken;

    /// Attempt to make request to Kyte API and get response or throw exception
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

    /// get a final copy of response to obtain session and transaction tokens,
    /// as well as be able to check the status code
    final dynamic modelResponse = response;

    /// retrieve session and tx token and internal update variables
    _sessionToken = (modelResponse as ModelResponse).sessionToken ?? "0";
    _txToken = modelResponse.txToken ?? "0";

    /// locally store session and transaction tokens for subsequent requests
    GetStorage().write('kyteSessionToken', _sessionToken);
    GetStorage().write('kyteTxToken', _txToken);

    if (modelResponse.responseCode == 400) {
      /// If the response code is 400, then request is unknown so throw exception
      throw KyteHttpException(
          (modelResponse as KyteErrorResponse).message ??
              "Unknown error response from API",
          responseCode: modelResponse.responseCode);
    }
    if (modelResponse.responseCode == 403) {
      /// If the response code is 403, then request is unauthorized so throw exception
      throw KyteHttpException(
          (modelResponse as KyteErrorResponse).message ?? "Unauthorized Access",
          responseCode: modelResponse.responseCode);
    }
    if (modelResponse.responseCode != 200) {
      /// If the response code is not 200, then unknown error, so throw exception
      throw KyteHttpException(
          (modelResponse as KyteErrorResponse).message ??
              "Unknown error response from API. Error code ${modelResponse.responseCode}.",
          responseCode: modelResponse.responseCode);
    }

    /// return parsed response
    return response;
  }
}
