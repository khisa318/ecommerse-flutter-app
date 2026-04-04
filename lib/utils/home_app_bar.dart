import 'package:flutter/material.dart';
import '../providers/cart_provider.dart';
import '../utils/theme.dart';
import '../screens/cart_screen.dart';

class HomeAppBar extends StatelessWidget {
  final CartProvider cartProvider;

  const HomeAppBar({
    super.key,
    required this.cartProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppTheme.colors(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Logo/Menu Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // App Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Cyberspex",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    "Technologies",
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Notification Icon
            Container(
              width: 44,
              height: 44,
                decoration: BoxDecoration(
                  color: colors.secondarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
              child: Icon(
                Icons.notifications_outlined,
                color: colors.textPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            // Cart Icon
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              child: Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.secondarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      color: colors.textPrimary,
                      size: 22,
                    ),
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentRed,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            cartProvider.itemCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
