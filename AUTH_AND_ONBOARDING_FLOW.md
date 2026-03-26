# CyberSpex Authentication & Onboarding Flow

## Overview

The CyberSpex application now follows a **guest-first, auth-on-demand** model:

1. **First-Time Users** → Onboarding Screens → Browse App (No Login)
2. **Returning Users** → Skip Onboarding → Browse App (No Login)
3. **Profile/Checkout Access** → Login Required (On-Demand)

This approach maximizes user engagement by allowing browsing without authentication friction.

---

## Authentication Flow Architecture

### New App Flow Diagram

```
App Launch
    ↓
SplashScreen (2 sec animation)
    ↓
Check: "hasSeenOnboarding" in SharedPreferences
    ↓
    ├─ FALSE (First Time) → OnboardingScreen
    │   ├─ Swipe through 4 screens
    │   ├─ Click "Skip" OR "Get Started"
    │   ├─ Mark onboarding as complete in SharedPreferences
    │   │   (sets hasSeenOnboarding = true)
    │   └─ Navigate to MainScreen
    │
    └─ TRUE (Returning) → MainScreen (Direct)
         ↓
         Home / Shop / Wishlist / Cart / Messages / Profile
         
When User Taps Profile → Check isLoggedIn
    ├─ YES → Show Profile Screen
    └─ NO → Show Login Prompt
         ├─ Login → Profile Screen
         └─ Sign Up → Create Account → Profile Screen
```

---

## Key Components

### 1. SplashScreen (`lib/screens/splash_screen.dart`)

**Purpose:** Initial app state detection and routing

```dart
void _checkAppState() async {
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  await Future.delayed(const Duration(seconds: 2));

  if (!hasSeenOnboarding) {
    // First time → show onboarding
    Navigator.of(context).pushReplacementNamed('/onboarding');
  } else {
    // Returning user → go to home
    Navigator.of(context).pushReplacementNamed('/main');
  }
}
```

**Features:**
- Animated splash UI with fade & scale animations
- 2-second delay for professional appearance
- Checks `SharedPreferences` for onboarding status
- Uses `pushReplacementNamed()` to prevent back navigation

### 2. OnboardingScreen (`lib/screens/onboarding_screen.dart`)

**Purpose:** Introduce app features to first-time users

**4 Onboarding Screens:**
1. **Welcome** - Shop premium electronics
2. **Fast Delivery** - Reliable logistics
3. **Secure & Trusted** - Buyer protection
4. **Customer Support** - 24/7 help

**Features:**
- PageView with smooth transitions
- Dot indicators for progress
- Back/Next navigation
- Skip button (available on all screens)
- Get Started button (on last screen)

**Important:** When user completes onboarding (clicks Skip or Get Started):

```dart
Future<void> _markOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('hasSeenOnboarding', true);  // ← Marks as complete
}

void _skipOnboarding() async {
  await _markOnboardingComplete();
  Navigator.of(context).pushReplacementNamed('/main');
}
```

### 3. MainScreen with Protected Features

**Browse Without Auth:**
- ✅ Home Screen
- ✅ Shop Screen (Browse & Filter)
- ✅ Wishlist Screen (Local storage)
- ✅ Cart Screen (Add items locally)
- ✅ Messages Screen (View support chat)

**Auth Required:**
- 🔒 Profile Screen
- 🔒 View Full Profile Details
- 🔒 Order History (future)
- 🔒 Saved Addresses (future)
- 🔒 Checkout (future)

### 4. ProfileScreen Auth Gate

**When User NOT Logged In:**

```dart
if (!authProvider.isLoggedIn) {
  return Scaffold(
    body: Center(
      child: Column(
        children: [
          Icon(Icons.account_circle, size: 100),
          Text('Please login to view your profile'),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: Text('Login'),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/signup'),
            child: Text('Create Account'),
          ),
        ],
      ),
    ),
  );
}
```

**When User Logged In:**
- Show full profile with user data
- Display order history
- Manage addresses
- Account settings

---

## Routes Reference

| Route | Screen | Auth Required | Purpose |
|-------|--------|---------------|---------|
| `/` (home) | SplashScreen | N/A | App entry point |
| `/onboarding` | OnboardingScreen | No | First-time intro |
| `/main` | MainScreen | No | Main app container |
| `/home` | HomeScreen | No | Home/Featured products |
| `/shop` | ShopScreen | No | Browse products |
| `/wishlist` | WishlistScreen | No | Saved favorites (local) |
| `/cart` | CartScreen | No | Shopping cart (local) |
| `/messages` | ChatScreen | No | Support messages |
| `/profile` | ProfileScreen | **YES** | User profile (shows login if not auth'd) |
| `/orders` | OrderHistoryScreen | **YES** | Order history |
| `/addresses` | AddressScreen | **YES** | Manage delivery addresses |
| `/login` | LoginScreen | No | User login |
| `/signup` | SignupScreen | No | Create account |
| `/product-detail` | ProductDetailScreen | No | Product details |

---

## Data Persistence

### SharedPreferences Usage

```dart
// Mark onboarding as completed
await prefs.setBool('hasSeenOnboarding', true);
await prefs.getBool('hasSeenOnboarding'); // Returns true on next app launch
```

### Local Storage (Non-Auth Features)

```dart
// Cart items stored locally (per device)
cartProvider.addItem(product);

// Wishlist stored locally (per device)  
wishlistProvider.addItem(product);

// These sync to backend ONLY after user logs in and purchases
```

---

## Login Flow (When User Accesses Profile)

```
User Taps Profile Tab
    ↓
ProfileScreen checks: authProvider.isLoggedIn?
    ├─ YES → Show Profile (continue reading below)
    └─ NO → Show Login Screen
         ↓
    User enters email + password
         ↓
    Click "Login" Button
         ↓
    AuthProvider.login() called
         ↓
    AuthProvider emits logged-in state
         ↓
    ProfileScreen rebuilds (via context.watch<AuthProvider>)
         ↓
    Show Profile Data
```

### LoginScreen Navigation After Success

```dart
Future<void> _login() async {
  await context.read<AuthProvider>().login(email, password);
  if (mounted) {
    Navigator.of(context).pop();  // ← Go back to ProfileScreen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login successful')),
    );
  }
}
```

**Key Point:** `Navigator.pop()` returns user to the ProfileScreen (where they came from)

---

## Sign Up Flow

1. User clicks "Create Account" on Profile Screen
2. SignupScreen appears
3. User fills in details (name, email, password)
4. Clicks "Sign Up"
5. AuthProvider creates new user
6. User automatically logged in
7. `Navigator.pop()` returns to ProfileScreen
8. ProfileScreen shows profile data

---

## User Experience Journey

### Scenario 1: First-Time User (No Account)

```
Day 1:
  1. Download app
  2. See splash screen (2 sec)
  3. See onboarding screens (can skip)
  4. Land on home page (products visible)
  5. Browse products, add to cart
  6. Try to view profile → Login prompt
  7. Decide not to login, continue browsing
  
Day 2:
  1. Open app
  2. No onboarding (already seen)
  3. Directly to home page
  4. Continue browsing
  
Day 3:
  1. Ready to buy
  2. Click profile
  3. Create account/login
  4. Complete profile
  5. Proceed to checkout
```

### Scenario 2: Returning User (Has Account)

```
Day 1:
  1. Open app
  2. No onboarding (already seen) 
  3. Directly to home page
  4. Browse products
  5. Click profile → Already logged in
  6. See profile data
  7. Can manage orders, addresses, etc.
```

---

## Technical Implementation Details

### 1. Onboarding Tracking

**File:** `lib/screens/splash_screen.dart`

Uses SharedPreferences to track onboarding completion:
- Key: `'hasSeenOnboarding'`
- Type: Boolean
- Default: false (first-time users)
- Set to true: When onboarding completes

```dart
SharedPreferences prefs = await SharedPreferences.getInstance();
bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
```

### 2. Auth State Management

**File:** `lib/providers/auth_provider.dart`

```dart
class AuthProvider with ChangeNotifier {
  User? _currentUser;
  
  bool get isLoggedIn => _currentUser != null;
  
  Future<void> login(String email, String password) async {
    // Validate credentials
    // Update _currentUser
    // notifyListeners()
  }
  
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
```

### 3. Protected Screen Pattern

**Example: ProfileScreen**

```dart
Widget build(BuildContext context) {
  final authProvider = context.watch<AuthProvider>();

  // Gate: Check authentication
  if (!authProvider.isLoggedIn) {
    return UnauthenticatedView();  // Shows login prompt
  }

  // Authenticated view
  return AuthenticatedProfileView(user: authProvider.currentUser);
}
```

---

## Best Practices

✅ **Do:**
- Track onboarding with SharedPreferences
- Show auth gate only for account-specific features
- Allow browsing without login
- Pop back to previous screen after login
- Use `context.watch<AuthProvider>()` for reactive auth changes
- Mark onboarding as complete immediately when user finishes

❌ **Don't:**
- Force login immediately on app launch
- Show login before browsing
- Navigate away from profile after login
- Clear onboarding flag on logout
- Use direct auth checks in every screen (use gate pattern)

---

## Future Enhancements

### 1. Persistent Login Session
```dart
void _checkAuthState() async {
  // Check if user has existing session in Supabase
  final session = await Supabase.instance.client.auth.currentSession;
  if (session != null) {
    authProvider.restoreSession(session);
  }
}
```

### 2. Guest Checkout
Allow users to complete purchase without full account (email only)

### 3. Social Login
Add Google, Apple, GitHub login as auth options

### 4. Onboarding Customization
Show different onboarding based on user segment (new vs returning)

### 5. Deep Linking
Support URLs like `cyberspex://onboarding` or `cyberspex://profile`

---

## Testing Checklist

- [ ] First-time app launch shows onboarding
- [ ] Onboarding completes and saves to SharedPreferences
- [ ] Second app launch skips onboarding (goes to home)
- [ ] Can browse home, shop, wishlist without login
- [ ] Profile shows login prompt when not authenticated
- [ ] Clicking login from profile shows LoginScreen
- [ ] Successful login returns to ProfileScreen
- [ ] Profile shows user data after login
- [ ] Logout clears user but keeps onboarding flag
- [ ] All 6 bottom tabs functional
- [ ] Product detail accessible without auth
- [ ] Cart items persist without login
- [ ] Messages accessible without login

---

## Implementation Checklist

- [x] Create OnboardingScreen
- [x] Update SplashScreen to check onboarding status
- [x] Add onboarding route to main.dart
- [x] Update MainScreen navigation
- [x] Update ProfileScreen auth gate
- [x] Add SharedPreferences dependency (pubspec.yaml)
- [ ] Test on real device/emulator
- [ ] Verify SharedPreferences data persistence
- [ ] Add analytics tracking for onboarding completion
- [ ] Optimize onboarding animations
- [ ] Create admin onboarding reset function (debug)

---

## Dependency Note

Ensure pubspec.yaml includes:
```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.0.0  # For onboarding tracking
  provider: ^6.0.0  # For auth state
  # ... other dependencies
```

---

**Document Version:** 1.0  
**Last Updated:** March 22, 2026  
**Status:** Implementation Complete
