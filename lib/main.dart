import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cyberspex_ecommerce/screens/home_screen.dart';
import 'package:cyberspex_ecommerce/screens/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/product.dart' as product_model;
import 'data/datasources/remote_datasource.dart';
import 'data/repositories/repositories_impl.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/checkout_provider.dart';
import 'providers/product_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/theme_provider.dart';
import 'data/repositories/sync_repository.dart';
import 'screens/address_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/customer_service_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/payment_status_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reviews_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/wishlist_screen.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    print('🔷 Supabase Initialization Starting...');
    print('🔷 Supabase URL: https://xjmgfmkhtzdybbgkintb.supabase.co');
    print('🔷 Supabase Project ID: xjmgfmkhtzdybbgkintb');

    await Supabase.initialize(
      url: 'https://xjmgfmkhtzdybbgkintb.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhqbWdmbWtodHpkeWJiZ2tpbnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyNDA4MTEsImV4cCI6MjA4OTgxNjgxMX0.JyTeXuXL09foDNqvNL5bDAbVEz5kV0IPvTOPodGrWUU',
    );
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('🔴 Supabase initialization error: $e');
    print('🔴 This is usually a network issue or invalid credentials');
    rethrow;
  }

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(CyberspexApp(sharedPreferences: sharedPreferences));
}

class CyberspexApp extends StatefulWidget {
  final SharedPreferences sharedPreferences;

  const CyberspexApp({
    required this.sharedPreferences,
    super.key,
  });

  @override
  State<CyberspexApp> createState() => _CyberspexAppState();
}

class _CyberspexAppState extends State<CyberspexApp> {
  late final RemoteDataSource _remoteDataSource;
  late final AuthProvider _authProvider;
  late final ProductProvider _productProvider;
  late final CartProvider _cartProvider;
  late final CheckoutProvider _checkoutProvider;
  late final WishlistProvider _wishlistProvider;
  late final SyncRepository _syncRepository;
  late final ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _remoteDataSource = RemoteDataSource(
      supabaseClient: Supabase.instance.client,
    );
    _authProvider = AuthProvider(
      remoteDataSource: _remoteDataSource,
    );
    _productProvider = ProductProvider(
      productRepository: ProductRepositoryImpl(
        remoteDataSource: _remoteDataSource,
        sharedPreferences: widget.sharedPreferences,
      ),
      categoryRepository: CategoryRepositoryImpl(
        remoteDataSource: _remoteDataSource,
        sharedPreferences: widget.sharedPreferences,
      ),
    );
    _cartProvider = CartProvider(
      remoteDataSource: _remoteDataSource,
    );
    _checkoutProvider = CheckoutProvider(
      remoteDataSource: _remoteDataSource,
    );
    _wishlistProvider = WishlistProvider(
      remoteDataSource: _remoteDataSource,
    );
    _themeProvider = ThemeProvider(
      sharedPreferences: widget.sharedPreferences,
    );
    _syncRepository = SyncRepository(
      supabaseClient: Supabase.instance.client,
      sharedPreferences: widget.sharedPreferences,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Data layer repositories
        Provider<RemoteDataSource>.value(value: _remoteDataSource),

        // Auth Provider
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),

        // Product Provider
        ChangeNotifierProvider<ProductProvider>.value(value: _productProvider),

        // Cart Provider (local state only)
        ChangeNotifierProvider<CartProvider>.value(value: _cartProvider),

        ChangeNotifierProvider<CheckoutProvider>.value(
          value: _checkoutProvider,
        ),

        ChangeNotifierProvider<WishlistProvider>.value(
            value: _wishlistProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),

        ChangeNotifierProxyProvider<AuthProvider, SyncProvider>(
          create: (context) => SyncProvider(
            syncRepository: _syncRepository,
            userId: _authProvider.currentUserId,
          ),
          update: (context, auth, previous) => SyncProvider(
            syncRepository: _syncRepository,
            userId: auth.currentUserId,
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Cyberspex Technologies',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          themeAnimationCurve: Curves.easeInOut,
          themeAnimationDuration: const Duration(milliseconds: 220),
          home: const SplashScreen(),
          onGenerateRoute: _generateRoute,
          routes: {
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/verify-email': (context) => const VerifyEmailScreen(),
            '/home': (context) => const HomeScreen(),
            '/shop': (context) => const ShopScreen(),
            '/wishlist': (context) => const WishlistScreen(),
            '/cart': (context) => const CartScreen(),
            '/checkout': (context) => const CheckoutScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/inbox': (context) => const InboxScreen(),
            '/customer-service': (context) => const CustomerServiceScreen(),
            '/reviews': (context) => const ReviewsScreen(),
            '/orders': (context) => const OrderHistoryScreen(),
            '/addresses': (context) => const AddressScreen(),
          },
        ),
      ),
    );
  }

  // Dynamic route handler for passing parameters (e.g., product details)
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/main':
        final args = settings.arguments;
        final initialIndex = args is int ? args : 0;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MainScreen(initialIndex: initialIndex),
        );
      case '/product-detail':
        final args = settings.arguments;
        if (args is product_model.Product) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ProductDetailScreen(product: args),
          );
        }
        return null;
      case '/payment-status':
        final args = settings.arguments;
        if (args is PaymentStatusScreenArgs) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => PaymentStatusScreen(args: args),
          );
        }
        return null;
      default:
        return null;
    }
  }
}
