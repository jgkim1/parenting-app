class CartItem {
  const CartItem({
    required this.productId,
    required this.productName,
    required this.thumbnailUrl,
    required this.unitPrice,
    required this.stock,
    required this.quantity,
  });

  final String productId;
  final String productName;
  final String? thumbnailUrl;
  final int unitPrice;
  final int stock;
  final int quantity;

  int get subtotal => unitPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>;
    final images = product['images'] as List<dynamic>? ?? [];
    return CartItem(
      productId: json['productId'] as String,
      productName: product['name'] as String,
      thumbnailUrl: images.isNotEmpty ? (images.first as Map<String, dynamic>)['url'] as String? : null,
      unitPrice: product['price'] as int,
      stock: product['stock'] as int,
      quantity: json['quantity'] as int,
    );
  }
}

class Cart {
  const Cart({required this.items});

  final List<CartItem> items;

  int get totalAmount => items.fold(0, (sum, item) => sum + item.subtotal);
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>;
    return Cart(items: items.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList());
  }
}
