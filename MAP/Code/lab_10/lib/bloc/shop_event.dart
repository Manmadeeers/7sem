part of 'shop_bloc.dart';

sealed class ShopEvent extends Equatable {
  const ShopEvent();

  @override
  List<Object?> get props => const [];
}

final class ShopStarted extends ShopEvent {
  const ShopStarted();
}

final class UserSelected extends ShopEvent {
  const UserSelected(this.userId);

  final String userId;

  @override
  List<Object> get props => [userId];
}

final class FavoriteToggled extends ShopEvent {
  const FavoriteToggled(this.productId);

  final String productId;

  @override
  List<Object> get props => [productId];
}

final class ProductAdded extends ShopEvent {
  const ProductAdded(this.product);

  final Product product;

  @override
  List<Object> get props => [product];
}

final class ProductUpdated extends ShopEvent {
  const ProductUpdated(this.product);

  final Product product;

  @override
  List<Object> get props => [product];
}

final class ProductDeleted extends ShopEvent {
  const ProductDeleted(this.productId);

  final String productId;

  @override
  List<Object> get props => [productId];
}

final class WrongKeyDemoRequested extends ShopEvent {
  const WrongKeyDemoRequested();
}

final class StorageCompactionRequested extends ShopEvent {
  const StorageCompactionRequested();
}
