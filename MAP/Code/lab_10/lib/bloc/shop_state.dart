part of 'shop_bloc.dart';

enum ShopActionStatus { idle, inProgress, success, failure }

enum ShopAction {
  selectUser,
  toggleFavorite,
  addProduct,
  updateProduct,
  deleteProduct,
  wrongKeyDemo,
  compactStorage,
}

sealed class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => const [];
}

final class ShopInitial extends ShopState {
  const ShopInitial();
}

final class ShopLoadInProgress extends ShopState {
  const ShopLoadInProgress();
}

final class ShopLoadSuccess extends ShopState {
  ShopLoadSuccess({
    required List<Product> products,
    required List<ShopUser> users,
    required this.currentUser,
    required Set<String> favoriteProductIds,
    required this.storageDescription,
    required this.keyFingerprint,
    this.actionStatus = ShopActionStatus.idle,
    this.action,
    this.actionMessage,
    this.actionRevision = 0,
  }) : products = List.unmodifiable(products),
       users = List.unmodifiable(users),
       favoriteProductIds = Set.unmodifiable(favoriteProductIds);

  final List<Product> products;
  final List<ShopUser> users;
  final ShopUser currentUser;
  final Set<String> favoriteProductIds;
  final String storageDescription;
  final String keyFingerprint;
  final ShopActionStatus actionStatus;
  final ShopAction? action;
  final String? actionMessage;
  final int actionRevision;

  bool isFavorite(String productId) => favoriteProductIds.contains(productId);

  ShopLoadSuccess copyWith({
    ShopActionStatus? actionStatus,
    ShopAction? action,
    String? actionMessage,
    int? actionRevision,
  }) {
    return ShopLoadSuccess(
      products: products,
      users: users,
      currentUser: currentUser,
      favoriteProductIds: favoriteProductIds,
      storageDescription: storageDescription,
      keyFingerprint: keyFingerprint,
      actionStatus: actionStatus ?? this.actionStatus,
      action: action ?? this.action,
      actionMessage: actionMessage,
      actionRevision: actionRevision ?? this.actionRevision,
    );
  }

  @override
  List<Object?> get props => [
    products,
    users,
    currentUser,
    favoriteProductIds,
    storageDescription,
    keyFingerprint,
    actionStatus,
    action,
    actionMessage,
    actionRevision,
  ];
}

final class ShopLoadFailure extends ShopState {
  const ShopLoadFailure(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
