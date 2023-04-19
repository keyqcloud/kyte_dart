// Copyright 2023 KeyQ, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'model_response.dart';

class KyteErrorResponse extends ModelResponse {
  /// The error message returned from API if the response code was other than 200
  String? message;

  KyteErrorResponse({this.message});

  /// Parse the json and populate data
  KyteErrorResponse.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    message = json['error'];
  }
}
