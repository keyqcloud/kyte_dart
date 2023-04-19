// Copyright 2023 KeyQ, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

class KyteHttpException implements Exception {
  /// The exception message
  final String message;

  /// The exception code, used to return the response code from API (same as HTTP status code)
  final int? responseCode;

  /// Constructor that takes an exception message and an optional response code
  KyteHttpException(this.message, {this.responseCode});

  /// Override default toString method to return message.
  @override
  String toString() {
    return message;
  }
}
