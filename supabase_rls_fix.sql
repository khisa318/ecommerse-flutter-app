-- Run this in the Supabase SQL Editor for project xjmgfmkhtzdybbgkintb.
-- It opens public read access for storefront data and keeps profile access
-- limited to the signed-in owner.

-- PRODUCTS: allow everyone to view active products
alter table public.products enable row level security;

drop policy if exists "Public can view active products" on public.products;
create policy "Public can view active products"
on public.products
for select
to anon, authenticated
using (is_active = true);

-- CATEGORIES: allow everyone to view active categories
alter table public.categories enable row level security;

drop policy if exists "Public can view active categories" on public.categories;
create policy "Public can view active categories"
on public.categories
for select
to anon, authenticated
using (is_active = true);

-- PRODUCT IMAGES: allow everyone to view product images
alter table public.product_images enable row level security;

drop policy if exists "Public can view product images" on public.product_images;
create policy "Public can view product images"
on public.product_images
for select
to anon, authenticated
using (true);

-- PROFILES: let signed-in users view and update only their own profile
alter table public.profiles enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);
