import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cart.dart';

class ReceiptDialog extends StatelessWidget {
  final Cart cart;

  ReceiptDialog({required this.cart});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    return AlertDialog(
      title: Text('Transaction Receipt'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                'SMART CASHIER',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            SizedBox(height: 8),
            Center(child: Text('Point of Sale Receipt')),
            Center(child: Text('Date: ${formatter.format(now)}')),
            Divider(),
            ...cart.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name, style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('${item.quantity} x \$${item.product.price.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                  Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                ],
              ),
            )),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${cart.totalItems}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('\$${cart.totalPrice.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            SizedBox(height: 16),
            Center(child: Text('Thank you for your purchase!')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Confirm Payment'),
        ),
      ],
    );
  }
}