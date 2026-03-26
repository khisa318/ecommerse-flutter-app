import 'package:flutter/foundation.dart';
import '../data/datasources/remote_datasource.dart';
import '../models/cart_item.dart';

class MpesaCheckoutResult {
  final int orderId;
  final String? checkoutRequestId;
  final String? customerMessage;
  final String? paymentStatus;
  final String? errorMessage;

  const MpesaCheckoutResult({
    required this.orderId,
    this.checkoutRequestId,
    this.customerMessage,
    this.paymentStatus,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}

class CheckoutProvider with ChangeNotifier {
  final RemoteDataSource remoteDataSource;

  CheckoutProvider({required this.remoteDataSource});

  bool _isProcessing = false;
  String? _errorMessage;
  int? _lastOrderId;
  String? _lastCheckoutRequestId;
  String? _lastCustomerMessage;
  String? _lastPaymentStatus;

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  int? get lastOrderId => _lastOrderId;
  String? get lastCheckoutRequestId => _lastCheckoutRequestId;
  String? get lastCustomerMessage => _lastCustomerMessage;
  String? get lastPaymentStatus => _lastPaymentStatus;

  Future<MpesaCheckoutResult> initiatePayment({
    required String userId,
    required String phoneNumber,
    required double totalAmount,
    required List<CartItem> items,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (remoteDataSource.supabaseClient.auth.currentUser == null) {
        throw Exception('Please log in before starting M-Pesa checkout');
      }

      final normalizedPhone = _normalizeKenyanPhone(phoneNumber);
      final roundedAmount = totalAmount.round();

      final orderId = await remoteDataSource.createOrder(
        userId: userId,
        totalPrice: roundedAmount,
        items: items
            .map(
              (item) => {
                'product_id': int.parse(item.product.id),
                'quantity': item.quantity,
                'price_at_purchase': item.product.price.round(),
              },
            )
            .toList(),
      );

      final response = await remoteDataSource.initiateMpesaStkPush(
        orderId: orderId,
        phoneNumber: normalizedPhone,
        amount: roundedAmount,
      );

      _lastOrderId = orderId;
      _lastCheckoutRequestId = response['checkout_request_id']?.toString() ??
          response['CheckoutRequestID']?.toString();
      _lastCustomerMessage = response['customer_message']?.toString() ??
          response['CustomerMessage']?.toString();
      _lastPaymentStatus = response['payment_status']?.toString() ??
          response['status']?.toString();
      _isProcessing = false;
      notifyListeners();
      return MpesaCheckoutResult(
        orderId: orderId,
        checkoutRequestId: _lastCheckoutRequestId,
        customerMessage: _lastCustomerMessage,
        paymentStatus: _lastPaymentStatus,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isProcessing = false;
      notifyListeners();
      return MpesaCheckoutResult(
        orderId: -1,
        errorMessage: _errorMessage,
      );
    }
  }

  Future<String?> refreshPaymentStatus() async {
    final orderId = _lastOrderId;
    if (orderId == null) {
      throw Exception('No M-Pesa order available to check');
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await remoteDataSource.getMpesaPaymentStatus(
        orderId: orderId,
      );

      final payment = response['payment'];
      if (payment is Map) {
        final paymentMap = Map<String, dynamic>.from(payment);
        _lastPaymentStatus = paymentMap['status']?.toString();
        _lastCustomerMessage = paymentMap['customer_message']?.toString() ??
            paymentMap['result_desc']?.toString() ??
            _lastCustomerMessage;
        _lastCheckoutRequestId =
            paymentMap['checkout_request_id']?.toString() ??
                _lastCheckoutRequestId;
      } else {
        _lastPaymentStatus = response['payment_status']?.toString() ??
            response['status']?.toString();
      }

      _isProcessing = false;
      notifyListeners();
      return _lastPaymentStatus;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }
  }

  String _normalizeKenyanPhone(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.startsWith('254') && digitsOnly.length == 12) {
      return digitsOnly;
    }

    if (digitsOnly.startsWith('0') && digitsOnly.length == 10) {
      return '254${digitsOnly.substring(1)}';
    }

    if (digitsOnly.length == 9) {
      return '254$digitsOnly';
    }

    throw Exception('Enter a valid Kenyan M-Pesa number');
  }
}
