# Wishlist Sync Setup Guide

## Overview
The wishlist feature now syncs with user accounts in Supabase. Follow these steps to set up the database tables.

## Supabase Table Migration

### Create Wishlist Table

1. Go to your Supabase project dashboard
2. Navigate to the SQL Editor
3. Run the following SQL to create the wishlist table:

```sql
-- Create wishlist table
CREATE TABLE public.wishlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, product_id)
);

-- Create index for faster queries
CREATE INDEX wishlist_user_id_idx ON public.wishlist(user_id);
CREATE INDEX wishlist_product_id_idx ON public.wishlist(product_id);

-- Enable RLS (Row Level Security)
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;

-- Create policy for users to view their own wishlist
CREATE POLICY "Users can view their own wishlist"
  ON public.wishlist FOR SELECT
  USING (auth.uid() = user_id);

-- Create policy for users to insert into their wishlist
CREATE POLICY "Users can add to their own wishlist"
  ON public.wishlist FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create policy for users to delete from their wishlist
CREATE POLICY "Users can remove from their wishlist"
  ON public.wishlist FOR DELETE
  USING (auth.uid() = user_id);
```

## Features Implemented

### WishlistProvider
- **Location**: `lib/providers/wishlist_provider.dart`
- **Methods**:
  - `loadWishlist()`: Load all wishlist items for the current user
  - `addToWishlist(Product)`: Add a product to wishlist
  - `removeFromWishlist(String)`: Remove a product from wishlist
  - `isInWishlist(String)`: Check if a product is in wishlist
  - `clearWishlist()`: Clear all items from wishlist
  - `moveToCart(Product)`: Move item to cart (removes from wishlist)

### WishlistScreen Updates
- Professional Material Design layout with gradient background
- Empty state message when wishlist is empty
- Real-time item management (add to cart, remove from wishlist)
- Clear All button with confirmation dialog
- Loading state indicator

## User Flow

1. **First Login**: When user logs in, wishlist data is available via the provider
2. **Add to Wishlist**: User can add products from shop/product detail screens
3. **View Wishlist**: Navigate to Wishlist tab to see saved items
4. **Manage Items**: 
   - Click heart icon to remove from wishlist
   - Click cart icon to move to cart
   - Click "Clear" button to remove all items
5. **Logout**: Wishlist data is cleared from local state

## Integration Points

### In Main Screen
- Wishlist tab replaced Messages tab
- 5-tab navigation: Home, Shop, Wishlist, Cart, Profile

### In Auth Provider  
- When user logs in, their wishlist ID is available via `Supabase.instance.client.auth.currentUser?.id`
- WishlistProvider automatically detects current user

### In Product Detail Screen (Future Integration)
```dart
// Add this to product detail screen
Consumer<WishlistProvider>(
  builder: (context, wishlistProvider, _) {
    final isWishlisted = wishlistProvider.isInWishlist(product.id);
    return IconButton(
      icon: Icon(
        isWishlisted ? Icons.favorite : Icons.favorite_outline,
        color: isWishlisted ? Colors.red : Colors.grey,
      ),
      onPressed: () {
        if (isWishlisted) {
          wishlistProvider.removeFromWishlist(product.id);
        } else {
          wishlistProvider.addToWishlist(product);
        }
      },
    );
  },
)
```

## Troubleshooting

- **Wishlist not loading**: Ensure user is logged in and wishlist table exists in Supabase
- **RLS Errors**: Check that Row Level Security policies are correctly applied
- **Products not found**: Verify product IDs in wishlist table match products table

## Testing

1. Create a test account
2. Add items to wishlist
3. Log out and log back in
4. Verify wishlist items persist
5. Test removal and clear functionality
