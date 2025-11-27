import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cart.dart';

class ReceiptDialog extends StatefulWidget {
  final Cart cart;

  ReceiptDialog({required this.cart});

  @override
  _ReceiptDialogState createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  final TextEditingController _paymentController = TextEditingController();
  double _change = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _paymentController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final paymentText = _paymentController.text;
    final payment = double.tryParse(paymentText) ?? 0.0;
    final total = widget.cart.totalPrice;

    setState(() {
      if (payment < total) {
        _change = 0.0;
        _errorMessage = 'Payment amount must be at least \$${total.toStringAsFixed(2)}';
      } else {
        _change = payment - total;
        _errorMessage = null;
      }
    });
  }

  bool get _isPaymentValid => _errorMessage == null && _paymentController.text.isNotEmpty;

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
            ...widget.cart.items.map((item) => Padding(
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
                Text('${widget.cart.totalItems}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('\$${widget.cart.totalPrice.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _paymentController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Payment Amount (\$)',
                border: OutlineInputBorder(),
                errorText: _errorMessage,
              ),
            ),
            SizedBox(height: 8),
            if (_isPaymentValid)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Change:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('\$${_change.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
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
          onPressed: _isPaymentValid ? () => Navigator.of(context).pop({'confirmed': true, 'payment': double.parse(_paymentController.text), 'change': _change}) : null,
          child: Text('Confirm Payment'),
        ),
      ],
    );
  }
}