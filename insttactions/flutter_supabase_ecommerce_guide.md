Flutter E-commerce with Supabase Integration - Comprehensive Guide

---

# 1. Architecture Overview

## 1.1 Backend Modules

- **Authentication:** Managed by Supabase Auth. Handles signup, login, session management.
- **Profiles / Accounts:** Separate table `profiles` storing user info (name, phone, address, role). Links to Supabase Auth user ID.
- **Products:** Table `products` storing details (title, description, price in integer for cents, stock, category_id, created_at, updated_at). Images stored in `product_images` table (one-to-many).
- **Categories:** Table `categories` with `parent_id` for subcategories.
- **Orders:** Table `orders` (summary) + `order_items` (details). `order_items.price_at_purchase` stores historical price.
- **Admin Website:** Separate frontend accessing same backend, uses `role` field in `profiles` for permissions.
- **Storage:** Supabase Storage buckets for images. Product images are usually public URLs.

## 1.2 Relationships

- User (profiles) 1 → many Orders
- Order 1 → many order_items
- Product 1 → many product_images
- Category self-referencing for subcategories
- Cart stored locally initially; can be migrated later

# 2. Clean Architecture Integration

## 2.1 Layers

- **Domain Layer:** Entities like User, Product, Order. Business logic lives here.
- **Data Layer:** Datasources (SupabaseRemoteDatasource), Repositories (transform DTO to entities).
- **Presentation Layer:** Flutter widgets, Bloc/Provider state management, only consume entities.

## 2.2 DTOs

- Separate backend structure from UI model.
- Map Supabase JSON responses → DTO → Entity → UI model.

# 3. User Model & Auth Flow

## 3.1 User Class

- Contains id, name, email, phone?, address?
- `fromJson` maps backend JSON → Flutter object
- `toJson` maps Flutter object → backend JSON
- UI decides which fields to display; all fields exist in model for system logic

## 3.2 Auth Lifecycle

- App startup → check Supabase session → valid? fetch profile → else logout
- Cache user object locally for faster UI & offline
- Session may expire → enforce logout if user disabled

# 4. Product & Image Fetching Strategy

- **Pagination:** Fetch initial page, then cache & update from remote.
- **Images:** Load separately; main image prefetch, others lazy-load.
- **Categories:** Fetch once & cache.
- **Stock Handling:** Show “out of stock” label instead of removing product.
- **Realtime vs Pull:** Start with pull-to-refresh; optionally enable Realtime updates.

# 5. Orders & Checkout

- Cart stored locally first.
- Checkout → create orders & order_items → process payment → reduce stock
- Total price stored in order (snapshot), not calculated dynamically

# 6. Admin Website Considerations

- Can add, edit, remove products
- Upload images  
- Update order status
- Permissions controlled via `role` field
- Shares same Supabase backend

# 7. Security & RLS

- Row Level Security for all tables
  - Customers: read products, create orders, view own orders
  - Admins: insert/update/delete products, update order status
- Images: public for products; protected for sensitive documents

# 8. Flow Diagram Reference

- User opens home screen:
  1. Check auth session
  2. Fetch categories (cached)
  3. Fetch paginated products (cache first, then remote)
  4. Load images separately
  5. Display products; show out-of-stock labels
  6. Admin changes reflected via pull-to-refresh or Realtime

# 9. Incremental Migration Strategy

- Phase 1: Auth → remote, Products → local
- Phase 2: Products → remote
- Phase 3: Orders → remote
- Phase 4: Remove local mock data

# 10. Best Practices

- Store price in integer (cents) for precision
- Soft-delete products for historical integrity
- Keep cart locally initially; migrate to DB later
- Profile created automatically on signup, customizable by user
- Map DTO → Entity → UI model for backend changes
- Enforce auth & session validation on every critical operation
- Plan for scalability (categories, stock, subcategories, RLS)

---

This document can be used as a **reference blueprint** during Flutter + Supabase integration, ensuring clean architecture, security, and professional backend logic.

