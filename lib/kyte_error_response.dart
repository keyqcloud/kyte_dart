import 'model_response.dart';

class KyteErrorResponse extends ModelResponse {
  String? message;

  KyteErrorResponse({this.message});

  KyteErrorResponse.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    message = json['error'];
  }
}
