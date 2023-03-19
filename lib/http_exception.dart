class HttpException implements Exception {
  final String message;
  final int? responseCode;

  HttpException(this.message,
      {this.responseCode}); // Pass your message in constructor.

  @override
  String toString() {
    return message;
  }
}
