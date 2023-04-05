// Copyright 2023 KeyQ, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

abstract class ModelResponse {
  /// The response code returned from Kyte API, which is the same as HTTP
  /// response codes
  int? responseCode;

  /// The session token returned from the API. This value defaults to "0" when
  /// there is no active session
  String? sessionToken;

  /// The transaction token returned from the API. This value defaults to "0"
  /// when there is no active session
  String? txToken;

  ModelResponse({
    this.responseCode,
    this.sessionToken,
    this.txToken,
  });

  /// Parse the json and populate data
  ModelResponse.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    sessionToken = json['session'];
    txToken = json['token'];
  }
}
