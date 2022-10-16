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

  String sessionToken = "0";
  String txToken = "0";

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

    api.sessionToken = sessionToken;
    api.txToken = txToken;

    return await api.request(fromJosn, method, model,
        body: body,
        field: field,
        value: value,
        customHeaders: customHeaders,
        pageId: pageId,
        pageSize: pageSize,
        contentType: contentType);
  }
}
