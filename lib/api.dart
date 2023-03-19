library kyte_dart;

import 'dart:convert';
// import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'kyte_error_response.dart';

enum KyteRequestType { post, put, get, delete }

class Api {
  final String endpoint;
  final String identifier;
  final String accountNumber;
  final String publicKey;
  final String secretKey;
  final String appId;
  String sessionToken = "0";
  String txToken = "0";
  var client = http.Client();

  Api(this.endpoint, this.identifier, this.accountNumber, this.publicKey,
      this.secretKey, this.appId);

// Map<String, String> headers = {"Content-type": "application/json"};

  // generate signature required to authenticate with API
  String generateSignature(DateTime now) {
    var hmacSha256 = Hmac(sha256, utf8.encode(secretKey));
    var hash1 = hmacSha256.convert(utf8.encode(txToken));

    var hmacSha256_2 = Hmac(sha256, hash1.bytes);
    var hash2 = hmacSha256_2.convert(utf8.encode(identifier));

    var epochTimeStamp = (now.millisecondsSinceEpoch / 1000).floor().toString();

    var hmacSha256_3 = Hmac(sha256, hash2.bytes);
    var signature =
        hmacSha256_3.convert(utf8.encode(epochTimeStamp)).toString();

    return signature;
  }

  // get datetime in UNIX seconds (epoch)
  DateTime formattedTimeStamp() {
    final microsecondsSinceEpoch = DateTime.now().microsecondsSinceEpoch;

    DateTime now = DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch,
        isUtc: true);

    return now;
  }

  // generate the identity string to pass along in the header
  String generateIdentity(DateTime now) {
    String formattedDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss').format(now);

    String encoded = base64.encode(
        utf8.encode('$publicKey%$sessionToken%$formattedDate%$accountNumber'));

    return encoded;
  }

  Map<String, String> generateHeader(
      {Map<String, String>? customHeaders,
      String pageId = "1",
      String pageSize = "0",
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
      header.addEntries({"X-KYTE-SIGNATURE": appId}.entries);
    }

    if (customHeaders != null) {
      header.addEntries(customHeaders.entries);
    }

    return header;
  }

  Uri generateEndpointUrl(String? model, {String? field, String? value}) {
    if (field != null && value != null) {
      return Uri.parse('$endpoint/$model/$field/$value');
    } else {
      var url = Uri.parse('$endpoint/$model');
      return url;
    }
  }

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
      // make post request
      case KyteRequestType.post:
        if (body == null) {
          throw Exception('Data body cannot be null for POST request');
        }
        response = await post(model, body,
            customHeaders: customHeaders,
            pageId: pageId,
            pageSize: pageSize,
            contentType: contentType);
        break;

      // make put request
      case KyteRequestType.put:
        if (field == null) {
          throw Exception('Field cannot be null for PUT request');
        }
        if (value == null) {
          throw Exception('Value cannot be null for PUT request');
        }
        if (body == null) {
          throw Exception('Data body cannot be null for PUT request');
        }
        response = await put(model, field, value, body,
            customHeaders: customHeaders,
            pageId: pageId,
            pageSize: pageSize,
            contentType: contentType);
        break;

      // make get request
      case KyteRequestType.get:
        response = await get(model,
            field: field,
            value: value,
            customHeaders: customHeaders,
            pageId: pageId,
            pageSize: pageSize,
            contentType: contentType);
        break;

      // make delete request
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
        throw Exception(
            'Unknown or unsupported HTTP request. Must be POST, PUT, GET, or DELETE');
    }

    try {
      if (response.statusCode != 200) {
        return KyteErrorResponse.fromJson(json.decode(response.body));
      }

      return fromJosn(json.decode(response.body));
    } catch (e) {
      throw Exception("Unable to parse response data. ${e.toString()}");
    }
  }

  /*
   * POST Request
   */
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

  /*
   * GET Request
   */
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

  /*
   * PUT Request
   */
  Future<dynamic> put(String model, String field, String value, String body,
      {Map<String, String>? customHeaders,
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

  /*
   * DELETE Request
   */
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
