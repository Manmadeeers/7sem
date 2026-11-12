# Shoe Shop — laboratories 4–6 and 8

The laboratory 4–5 catalog UI is backed by encrypted Hive storage.

## Stored data

- `products` — image path, price, location, review count, description, sizes;
- `users` — Anna (customer), Max (manager), Admin (administrator);
- `favorites` — user/product relations and creation timestamps;
- `settings` — the selected user.

All four boxes use `HiveAesCipher` with a generated 256-bit key. The key is
saved separately in the application's internal support directory as
`shoe_shop_hive.key`. Only its short fingerprint is displayed in the UI.

## UI flow

- Switch users from the avatar menu in the catalog header.
- Every user can add/remove/view their own favorites.
- A manager or administrator can open **Manage products** and create, view,
  edit, or delete catalog products. The store layer checks the role again.
- **Hive storage** can create a second random key and demonstrate the expected
  read failure on an isolated encrypted demo box.q
- **Compact Hive boxes** calls `compact()` for every box and reports the file
  size before and after. A compaction strategy is also configured when boxes
  are opened.

## Verification

```bash
flutter pub get
flutter analyze
flutter test
```
