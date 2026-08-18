class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.thumbnailUrl,
    required this.quantity,
    required this.priceAtOrder,
  });

  final String productId;
  final String productName;
  final String? thumbnailUrl;
  final int quantity;
  final int priceAtOrder;

  int get subtotal => priceAtOrder * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>;
    final images = product['images'] as List<dynamic>? ?? [];
    return OrderItem(
      productId: json['productId'] as String,
      productName: product['name'] as String,
      thumbnailUrl: images.isNotEmpty ? (images.first as Map<String, dynamic>)['url'] as String? : null,
      quantity: json['quantity'] as int,
      priceAtOrder: json['priceAtOrder'] as int,
    );
  }
}

// 서버가 목록/상세 모두 동일한 형태(아이템 포함)로 내려주므로 하나의 모델을 공유한다.
class Order {
  const Order({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.shippingAddr,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String status;
  final int totalAmount;
  final String shippingAddr;
  final DateTime createdAt;
  final List<OrderItem> items;

  factory Order.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>;
    return Order(
      id: json['id'] as String,
      status: json['status'] as String,
      totalAmount: json['totalAmount'] as int,
      shippingAddr: json['shippingAddr'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: items.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class OrderPage {
  const OrderPage({required this.items, required this.page, required this.totalPages});

  final List<Order> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory OrderPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>;
    return OrderPage(
      items: items.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList(),
      page: json['page'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}

String orderStatusLabel(String status) {
  switch (status) {
    case 'PENDING_PAYMENT':
      return '결제 대기';
    case 'PAID':
      return '결제 완료';
    case 'PREPARING':
      return '상품 준비중';
    case 'SHIPPED':
      return '배송중';
    case 'DELIVERED':
      return '배송 완료';
    case 'CANCELLED':
      return '주문 취소';
    default:
      return status;
  }
}
