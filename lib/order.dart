class Order {
  final String id;
  final DateTime date;
  final List<Map<String, dynamic>> products;
  final double total;
  final String status; // "En préparation", "Expédié", "Livré", etc.
  final String address;
  final String paymentMethod;

  Order({
    required this.id,
    required this.date,
    required this.products,
    required this.total,
    this.status = "En préparation",
    required this.address,
    required this.paymentMethod,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      date: DateTime.parse(json['date']),
      products: List<Map<String, dynamic>>.from(json['products']),
      total: json['total'],
      status: json['status'],
      address: json['address'],
      paymentMethod: json['paymentMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'products': products,
      'total': total,
      'status': status,
      'address': address,
      'paymentMethod': paymentMethod,
    };
  }
}