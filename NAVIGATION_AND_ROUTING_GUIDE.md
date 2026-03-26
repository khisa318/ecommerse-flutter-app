# CyberSpex Navigation & Routing Guide

## Overview

This document outlines the complete navigation and routing structure for the CyberSpex e-commerce Flutter application. The app uses a combination of named routes and dynamic route generation to manage screen transitions efficiently.

---

## 1. App Navigation Structure

### 1.1 Entry Point: SplashScreen

```
SplashScreen
    ↓
    ├─ Check Auth State ─→ isLoggedIn = true → MainScreen (/main)
    │                                       ↓
    │                              Home / Shop / Wishlist / Cart / Messages / Profile
    │
    └─ isLoggedIn = false → LoginScreen (/login)
                                ↓
                               (Login or Signup Process)
                                ↓
                          Successfully Login → MainScreen (/main)
```

### 1.2 Main Navigation Hierarchy

```
Root
├── SplashScreen (Initial route)
│
├── Authentication Routes
│   ├── /login → LoginScreen
│   └── /signup → SignupScreen
│
├── Main Navigation (Bottom Tab Bar)
│   └── /main → MainScreen [Parent Container]
│       ├── [Tab 0] HomeScreen (/home)
│       ├── [Tab 1] ShopScreen (/shop)
│       ├── [Tab 2] WishlistScreen (/wishlist)
│       ├── [Tab 3] CartScreen (/cart)
│       ├── [Tab 4] ChatScreen (/messages)
│       └── [Tab 5] ProfileScreen (/profile)
│
├── Secondary Routes (Stack on top of MainScreen)
│   ├── /product-detail → ProductDetailScreen [Dynamic Route - passes product object]
│   ├── /orders → OrderHistoryScreen
│   └── /addresses → AddressScreen
│
└── Utility Routes
    └── /checkout → CheckoutScreen (Future implementation)
```

---

## 2. Named Routes Reference

| Route | Screen | Type | Purpose |
|-------|--------|------|---------|
| `/` | SplashScreen | Initial | Auth check & initialization |
| `/login` | LoginScreen | Auth | User login |
| `/signup` | SignupScreen | Auth | New user registration |
| `/main` | MainScreen | Main | Tab-based navigation hub |
| `/home` | HomeScreen | Tab | Home/Dashboard with featured products |
| `/shop` | ShopScreen | Tab | Browse all products by category |
| `/wishlist` | WishlistScreen | Tab | Saved favorite products |
| `/cart` | CartScreen | Tab | Shopping cart management |
| `/messages` | ChatScreen | Tab | Messages & customer support |
| `/profile` | ProfileScreen | Tab | User account & settings |
| `/product-detail` | ProductDetailScreen | Dynamic | Product details (passes Product object) |
| `/orders` | OrderHistoryScreen | Secondary | View past orders |
| `/addresses` | AddressScreen | Secondary | Manage delivery addresses |

---

## 3. Route Implementation Details

### 3.1 Static Named Routes (main.dart)

```dart
routes: {
  // Main navigation
  '/main': (context) => const MainScreen(),
  '/home': (context) => const HomeScreen(),
  
  // Authentication routes
  '/login': (context) => const LoginScreen(),
  '/signup': (context) => const SignupScreen(),
  
  // Core feature routes
  '/shop': (context) => const ShopScreen(),
  '/wishlist': (context) => const WishlistScreen(),
  '/cart': (context) => const CartScreen(),
  '/profile': (context) => const ProfileScreen(),
  '/messages': (context) => const ChatScreen(),
  
  // User management routes
  '/orders': (context) => const OrderHistoryScreen(),
  '/addresses': (context) => const AddressScreen(),
}
```

### 3.2 Dynamic Routes (onGenerateRoute)

```dart
Route<dynamic>? _generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/product-detail':
      final product = settings.arguments;
      if (product != null) {
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        );
      }
      return null;
    default:
      return null;
  }
}
```

---

## 4. Navigation Patterns

### 4.1 Navigating Between Bottom Tab Screens

**Location:** MainScreen uses IndexedStack with BottomNavigationBar

```dart
// Automatic - tapping bottom nav bar updates _currentIndex
onTap: (index) => setState(() => _currentIndex = index)

// All tab screens are kept in memory (IndexedStack)
// No route navigation needed for tab switching
```

### 4.2 Named Route Navigation

**Pattern:** Using `Navigator.pushNamed()`

```dart
// Navigate to login
Navigator.pushNamed(context, '/login');

// Navigate to order history
Navigator.pushNamed(context, '/orders');

// Navigate to addresses
Navigator.pushNamed(context, '/addresses');
```

### 4.3 Dynamic Route Navigation (Product Details)

**Pattern:** Using `Navigator.pushNamed()` with arguments

```dart
// From ProductCard or anywhere else
Navigator.pushNamed(
  context,
  '/product-detail',
  arguments: product,  // Pass Product object
);

// In ProductDetailScreen
ProductDetailScreen(product: product)
```

### 4.4 Authentication Redirect

**Location:** SplashScreen (_checkAuthState)

```dart
final authProvider = context.read<AuthProvider>();

if (authProvider.isLoggedIn) {
  Navigator.of(context).pushReplacementNamed('/main');
} else {
  Navigator.of(context).pushReplacementNamed('/login');
}
```

### 4.5 Post-Login Navigation

**Location:** LoginScreen (after successful login)

```dart
await context.read<AuthProvider>().login(email, password);
if (mounted) {
  // Update AuthProvider state, then navigate
  Navigator.of(context).pushReplacementNamed('/main');
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Login successful')),
  );
}
```

---

## 5. Screen-Specific Navigation Guide

### 5.1 HomeScreen
- **Entry:** Via MainScreen Tab [0]
- **Navigates To:**
  - `/product-detail` (tap product card)
  - `/shop` (tap view all category)
  - `/messages` (customer support link)
  - `/login` (if not authenticated)

### 5.2 ShopScreen
- **Entry:** Via MainScreen Tab [1]
- **Navigates To:**
  - `/product-detail` (tap product card)
  - `/cart` (add to cart → view cart)
  - `/login` (if not authenticated)

### 5.3 WishlistScreen
- **Entry:** Via MainScreen Tab [2]
- **Navigates To:**
  - `/product-detail` (tap wishlist item)
  - `/cart` (move to cart)
  - `/login` (if not authenticated)

### 5.4 CartScreen
- **Entry:** Via MainScreen Tab [3]
- **Navigates To:**
  - `/product-detail` (tap product)
  - `/addresses` (during checkout)
  - `/checkout` (future: proceed to payment)

### 5.5 ChatScreen
- **Entry:** Via MainScreen Tab [4]
- **Navigates To:**
  - `/login` (if not authenticated)

### 5.6 ProfileScreen
- **Entry:** Via MainScreen Tab [5]
- **Navigates To:**
  - `/login` (if not authenticated)
  - `/addresses` (manage addresses)
  - `/orders` (view order history)

### 5.7 LoginScreen
- **Entry:** From SplashScreen or ProfileScreen
- **Navigates To:**
  - `/signup` (create account link)
  - `/main` (after successful login)

### 5.8 SignupScreen
- **Entry:** From LoginScreen
- **Navigates To:**
  - `/login` (already have account)
  - `/main` (after successful signup)

### 5.9 ProductDetailScreen
- **Entry:** From HomeScreen, ShopScreen, WishlistScreen (dynamic route)
- **Navigates To:**
  - `/cart` (after add to cart)
  - Back button → Previous screen

### 5.10 OrderHistoryScreen
- **Entry:** From ProfileScreen
- **Navigates To:**
  - `/product-detail` (tap order item)

### 5.11 AddressScreen
- **Entry:** From ProfileScreen or CartScreen
- **Navigates To:**
  - Back button → Previous screen

---

## 6. State Management with Navigation

### 6.1 AuthProvider Integration

```dart
// Check auth state before showing certain screens
final authProvider = context.watch<AuthProvider>();

if (!authProvider.isLoggedIn) {
  return Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/login'),
        child: const Text('Login'),
      ),
    ),
  );
}
```

### 6.2 CartProvider Integration

```dart
// After adding to cart, optionally navigate
final cartProvider = context.read<CartProvider>();
cartProvider.addItem(product);

// Option 1: Show snackbar with action
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Added to cart'),
    action: SnackBarAction(
      label: 'View',
      onPressed: () => Navigator.pushNamed(context, '/cart'),
    ),
  ),
);

// Option 2: Navigate directly
Navigator.pushNamed(context, '/cart');
```

---

## 7. Back Navigation Behavior

### 7.1 Bottom Tab Screens (MainScreen)
- **Behavior:** No back button (IndexedStack keeps state)
- **Physical back:** Exits app (handled by Android)
- **Code:** Use `Navigator.pop()` to pop any overlaid routes

### 7.2 Named Route Screens (Outside MainScreen)
- **Behavior:** Standard back button appears in AppBar
- **Action:** `Navigator.pop(context)` or system back
- **Example:**
  ```dart
  AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.pop(context),
    ),
  )
  ```

### 7.3 auth Flows
- **LoginScreen → SplashScreen:** Use `pushReplacementNamed()` to replace splash
- **SignupScreen → MainScreen:** Use `pushReplacementNamed()` to prevent back navigation to signup

---

## 8. Dialog & Bottom Sheet Navigation

### 8.1 Dialogs (Stay on same route)
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(...),
);
// User dismisses dialog → returns to current screen
```

### 8.2 Bottom Sheets (Stack on current route)
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => Container(...),
);
// User swipes down → returns to current screen
```

---

## 9. Deep Linking Support (Future)

**Potential deep link routes:**
```
cyberspex://home
cyberspex://product/123
cyberspex://orders
cyberspex://cart
```

**Implementation:**
```dart
// onGenerateRoute can be extended to parse deep links
Route<dynamic>? _generateRoute(RouteSettings settings) {
  final Uri deepLink = Uri.parse(settings.name ?? '');
  
  if (deepLink.pathSegments.contains('product')) {
    final productId = deepLink.queryParameters['id'];
    // Fetch product and navigate
  }
}
```

---

## 10. Navigation Troubleshooting

### Issue: "Route does not exist"
**Solution:** Check route name spelling in `routes` map or `_generateRoute`

### Issue: Screen doesn't rebuild after navigation
**Solution:** Use `Navigator.pop()` + `Navigator.pushNamed()` instead of `Replace`

### Issue: Back button doesn't work
**Solution:** Ensure `automaticallyImplyLeading` is not set to false, or provide custom leading button

### Issue: Lost state when navigating
**Solution:** Use Provider or other state management to persist data across routes

### Issue: Multiple instances of same screen
**Solution:** Use `pushReplacementNamed()` instead of `pushNamed()` for auth flows

---

## 11. Navigation Best Practices

✓ **Do:**
- Use named routes for static screens (consistent, maintainable)
- Use dynamic routes for data-driven screens (ProductDetailScreen)
- Use `pushReplacementNamed()` for auth flows (prevent back navigation)
- Keep navigation logic in providers (AuthProvider, etc.)
- Use IndexedStack for bottom tab navigation (maintains state)
- Pass complex objects via `arguments` parameter

✗ **Don't:**
- Don't mix named routes with direct MaterialPageRoute creation
- Don't navigate from BuildContext after widget is disposed
- Don't create new provider instances in navigation callbacks
- Don't use hardcoded string route names multiple times
- Don't overuse `pushReplacementNamed()` (breaks back navigation)
- Don't navigate in `build()` method (causes infinite loops)

---

## 12. Implementation Checklist

- [x] SplashScreen created for auth initialization
- [x] MainScreen uses IndexedStack for tab navigation
- [x] ProductDetailScreen uses dynamic route with arguments
- [x] ChatScreen included in bottom navigation
- [x] All named routes defined in main.dart routes map
- [x] onGenerateRoute implemented for dynamic routes
- [x] CartScreen removed unnecessary back navigation
- [x] ProductCard uses named route for product detail
- [ ] LoginScreen properly redirects after login
- [ ] ProfileScreen shows login prompt when not authenticated
- [ ] DeepLinking integration (future)
- [ ] Analytics event tracking on route changes (future)
- [ ] Route name constants file (optional but recommended)

---

## 13. Suggested Improvements (Future)

### 13.1 Create Route Constants File
```dart
// lib/utils/route_constants.dart
class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String main = '/main';
  static const String home = '/home';
  static const String shop = '/shop';
  static const String productDetail = '/product-detail';
  // ... etc
}

// Usage
Navigator.pushNamed(context, Routes.productDetail, arguments: product);
```

### 13.2 Custom Navigation Observer (for analytics)
```dart
class NavigationObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Log route change
    print('Route pushed: ${route.settings.name}');
  }
}

// Add to MaterialApp
navigatorObservers: [NavigationObserver()],
```

### 13.3 Explicit Route Guards
```dart
class AuthGuard {
  static Future<bool> checkAuth(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return false;
    }
    return true;
  }
}

// Usage in screen
if (await AuthGuard.checkAuth(context)) {
  // Proceed with protected action
}
```

---

## Document Version
- **Version:** 1.0
- **Last Updated:** March 22, 2026
- **Status:** Implementation Complete - Navigation Structure Finalized
