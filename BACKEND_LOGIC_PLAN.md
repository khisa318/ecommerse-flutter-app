# CyberSpex E-Commerce Backend Logic Plan

## 1. Database Schema & Supabase Tables

### 1.1 Core Tables

#### `auth.users` (Supabase Auth)
- Managed by Supabase
- Stores: id (UUID), email, password hash, created_at, updated_at

#### `profiles`
```
- id (UUID) — Foreign key to auth.users.id
- name (TEXT)
- email (TEXT)
- phone (TEXT, nullable)
- address (TEXT, nullable)
- role (ENUM: 'customer' | 'admin')
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
- RLS: Customers can view/edit own profile; Admins can view all
```

#### `categories`
```
- id (BIGSERIAL PRIMARY KEY)
- name (TEXT, UNIQUE)
- parent_id (BIGINT, nullable) — Self-reference for subcategories
- created_at (TIMESTAMP)
- is_active (BOOLEAN)
- RLS: Public read; Admin write
- Cache: Long-term (24 hrs)
```

#### `products`
```
- id (BIGSERIAL PRIMARY KEY)
- title (TEXT)
- description (TEXT)
- price (INTEGER) — Stored in cents (e.g., 9999 = $99.99)
- discount_percentage (DECIMAL, nullable, 0-100)
- stock_quantity (INTEGER)
- category_id (BIGINT) — Foreign key to categories
- is_active (BOOLEAN)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
- RLS: Public read; Admin write
- Indices: category_id, is_active, created_at (for sorting)
- Cache: 5 minutes
```

#### `product_images`
```
- id (BIGSERIAL PRIMARY KEY)
- product_id (BIGINT) — Foreign key to products
- image_url (TEXT)
- is_main (BOOLEAN) — Main image for product card
- order (INTEGER) — Sequence for lazy loading
- created_at (TIMESTAMP)
- RLS: Public read; Admin write
- Storage: Supabase Storage bucket 'product-images/'
```

#### `orders`
```
- id (BIGSERIAL PRIMARY KEY)
- user_id (UUID) — Foreign key to profiles.id
- total_price (INTEGER) — Snapshot at purchase
- status (ENUM: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled')
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
- RLS: Customers view own; Admins view all and can update status
```

#### `order_items`
```
- id (BIGSERIAL PRIMARY KEY)
- order_id (BIGINT) — Foreign key to orders
- product_id (BIGINT) — Foreign key to products
- quantity (INTEGER)
- price_at_purchase (INTEGER) — Cents, snapshot of product price
- created_at (TIMESTAMP)
- RLS: Based on order ownership
```

#### `reviews`
```
- id (BIGSERIAL PRIMARY KEY)
- product_id (BIGINT) — Foreign key to products
- user_id (UUID) — Foreign key to profiles.id
- rating (INTEGER, 1-5)
- comment (TEXT, nullable)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
- RLS: Public read; Customers write own; Admins moderate
```

---

## 2. Authentication Flow

### 2.1 Startup (App Launch)

```
START
  ↓
[1. CHECK AUTH SESSION]
  - Supabase.auth.currentSession exists?
  ↓
  ├─ YES → Fetch user profile from profiles table
  │          ├─ Success? → Cache profile locally
  │          │               CONTINUE TO HOME SCREEN
  │          └─ Failed (user disabled) → FORCE LOGOUT & REDIRECT TO LOGIN
  │
  └─ NO → REDIRECT TO LOGIN SCREEN
         (Show splash/loading briefly)
END
```

### 2.2 Login Flow
```
User enters email + password
  ↓
[SUPABASE AUTH LOGIN]
  Supabase.auth.signInWithPassword(email, password)
  ├─ Success → Fetch profile data (name, phone, address, role)
  │             Cache user object locally (Hive/SharedPrefs)
  │             Emit logged-in state → Navigate to HOME
  └─ Failed → Show error message & retry
```

### 2.3 Signup Flow
```
User fills: email, password, name
  ↓
[SUPABASE AUTH SIGNUP]
  Supabase.auth.signUpWithPassword(email, password)
  ├─ Success → Create profile record (role='customer', auto-assigned)
  │             Cache user object
  │             Emit signed-up state → Navigate to HOME
  └─ Failed → Show error & retry
```

### 2.4 Logout Flow
```
User taps logout
  ↓
[CLEAR LOCAL CACHE]
  - Delete cached user object
  - Clear cart (local)
  ↓
[SUPABASE LOGOUT]
  Supabase.auth.signOut()
  ↓
REDIRECT TO LOGIN SCREEN
```

---

## 3. Home Screen Data Loading Flow

### 3.1 Entry Point: User Opens Home Screen

```
START: User taps Home tab or app launches to home
  ↓
[STEP 1: CHECK LOCAL CACHE]
  Is cached data valid & not expired?
  ├─ YES (Cache Fresh) → [STEP 2b: USE CACHED DATA]
  └─ NO (Cache Invalid/Missing) → [STEP 2a: SHOW LOADING SHIMMER]
```

### 3.2a Loading Path (No Cache)

```
[SHOW LOADING SHIMMER]
  - Skeleton UI for categories + product grid
  ↓
[STEP 2: FETCH CATEGORIES]
  ├─ Network available?
  │   ├─ YES → Query Supabase: SELECT * FROM categories WHERE is_active=true
  │   │         ├─ Success → Cache locally (expiry: 24 hrs)
  │   │         │              CONTINUE
  │   │         └─ Network Error → Show cached categories (if any)
  │   │                            Or show error + "Pull to Retry"
  │   └─ NO → Show cached categories or empty state
  ↓
[STEP 3: FETCH PRODUCTS (Paginated)]
  Query: SELECT * FROM products 
         WHERE is_active=true AND category_id=? (if filtered)
         ORDER BY created_at DESC
         LIMIT 20
  ├─ Success → Cache first 20 locally (expiry: 5 mins)
  │             Remove loading shimmer
  │             Display products grid
  └─ Error → Show error banner + "Pull to Refresh"
             If cached data exists → show stale data with warning
  ↓
[STEP 4: FETCH PRODUCT IMAGES (Lazy Loading)]
  For each product:
    - Display main_image (is_main=true) → cached URL
    - Load thumbnail in background
  Images are public URLs from Supabase Storage
  └─ No caching needed (URL directly to CDN)
  ↓
[STEP 5: PROCESS & DISPLAY]
  ✓ Show product cards with:
    - Main image + title + price
    - Discount badge (if discount_percentage > 0)
    - "IN STOCK" or "OUT OF STOCK" label (based on stock_quantity > 0)
    - "Add to Cart" button (disabled if out of stock)
  ✓ Show categories as horizontal scroll
  ↓
HOME SCREEN READY
```

### 3.2b Cached Data Path

```
[LOAD FROM LOCAL CACHE]
  - Load categories from Hive
  - Load products from Hive
  ↓
[DISPLAY IMMEDIATELY] (< 100ms)
  - Show cached products grid
  - Show cached categories
  ↓
[BACKGROUND: FETCH FRESH DATA]
  - Silently fetch latest from Supabase (non-blocking)
  - If data differs → Update UI smoothly (list rebuild)
  - If error → Keep showing cached data (no disruption)
  ↓
HOME SCREEN READY (Instant + Updates)
```

### 3.3 Pull-to-Refresh Flow

```
User swipes down
  ↓
[REFRESH TRIGGER]
  1. Clear current data state
  2. Show small refresh indicator
  ↓
[REPEAT: FETCH CATEGORIES]
  (Same as Step 2 above)
  ↓
[REPEAT: FETCH PRODUCTS]
  (Same as Step 3 above, page 1 only)
  ↓
[REPEAT: FETCH IMAGES]
  (Same as Step 4 above)
  ↓
[UPDATE UI] & Hide refresh indicator
  ↓
COMPLETE
```

---

## 4. Pagination Logic

### 4.1 Initial Load
```
Page = 1, Limit = 20
SELECT * FROM products WHERE is_active=true ORDER BY created_at LIMIT 20
Result: products[0-19]
Cache locally (expiry: 5 mins)
```

### 4.2 Load More (Scroll to End)
```
User scrolls near bottom
  ↓
Is page 2 already loading?
  ├─ YES → Wait for current request
  └─ NO → Fetch page 2
           SELECT * FROM products 
           WHERE is_active=true
           ORDER BY created_at
           LIMIT 20 OFFSET 20
           Result: products[20-39]
           Append to existing list
           Cache updated list
           Display "Load More" progress at bottom
```

### 4.3 Cache Management for Pagination
```
Cache Key: "products_page_1", "products_page_2", etc.
Expiry: 5 minutes
On page load: Load page 1 first, then fetch page 2+ on demand
On refresh: Clear all pagination cache, start fresh
```

---

## 5. Caching Strategy

### 5.1 Cache Layers

| Data | Cache Type | Expiry | Use Case |
|------|-----------|--------|----------|
| Categories | Local (Hive) | 24 hrs | Rarely changes; instant load |
| Products (Page 1) | Local (Hive) | 5 mins | Most viewed; balance freshness |
| Products (Page 2+) | Local (Hive) | 5 mins | On-demand pagination |
| Product Images | CDN (URL) | N/A | Public storage; no local cache needed |
| User Profile | Local (SharedPrefs) | Session | Auth state; updated on login |
| Cart | Local (Hive) | Until cleared | Never synced to backend (v1) |

### 5.2 Cache Invalidation

```
On logout:
  - Clear all caches (categories, products, user, cart)

On admin update (server-side):
  - Future: Listen to Realtime changes
  - Current: Pull-to-refresh triggers fresh fetch

On app version upgrade:
  - Clear old schema caches (version mismatch)
```

---

## 6. Error Handling

### 6.1 Network Errors

```
ERROR: Network Unavailable
  ├─ Cached data exists? → Show stale data + warning banner
  │                         "You're viewing offline content"
  └─ No cache? → Show error state
                  "No internet. Please try again."
                  Show "Retry" button

ERROR: Request Timeout (> 10s)
  ├─ Cached data? → Use cache + show "Loading..." indicator
  └─ No cache? → Show timeout error + retry button
```

### 6.2 Server Errors (5xx)

```
ERROR: 500, 502, 503
  ├─ Cached data? → Show cache + banner: "Server temporarily unavailable"
  └─ No cache? → Show error + retry button
                  Log to error tracking (Sentry)

ERROR: 400, 404
  ├─ Invalid request (malformed) → Log + show generic error
  └─ Not found (product deleted) → Remove from UI
```

### 6.3 Auth Errors

```
ERROR: 401 Unauthorized (session expired)
  → Force logout
  → Redirect to login screen
  → Show: "Session ended. Please log in again."

ERROR: 403 Forbidden (RLS violation)
  → Likely a code bug
  → Show: "Permission denied"
  → Log to error tracking
```

---

## 7. Cart & Checkout Flow

### 7.1 Cart Operations (Local)

```
[ADD TO CART]
  1. Get product (id, title, price, image_url)
  2. Store in local Cart table (Hive)
  3. Update cart count badge
  4. Show toast: "Added to cart"

[VIEW CART]
  1. Load all items from local cache
  2. Display items with:
     - Product image + title
     - Current price (fetched fresh)
     - Quantity selector
     - Remove button

[UPDATE QUANTITY]
  1. Modify quantity in local cache
  2. Recalculate subtotal
  3. Show updated total

[REMOVE FROM CART]
  1. Delete from local cache
  2. Update UI

[CALCULATE TOTALS]
  - Subtotal = SUM(price * quantity)
  - Tax = Subtotal * TAX_RATE (if applicable)
  - Total = Subtotal + Tax + Shipping
```

### 7.2 Checkout Flow

```
[CHECKOUT INITIATION]
  User taps "Proceed to Checkout"
  ├─ User logged in?
  │   ├─ YES → Continue
  │   └─ NO → Redirect to login → Re-enter checkout
  ├─ Cart has items?
  │   ├─ YES → Continue
  │   └─ NO → Show empty cart message
  ├─ Stock available?
  │   ├─ YES for all items → Continue
  │   └─ NO → Show which items out of stock, remove them
  ↓
[ENTER SHIPPING ADDRESS]
  - Allow selection from saved addresses or new address
  - Validate: full address, phone, city, zip
  ↓
[SELECT PAYMENT METHOD]
  - Options: Credit card / Debit card / Other payment gateway
  (Payment processing: integrate Stripe/PayPal later)
  ↓
[CREATE ORDER RECORD]
  INSERT INTO orders (user_id, total_price, status)
  VALUES (?, ?, 'pending')
  → Capture order_id
  ↓
[CREATE ORDER ITEMS]
  FOR each cart item:
    INSERT INTO order_items (order_id, product_id, quantity, price_at_purchase)
    VALUES (order_id, product_id, qty, price_snapshot)
  ↓
[PROCESS PAYMENT]
  (Payment gateway integration)
  ├─ Success → Update order status = 'processing'
  │             Clear cart
  │             Emit order success
  │             Navigate to order confirmation
  └─ Failed → Show payment error
              Keep order in 'pending'
              Allow retry
  ↓
[REDUCE STOCK] (After payment success)
  UPDATE products SET stock_quantity = stock_quantity - qty
  WHERE id = product_id
  ↓
[ORDER CONFIRMATION]
  Display:
  - Order ID
  - Order date
  - Items list
  - Total paid
  - Expected delivery
  - Tracking info (if available)
```

### 7.3 Order History

```
[LOAD ORDER HISTORY]
  Query: SELECT * FROM orders WHERE user_id = ?
         ORDER BY created_at DESC
  ├─ Success → Display list of orders
  │             Click order → Show details (order_items, total, status)
  └─ Error → Show error message + retry
```

---

## 8. Product Detail Screen

```
[USER TAPS PRODUCT CARD]
  ↓
[FETCH FULL PRODUCT DATA]
  Query: SELECT * FROM products WHERE id = ?
  ├─ Cache first (if available)
  └─ Fetch fresh from Supabase
  ↓
[LOAD ALL PRODUCT IMAGES]
  Query: SELECT * FROM product_images WHERE product_id = ?
         ORDER BY order ASC
  - Load main image (is_main=true) first
  - Lazy load other images
  ↓
[FETCH REVIEWS] (Optional: Paginated)
  Query: SELECT * FROM reviews WHERE product_id = ?
         ORDER BY created_at DESC LIMIT 10
  ↓
[DISPLAY]
  - Full product info (title, description, price, stock)
  - Image gallery (swipeable)
  - Star rating (avg of reviews)
  - Related products (same category)
  - Add to Cart button
  - Add to Wishlist button
  ↓
[ADD TO CART FROM DETAIL]
  - User selects quantity
  - Taps "Add to Cart"
  - Product added to local cart
  - Show toast + option to go to cart
```

---

## 9. Admin Operations

### 9.1 Product Management (Admin Only)

```
[CREATE PRODUCT]
  Form:
  - title, description, price (cents), category_id, stock_quantity
  - Upload main image → stored in product-images/ bucket
  - Additional images (lazy loaded)
  ↓
  INSERT INTO products (title, description, ...)
  INSERT INTO product_images (product_id, image_url, is_main=true, ...)
  ↓
  Success → Show confirmation
  Cache invalidated (products cache cleared)
  ↓
[UPDATE PRODUCT]
  Same form structure
  UPDATE products SET ... WHERE id = ?
  UPDATE product_images (if image changed)
  ↓
[DELETE PRODUCT] (Soft-delete preferred)
  UPDATE products SET is_active = false WHERE id = ?
  (Keeps order history intact)
  ↓
[MANAGE STOCK]
  UPDATE products SET stock_quantity = ? WHERE id = ?
```

### 9.2 Order Management (Admin Only)

```
[VIEW ALL ORDERS]
  Query: SELECT * FROM orders ORDER BY created_at DESC
  Display: Order ID, customer name, total, status, date
  ↓
[UPDATE ORDER STATUS]
  pending → processing → shipped → delivered
  UPDATE orders SET status = ?, updated_at = now()
  Optionally: Send email notification to customer
  ↓
[VIEW ORDER DETAILS]
  Show order_items with product info + quantity + price_at_purchase
  Calculate refund (if cancelled)
```

---

## 10. Performance Optimizations

### 10.1 Data Fetching
- ✓ Pagination (20 items per page)
- ✓ Lazy load images (main image first)
- ✓ Index products by category_id, is_active, created_at
- ✓ Use SELECT with specific columns (not SELECT *)
- ✓ Limit queries with LIMIT clause

### 10.2 Caching
- ✓ Cache categories for 24 hrs
- ✓ Cache products for 5 mins
- ✓ Show cached data instantly (< 100ms)
- ✓ Background refresh non-blocking
- ✓ Cache-first, then fetch pattern

### 10.3 UI/UX
- ✓ Show loading shimmer (not spinner)
- ✓ Display cached data while loading fresh
- ✓ Smooth scroll with pagination
- ✓ Lazy load images in product detail
- ✓ Skip-loading for fast perceived load

### 10.4 Network
- ✓ Timeout: 10 seconds per request
- ✓ Retry: Exponential backoff (1s, 2s, 4s)
- ✓ Compression: Supabase handles gzip
- ✓ CDN: Images served from Supabase Storage CDN

---

## 11. Security & RLS Rules

### 11.1 Row Level Security Policies

```
CATEGORIES:
  - SELECT: PUBLIC (all users can view)
  - INSERT/UPDATE/DELETE: ADMIN only (role='admin')

PRODUCTS:
  - SELECT: PUBLIC (all users can view active products only)
  - INSERT/UPDATE/DELETE: ADMIN only

PRODUCT_IMAGES:
  - SELECT: PUBLIC
  - INSERT/UPDATE/DELETE: ADMIN only

PROFILES:
  - SELECT: Users can view own profile + admins can view all
  - INSERT: Only new signup (created via trigger)
  - UPDATE: Users can update own, admins can update all
  - DELETE: Never allowed

ORDERS:
  - SELECT: Users view own orders + admins view all
  - INSERT: Users can create own, admins can create any
  - UPDATE: Admins can update status; users cannot
  - DELETE: Never allowed

ORDER_ITEMS:
  - SELECT: Based on order_id ownership
  - INSERT: Based on order_id ownership
  - DELETE: Never allowed

REVIEWS:
  - SELECT: PUBLIC
  - INSERT: Authenticated users
  - UPDATE: Own reviews or admin
  - DELETE: Own reviews or admin
```

### 11.2 API Key Security
- Use `anon` key for client (public queries only)
- Use `service_role` key for backend/admin (with full access)
- Never expose keys in frontend; use secure endpoints

---

## 12. Supabase Function Calls (Backend Logic)

### 12.1 Recommended Edge Functions (Future)

```
POST /fetch-product-feed
  - Pagination + filtering
  - Returns products with images

POST /checkout
  - Validate cart
  - Create order
  - Process payment
  - Reduce stock (atomic transaction)

POST /get-user-orders
  - Fetch orders for logged-in user

POST /update-order-status
  - Admin only
  - Validate permission via RLS

POST /estimate-delivery
  - Calculate delivery date based on address
```

---

## 13. State Management Integration (Providers)

### 13.1 Provider Services

```
AuthProvider
  - Handle login, signup, logout
  - Cache user profile
  - Monitor session state

ProductProvider
  - Fetch products (paginated)
  - Cache locally
  - Handle pull-to-refresh

CategoryProvider
  - Fetch categories
  - Cache for 24 hrs
  - Listen to filter changes

CartProvider
  - Add/remove items (local)
  - Calculate totals
  - Submit checkout

OrderProvider
  - Fetch order history
  - Subscribe to order updates (future: Realtime)
  - Handle payment integration
```

---

## 14. Migration Phases

### Phase 1: Authentication (Backend-Ready)
- ✓ Supabase Auth setup
- ✓ Profiles table + RLS
- ✓ User session caching

### Phase 2: Products (Backend-Ready)
- ✓ Products + Categories tables
- ✓ Product images fetching
- ✓ Pagination + caching
- ✓ Home screen flow

### Phase 3: Orders (Partially-Ready)
- ✓ Orders + Order items tables
- ✓ Checkout flow (local cart → backend)
- ⏳ Payment integration (Stripe/PayPal)

### Phase 4: Advanced
- ⏳ Reviews system
- ⏳ Wishlist (backend storage vs. local)
- ⏳ Real-time updates (Supabase Realtime)
- ⏳ Admin dashboard

---

## 15. Testing & Validation

### 15.1 Backend Testing
- [ ] RLS policies (query as customer, query as admin)
- [ ] Pagination edge cases (page 1, last page, empty)
- [ ] Error handling (network off, server 500)
- [ ] Cart checkout validation (stock, prices)
- [ ] Stock updates (concurrent orders)

### 15.2 Data Validation
- [ ] Email format (auth)
- [ ] Price format (integers/cents)
- [ ] Stock quantity (non-negative)
- [ ] Order totals (matches cart)
- [ ] Image URLs (404 handling)

### 15.3 Performance Testing
- [ ] Product load time (< 2s with cache, 5s+ without)
- [ ] Image loading (lazy load verified)
- [ ] Pagination load (20 items < 1s)
- [ ] Cache hit rate (> 80% for categories)

---

## 16. Implementation Checklist

- [ ] Create Supabase project & auth setup
- [ ] Design & create database tables
- [ ] Define RLS policies for all tables
- [ ] Set up Supabase Storage for product images
- [ ] Create DTOs + Entities for models
- [ ] Implement data sources (SupabaseRemoteDatasource)
- [ ] Implement repositories (transform DTO → Entity)
- [ ] Implement Providers for state management
- [ ] Build screens with error handling
- [ ] Add local caching (Hive)
- [ ] Implement pagination
- [ ] Test auth flow (login, signup, logout)
- [ ] Test product fetching (cache, network, error)
- [ ] Test cart & checkout (local flow)
- [ ] Performance optimization
- [ ] Deploy to production

---

## 17. API Endpoints Reference (Supabase RPC/REST)

### Categories
- `GET /rest/v1/categories` → Fetch all
- `GET /rest/v1/categories?select=*&is_active=eq.true`

### Products
- `GET /rest/v1/products?order=created_at.desc&limit=20`
- `GET /rest/v1/products?category_id=eq.{id}&limit=20&offset=0`
- `GET /rest/v1/products?id=eq.{id}` → Single product

### Product Images
- `GET /rest/v1/product_images?product_id=eq.{id}`

### Orders
- `GET /rest/v1/orders?user_id=eq.{user_id}&order=created_at.desc`
- `POST /rest/v1/orders` → Create order (with order_items)

### Auth
- `POST /auth/v1/signup` → Supabase Auth
- `POST /auth/v1/token?grant_type=password` → Login

---

## 18. Key Decisions Made

| Feature | Decision | Reason |
|---------|----------|--------|
| Price Storage | Integer (cents) | Precision for calculations |
| Image Caching | None (direct URL) | Supabase CDN handles it |
| Product Cache | 5 mins | Balance freshness + performance |
| Category Cache | 24 hrs | Rarely changes |
| Soft Deletes | Enabled | Preserve order history |
| Stock Handling | Show "out of stock" label | Better UX than hiding |
| Cart Storage | Local (Hive) | No backend sync needed yet |
| Pagination | 20 items/page | Good balance for mobile |
| Error Handling | Show cache + banner | Offline-friendly UX |
| RLS | Granular per-table | Security by design |

---

## Next Steps

1. **Create Supabase Project** → Set up auth, database, storage
2. **Define Models** → Create Dart classes matching DB schema
3. **Implement Data Layer** → Remote datasource + repositories
4. **Implement Providers** → State management for auth, products, cart
5. **Build Screens** → Home, product detail, cart, checkout, profile
6. **Add Caching** → Hive for local storage
7. **Error Handling** → Network, server, auth errors
8. **Performance** → Pagination, lazy loading, optimization
9. **Testing** → RLS, flows, edge cases
10. **Deployment** → Production Supabase, analytics

---

**Document Version:** 1.0  
**Last Updated:** March 22, 2026  
**Status:** Ready for Implementation
