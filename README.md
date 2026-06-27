# CyberSpex E‑Commerce (Flutter + Supabase)

CyberSpex is a mobile-first e-commerce application built with **Flutter** and powered by **Supabase** for authentication, catalog data, orders, reviews, and (optionally) **M‑Pesa STK Push** via Supabase Edge Functions.

It follows a **guest-first** UX: users can browse immediately, while account-specific features (Profile, Orders, Addresses) require login.

---

## Features

### Client (Flutter)
- Guest-first browsing (no login required to explore products)
- Onboarding flow (first launch only) using `SharedPreferences`
- Tab navigation with protected screens (Profile / Orders / Addresses)
- Cart & wishlist stored locally (per device)
- Clean Architecture data layer (DTO → Repository → Provider → UI)
- Pagination (20 items/page) + caching
- Error handling with custom exceptions

### Backend (Supabase)
- Supabase Auth + `profiles` table
- Products, categories, images, orders, order_items, reviews
- Row Level Security (RLS) policies per table
- Supabase Edge Functions for M‑Pesa STK Push

---

## Project Structure

Key directories:

- `lib/main.dart` – app bootstrap, dependency injection, routes
- `lib/screens/` – UI screens (home, shop, cart, product detail, profile, etc.)
- `lib/providers/` – state management (Auth, Product, Cart, Wishlist, etc.)
- `lib/domain/` – business entities + repository interfaces (Clean Architecture)
- `lib/data/` – remote datasource, DTOs, repository implementations, exceptions
- `supabase/` – Supabase config + Edge Functions
- `assets/` – images and app icons

---

## App Flow (Guest-first + Auth on demand)

### First-time user
1. App launch → `SplashScreen` (2s)
2. Onboarding carousel (`OnboardingScreen`, 4 slides)
3. After “Get Started” / “Skip” → Home (`MainScreen`)
4. Profile tab prompts login only when accessed

### Returning user
1. App launch → Splash checks onboarding flag
2. If onboarding seen → direct to Home
3. Profile prompts login only if not authenticated

Implementation is documented in:
- `AUTH_AND_ONBOARDING_FLOW.md`
- `ONBOARDING_IMPLEMENTATION_SUMMARY.md`

---

## Navigation & Routing

Navigation uses:
- Named routes for static screens
- Dynamic routing for product details
- Bottom tab navigation managed inside `MainScreen`

See:
- `NAVIGATION_AND_ROUTING_GUIDE.md`

---

## Clean Architecture (Data Layer)

The app uses a Clean Architecture approach:

1. **Domain** (`lib/domain/`)
   - Entities (type-safe business models)
   - Repository interfaces

2. **Data** (`lib/data/`)
   - DTOs mapping Supabase JSON payloads → Entities
   - `RemoteDataSource` (Supabase queries)
   - Repository implementations (caching, fallback, error mapping)
   - Custom exceptions for network/auth/validation/cache/business errors

3. **Presentation** (`lib/providers/`, `lib/screens/`)
   - Providers coordinate repositories and expose state to UI

The implementation summary is documented in:
- `CLEAN_ARCHITECTURE_IMPLEMENTATION.md`

---

## Backend Setup (Supabase)

### Database & RLS
Tables and security are planned and documented in:
- `BACKEND_LOGIC_PLAN.md`

SQL setup scripts included in repo:
- `supabase_cart_items_setup.sql`
- `supabase_mpesa_setup.sql`
- `supabase_rls_fix.sql`
- `supabase_wishlist_setup.sql`

### Supabase Edge Functions
M‑Pesa STK Push endpoints are documented in:
- `MPESA_SETUP.md`

Functions folder:
- `supabase/functions/`
  - `stkpush/`
  - `callback/`
  - `payment-status/`

---

## M‑Pesa STK Push (Optional)

The app can integrate payments via Supabase Edge Functions.

Documented endpoints:
- `POST /functions/v1/stkpush`
- `POST /functions/v1/callback`
- `GET /functions/v1/payment-status?order_id=<id>`

Setup is in:
- `MPESA_SETUP.md`

---

## Local Development

### Prerequisites
- Flutter SDK
- A Supabase project with the configured tables/RLS and storage bucket for product images
- (Optional) M‑Pesa credentials configured in Supabase Edge Functions

### Run (client)
```bash
flutter pub get
flutter run
```

---

## Testing Checklist (Quick)

- First app launch shows onboarding and marks it complete
- Second launch skips onboarding
- Browsing works without login (Home / Shop / Wishlist / Cart / Messages)
- Profile prompts login when not authenticated
- Logging in shows profile data after returning to ProfileScreen

---

## Documents in Repo

- `AUTH_AND_ONBOARDING_FLOW.md` – guest-first UX + auth on demand
- `ONBOARDING_IMPLEMENTATION_SUMMARY.md` – onboarding implementation details
- `NAVIGATION_AND_ROUTING_GUIDE.md` – routing design
- `CLEAN_ARCHITECTURE_IMPLEMENTATION.md` – data layer implementation
- `BACKEND_LOGIC_PLAN.md` – database schema & request flow plan
- `MPESA_SETUP.md` – STK Push setup + environment variables

---

## Notes on Security

- Client should use **Supabase anon key** for public operations
- Server/admin operations use **service_role key** (never in frontend)
- RLS policies protect order updates and sensitive tables

---

## Version
- Document version: 1.0
- Last updated: 2026-03-22
