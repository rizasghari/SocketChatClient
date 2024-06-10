class APiResponse {
  final bool success;
  final String message;
  final List<String>? errors;
  final dynamic data;

  APiResponse({
    required this.success,
    required this.message,
    required this.errors,
    required this.data,
  });

  factory APiResponse.fromJson(Map<String, dynamic> json) {
    return APiResponse(
      success: json['success'],
      message: json['message'],
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
      data: json['data'],
    );
  }
}