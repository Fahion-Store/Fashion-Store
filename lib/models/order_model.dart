import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime date;
  final String status;
  final Map<String, String> shippingDetails;
  final String paymentMethod;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.date,
    this.status = 'Processing',
    required this.shippingDetails,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'date': Timestamp.fromDate(date),
      'status': status,
      'shippingDetails': shippingDetails,
      'paymentMethod': paymentMethod,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      items: (map['items'] as List? ?? [])
          .map((item) => CartItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'Processing',
      shippingDetails: Map<String, String>.from(map['shippingDetails'] ?? {}),
      paymentMethod: map['paymentMethod'] ?? '',
    );
  }
}
