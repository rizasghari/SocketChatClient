class PointResponse {
  double x;
  double y;

  PointResponse({required this.x, required this.y});

  factory PointResponse.fromJson(Map<String, dynamic> json) {
    return PointResponse(
      x: json['x'],
      y: json['y'],
    );
  }

  Map<String, dynamic> toMap() => {
    'x': x,
    'y': y,
  };
}