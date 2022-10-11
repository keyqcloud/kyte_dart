abstract class ModelResponse {
  int? responseCode;
  String? sessionToken;
  String? txToken;

  ModelResponse({
    this.responseCode,
    this.sessionToken,
    this.txToken,
  });

  ModelResponse.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    sessionToken = json['session'];
    txToken = json['token'];
  }
}
