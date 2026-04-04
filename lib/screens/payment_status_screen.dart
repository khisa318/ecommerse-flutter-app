import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datasources/remote_datasource.dart';
import '../providers/cart_provider.dart';
import '../utils/currency.dart';
import '../utils/theme.dart';

class PaymentStatusScreenArgs {
  final int orderId;
  final String? checkoutRequestId;
  final String? customerMessage;
  final String? initialStatus;

  const PaymentStatusScreenArgs({
    required this.orderId,
    this.checkoutRequestId,
    this.customerMessage,
    this.initialStatus,
  });
}

class PaymentStatusScreen extends StatefulWidget {
  final PaymentStatusScreenArgs args;

  const PaymentStatusScreen({
    required this.args,
    super.key,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  StreamSubscription<List<Map<String, dynamic>>>? _paymentSubscription;
  Timer? _pollingTimer;
  bool _isLoading = true;
  bool _hasHandledCompletion = false;
  String? _errorMessage;
  String _paymentStatus = 'pending';
  String? _customerMessage;
  String? _receiptNumber;
  String? _phoneNumber;
  int? _amount;

  @override
  void initState() {
    super.initState();
    _paymentStatus = widget.args.initialStatus ?? 'pending';
    _customerMessage = widget.args.customerMessage;
    _subscribeToRealtime();
    _startPollingFallback();
  }

  void _subscribeToRealtime() {
    final remoteDataSource = context.read<RemoteDataSource>();
    _paymentSubscription =
        remoteDataSource.watchPaymentsForOrder(widget.args.orderId).listen(
      (data) async {
        if (!mounted || data.isEmpty) {
          return;
        }

        final latestPayment = data.first;
        await _applyPaymentUpdate(latestPayment);
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
        });
      },
    );
  }

  void _startPollingFallback() {
    _fetchLatestPayment();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _fetchLatestPayment(),
    );
  }

  Future<void> _fetchLatestPayment() async {
    if (!mounted || _hasTerminalStatus) {
      _stopTracking();
      return;
    }

    try {
      final remoteDataSource = context.read<RemoteDataSource>();
      final paymentData =
          await remoteDataSource.getLatestPaymentForOrder(widget.args.orderId);

      if (!mounted || paymentData == null) {
        return;
      }

      await _applyPaymentUpdate(paymentData);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _applyPaymentUpdate(Map<String, dynamic> paymentData) async {
    if (!mounted) {
      return;
    }

    final nextStatus =
        paymentData['status']?.toString().toLowerCase() ?? _paymentStatus;
    final nextMessage = paymentData['customer_message']?.toString() ??
        paymentData['result_desc']?.toString() ??
        _customerMessage;

    setState(() {
      _paymentStatus = nextStatus;
      _customerMessage = nextMessage;
      _receiptNumber = paymentData['mpesa_receipt_number']?.toString();
      _phoneNumber = paymentData['phone_number']?.toString();
      _amount = paymentData['amount'] is num
          ? (paymentData['amount'] as num).round()
          : _amount;
      _errorMessage = null;
      _isLoading = false;
    });

    if (_hasTerminalStatus) {
      _stopTracking();
      await _handleTerminalStatus();
    }
  }

  bool get _hasTerminalStatus =>
      _paymentStatus == 'paid' ||
      _paymentStatus == 'failed' ||
      _paymentStatus == 'cancelled';

  Future<void> _handleTerminalStatus() async {
    if (_hasHandledCompletion || !mounted) {
      return;
    }

    _hasHandledCompletion = true;

    if (_paymentStatus == 'paid') {
      context.read<CartProvider>().clearCart();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _paymentStatus == 'paid'
                ? 'Payment confirmed successfully'
                : 'Payment did not complete successfully',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _statusColor,
        ),
      );
    });
  }

  void _stopTracking() {
    _paymentSubscription?.cancel();
    _paymentSubscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Payment Status'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading && !_hasTerminalStatus
                        ? const Padding(
                            padding: EdgeInsets.all(28),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : Icon(
                            _statusIcon,
                            color: _statusColor,
                            size: 52,
                          ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _statusTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailsCard(),
                  const SizedBox(height: 20),
                  if (!_hasTerminalStatus)
                    TextButton.icon(
                      onPressed: _fetchLatestPayment,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh now'),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/main',
                          (route) => false,
                        );
                      },
                      child:
                          Text(_hasTerminalStatus ? 'Back to Shop' : 'Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _detailRow('Order', '#${widget.args.orderId}'),
          if (widget.args.checkoutRequestId != null)
            _detailRow('Request ID', widget.args.checkoutRequestId!),
          _detailRow('Status', _paymentStatus.toUpperCase()),
          if (_amount != null)
            _detailRow('Amount', formatKsh(_amount!.toDouble())),
          if (_phoneNumber != null) _detailRow('Phone', _phoneNumber!),
          if (_receiptNumber != null) _detailRow('Receipt', _receiptNumber!),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppTheme.accentRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _statusIcon {
    switch (_paymentStatus) {
      case 'paid':
        return Icons.check_circle_outline;
      case 'failed':
      case 'cancelled':
        return Icons.error_outline;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Color get _statusColor {
    switch (_paymentStatus) {
      case 'paid':
        return AppTheme.accentGreen;
      case 'failed':
      case 'cancelled':
        return AppTheme.accentRed;
      default:
        return AppTheme.primaryColor;
    }
  }

  String get _statusTitle {
    switch (_paymentStatus) {
      case 'paid':
        return 'Payment Successful';
      case 'failed':
        return 'Payment Failed';
      case 'cancelled':
        return 'Payment Cancelled';
      default:
        return 'Waiting for payment...';
    }
  }

  String get _statusMessage {
    if (_errorMessage != null && !_hasTerminalStatus) {
      return 'We could not refresh the payment right now. You can try again in a moment.';
    }

    switch (_paymentStatus) {
      case 'paid':
        return _customerMessage ??
            'Your M-Pesa payment has been received. Your order is now confirmed.';
      case 'failed':
        return _customerMessage ??
            'The payment request did not complete. You can go back and try again.';
      case 'cancelled':
        return _customerMessage ??
            'The payment was cancelled before completion.';
      default:
        return _customerMessage ??
            'Complete the prompt on your phone. We will keep checking automatically.';
    }
  }
}
