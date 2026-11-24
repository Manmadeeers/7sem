import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../data/shop_store.dart';
import '../models/product.dart';
import '../models/shop_user.dart';

part 'shop_event.dart';
part 'shop_state.dart';

typedef ShopStoreLoader = Future<ShopStore> Function();

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  ShopBloc({required ShopStoreLoader storeLoader})
    : _storeLoader = storeLoader,
      super(const ShopInitial()) {
    on<ShopStarted>(_onStarted);
    on<UserSelected>(_onUserSelected);
    on<FavoriteToggled>(_onFavoriteToggled);
    on<ProductAdded>(_onProductAdded);
    on<ProductUpdated>(_onProductUpdated);
    on<ProductDeleted>(_onProductDeleted);
    on<WrongKeyDemoRequested>(_onWrongKeyDemoRequested);
    on<StorageCompactionRequested>(_onStorageCompactionRequested);
  }

  final ShopStoreLoader _storeLoader;
  ShopStore? _store;
  int _actionRevision = 0;

  Future<void> _onStarted(ShopStarted event, Emitter<ShopState> emit) async {
    emit(const ShopLoadInProgress());
    try {
      _store = await _storeLoader();
      emit(_snapshot());
    } catch (error) {
      emit(ShopLoadFailure(_errorMessage(error)));
    }
  }

  Future<void> _onUserSelected(
    UserSelected event,
    Emitter<ShopState> emit,
  ) async {
    await _runAction(
      emit,
      action: ShopAction.selectUser,
      operation: () => _requiredStore.selectUser(event.userId),
      successMessage: 'Active user changed.',
    );
  }

  Future<void> _onFavoriteToggled(
    FavoriteToggled event,
    Emitter<ShopState> emit,
  ) async {
    await _runAction(
      emit,
      action: ShopAction.toggleFavorite,
      operation: () => _requiredStore.toggleFavorite(event.productId),
      successMessage: 'Favorites updated.',
    );
  }

  Future<void> _onProductAdded(
    ProductAdded event,
    Emitter<ShopState> emit,
  ) async {
    await _runAction(
      emit,
      action: ShopAction.addProduct,
      operation: () => _requiredStore.addProduct(event.product),
      successMessage: '${event.product.name} created.',
    );
  }

  Future<void> _onProductUpdated(
    ProductUpdated event,
    Emitter<ShopState> emit,
  ) async {
    await _runAction(
      emit,
      action: ShopAction.updateProduct,
      operation: () => _requiredStore.updateProduct(event.product),
      successMessage: '${event.product.name} updated.',
    );
  }

  Future<void> _onProductDeleted(
    ProductDeleted event,
    Emitter<ShopState> emit,
  ) async {
    await _runAction(
      emit,
      action: ShopAction.deleteProduct,
      operation: () => _requiredStore.deleteProduct(event.productId),
      successMessage: 'Product deleted.',
    );
  }

  Future<void> _onWrongKeyDemoRequested(
    WrongKeyDemoRequested event,
    Emitter<ShopState> emit,
  ) async {
    await _runAction(
      emit,
      action: ShopAction.wrongKeyDemo,
      operation: _requiredStore.demonstrateWrongKey,
    );
  }

  Future<void> _onStorageCompactionRequested(
    StorageCompactionRequested event,
    Emitter<ShopState> emit,
  ) async {
    await _runAction(
      emit,
      action: ShopAction.compactStorage,
      operation: _requiredStore.compactBoxes,
    );
  }

  Future<void> _runAction(
    Emitter<ShopState> emit, {
    required ShopAction action,
    required Future<Object?> Function() operation,
    String? successMessage,
  }) async {
    final current = state;
    if (current is! ShopLoadSuccess) return;

    emit(
      current.copyWith(
        actionStatus: ShopActionStatus.inProgress,
        action: action,
        actionRevision: ++_actionRevision,
      ),
    );

    try {
      final result = await operation();
      emit(
        _snapshot(
          actionStatus: ShopActionStatus.success,
          action: action,
          actionMessage: successMessage ?? result?.toString(),
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          actionStatus: ShopActionStatus.failure,
          action: action,
          actionMessage: _errorMessage(error),
          actionRevision: ++_actionRevision,
        ),
      );
    }
  }

  ShopStore get _requiredStore {
    final value = _store;
    if (value == null) throw StateError('The shop has not been loaded yet.');
    return value;
  }

  ShopLoadSuccess _snapshot({
    ShopActionStatus actionStatus = ShopActionStatus.idle,
    ShopAction? action,
    String? actionMessage,
  }) {
    final store = _requiredStore;
    return ShopLoadSuccess(
      products: store.products,
      users: store.users,
      currentUser: store.currentUser,
      favoriteProductIds: {
        for (final product in store.products)
          if (store.isFavorite(product.id)) product.id,
      },
      storageDescription: store.storageDescription,
      keyFingerprint: store.keyFingerprint,
      actionStatus: actionStatus,
      action: action,
      actionMessage: actionMessage,
      actionRevision: ++_actionRevision,
    );
  }

  String _errorMessage(Object error) {
    if (error is StateError) return error.message;
    return 'Operation failed: $error';
  }
}
