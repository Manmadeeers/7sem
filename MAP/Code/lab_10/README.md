# Shoe Shop — laboratory 10 (BLoC)

The laboratory 4–5 catalog UI is backed by encrypted Hive storage.

Shared application state is managed only by `ShopBloc`, which extends
`Bloc<ShopEvent, ShopState>`. `MultiBlocProvider` exposes the BLoC at the root;
the instance is created once in `initState`, outside `build()`.

## BLoC structure

- `ShopStarted` performs asynchronous Hive initialization and produces
  `ShopLoadInProgress`, `ShopLoadSuccess`, or `ShopLoadFailure`.
- User selection, favorites, product CRUD, wrong-key demonstration, and Hive
  compaction are explicit immutable events.
- States and events use `Equatable`; success state collections are unmodifiable.
- Widgets render shared data with `BlocBuilder`/`BlocConsumer` and dispatch with
  `context.read<ShopBloc>().add(...)`.
- `BlocListener` handles navigation after a product save and displays operation
  errors as snackbars.

The remaining `setState` calls contain only local, short-lived UI state such as
the selected gallery page, form appearance controls, and platform-demo output.
No data owned by `ShopBloc` is changed through `setState`.

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
