// Copyright 2023 KeyQ, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';
// import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kyte_dart/http_exception.dart';

import 'kyte_error_response.dart';

/// HTTP method types declared as an enum
enum KyteRequestType { post, put, get, delete }

class Api {
  /// The endpoint url for the Kyte API
  final String endpoint;

  /// The identifier string for the account used in Kyte
  final String identifier;

  /// The account number for the account used in Kyte
  final String accountNumber;

  /// The public key associated with the account used in Kyte
  final String publicKey;

  /// The secret key associated with the account used in Kyte
  final String secretKey;

  /// The application ID for the app on Kyte you will access
  final String appId;

  /// The session token, which defaults to "0" when there is no active session
  String sessionToken = "0";

  /// The transaction token, which defaults to "0" when there is no active session
  String txToken = "0";

  var client = http.Client();

  Api(this.endpoint, this.identifier, this.accountNumber, this.publicKey,
      this.secretKey, this.appId);

  /// Generate signature required to authenticate with API using current datetime in UTC as [now]
  String generateSignature(DateTime now) {
    /// Generate the first set of SHA256 hmac from transaction token
    /// using the secret key as key
    var hmacSha256 = Hmac(sha256, utf8.encode(secretKey));
    var hash1 = hmacSha256.convert(utf8.encode(txToken));

    /// Generate the second set of SHA256 hmac from the account identifier
    /// using the fisrt hash as key
    var hmacSha256_2 = Hmac(sha256, hash1.bytes);
    var hash2 = hmacSha256_2.convert(utf8.encode(identifier));

    /// The epoch time which is used in generating the signature
    var epochTimeStamp = (now.millisecondsSinceEpoch / 1000).floor().toString();

    /// Generate the third and last set of SHA256 hmac from the epoch time
    /// using the second hash as key.
    /// Return hash as string
    var hmacSha256_3 = Hmac(sha256, hash2.bytes);
    var signature =
        hmacSha256_3.convert(utf8.encode(epochTimeStamp)).toString();

    return signature;
  }

  /// Get current datetime in UTC to be used in generating the signature and identity string
  DateTime formattedTimeStamp() {
    /// The current date time in seconds (epoch), but as final so it doesn't change
    final microsecondsSinceEpoch = DateTime.now().microsecondsSinceEpoch;

    /// Create a DateTime from the microsencds
    DateTime now = DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch,
        isUtc: true);

    return now;
  }

  /// Generate the identity string to pass along in the header with
  /// current date time [now]
  String generateIdentity(DateTime now) {
    String formattedDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss').format(now);

    String encoded = base64.encode(
        utf8.encode('$publicKey%$sessionToken%$formattedDate%$accountNumber'));

    return encoded;
  }

  /// Generate a map of headers to be sent to Kyte API.
  ///
  /// THe default headers that are required are:
  /// * X-KYTE-SIGNATURE
  /// * X-KYTE-IDENTITY
  /// * X-KYTE-PAGE-IDX
  /// * X-KYTE-PAGE-SIZE
  Map<String, String> generateHeader(
      {Map<String, String>? customHeaders,
      String pageId = "1",
      String pageSize = "50",
      String contentType = "application/json"}) {
    var timeStamp = formattedTimeStamp();
    var identityString = generateIdentity(formattedTimeStamp());
    var signature = generateSignature(timeStamp);

    Map<String, String> header = {
      "Content-type": contentType,
      "X-KYTE-SIGNATURE": signature,
      "X-KYTE-IDENTITY": identityString,
      "X-KYTE-PAGE-IDX": pageId,
      "X-KYTE-PAGE-SIZE": pageSize,
    };

    if (appId.isNotEmpty) {
      header.addEntries({"X-KYTE-APPID": appId}.entries);
    }

    if (customHeaders != null) {
      header.addEntries(customHeaders.entries);
    }

    return header;
  }

  /// Generate the final endpoint URL and path based on request using [model], and
  /// optional fields [field] and [value].
  Uri generateEndpointUrl(String? model, {String? field, String? value}) {
    if (field != null && value != null) {
      return Uri.parse('$endpoint/$model/$field/$value');
    } else {
      var url = Uri.parse('$endpoint/$model');
      return url;
    }
  }

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
      String pageSize = "0",
      String contentType = "application/json"}) async {
    http.Response response;
    switch (method) {
      /// Make POST request
      case KyteRequestType.post:
        if (body == null) {
          /// If request body is empty, throw exception
          throw Exception('Data body cannot be null for POST request');
        }
        response = await post(model, body,
            customHeaders: customHeaders,
            pageId: pageId,
            pageSize: pageSize,
            contentType: contentType);
        break;

      /// Make PUT request
      case KyteRequestType.put:
        if (body == null) {
          /// If request body is empty, throw exception
          throw Exception('Data body cannot be null for PUT request');
        }
        response = await put(model, body,
            field: field,
            value: value,
            customHeaders: customHeaders,
            pageId: pageId,
            pageSize: pageSize,
            contentType: contentType);
        break;

      /// Make GET request
      case KyteRequestType.get:
        response = await get(model,
            field: field,
            value: value,
            customHeaders: customHeaders,
            pageId: pageId,
            pageSize: pageSize,
            contentType: contentType);
        break;

      /// Make DELETE request
      case KyteRequestType.delete:
        response = await delete(model,
            field: field,
            value: value,
            customHeaders: customHeaders,
            pageId: pageId,
            pageSize: pageSize,
            contentType: contentType);
        break;
      default:

        /// Unknown or unsupported HTTP request
        throw Exception(
            'Unknown or unsupported HTTP request. Must be POST, PUT, GET, or DELETE');
    }

    try {
      if (response.body.isEmpty) {
        /// If the response body is empty, throw an exception.
        throw Exception("Response body is empty.");
      }

      if (response.statusCode != 200) {
        /// If the response status code was other than 200, return a Kyte Error
        return KyteErrorResponse.fromJson(json.decode(response.body));
      }

      /// Parse JSOn from successful response body and return model
      return fromJosn(json.decode(response.body));
    } catch (e) {
      /// If there was an error with parsing the data, throw exception
      throw HttpException("Unable to parse response data. ${e.toString()}",
          responseCode: response.statusCode);
    }
  }

  /// POST Request
  Future<dynamic> post(String model, String body,
      {Map<String, String>? customHeaders,
      String pageId = "1",
      String pageSize = "0",
      String contentType = "application/json"}) async {
    http.Response response;

    try {
      response = await client.post(
        generateEndpointUrl(model),
        headers: generateHeader(
            customHeaders: customHeaders,
            pageId: pageId,
            pageSize: pageSize,
            contentType: contentType),
        body: body,
      );
    } catch (e) {
      throw Exception("Unable to make POST request. ${e.toString()}");
    }

    return response;
  }

  /// GET Request
  Future<dynamic> get(String model,
      {String? field,
      String? value,
      Map<String, String>? customHeaders,
      String pageId = "1",
      String pageSize = "0",
      String contentType = "application/json"}) async {
    http.Response response;

    try {
      response = await client.get(
        generateEndpointUrl(model, field: field, value: value),
        headers: generateHeader(
            customHeaders: customHeaders,
            pageId: pageId,
            pageSize: pageSize,
            contentType: contentType),
      );
    } catch (e) {
      throw Exception("Unable to make GET request. ${e.toString()}");
    }

    return response;
  }

  /// PUT Request
  Future<dynamic> put(String model, String body,
      {String? field,
      String? value,
      Map<String, String>? customHeaders,
      String pageId = "1",
      String pageSize = "0",
      String contentType = "application/json"}) async {
    http.Response response;

    try {
      response = await client.put(
        generateEndpointUrl(model, field: field, value: value),
        headers: generateHeader(
            customHeaders: customHeaders,
            pageId: pageId,
            pageSize: pageSize,
            contentType: contentType),
        body: body,
      );
    } catch (e) {
      throw Exception("Unable to make PUT request. ${e.toString()}");
    }

    return response;
  }

  /// DELETE Request
  Future<dynamic> delete(String model,
      {String? field,
      String? value,
      Map<String, String>? customHeaders,
      String pageId = "1",
      String pageSize = "0",
      String contentType = "application/json"}) async {
    http.Response response;

    try {
      response = await client.delete(
        generateEndpointUrl(model, field: field, value: value),
        headers: generateHeader(
            customHeaders: customHeaders,
            pageId: pageId,
            pageSize: pageSize,
            contentType: contentType),
      );
    } catch (e) {
      throw Exception("Unable to make DELETE request. ${e.toString()}");
    }

    return response;
  }
}
