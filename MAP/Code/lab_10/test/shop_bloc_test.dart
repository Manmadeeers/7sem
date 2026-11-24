import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoe_shop/bloc/shop_bloc.dart';
import 'package:shoe_shop/data/shop_store.dart';

void main() {
  group('ShopBloc', () {
    test('emits loading and success during asynchronous startup', () async {
      final storeCompleter = Completer<ShopStore>();
      final bloc = ShopBloc(storeLoader: () => storeCompleter.future);
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<ShopLoadInProgress>(), isA<ShopLoadSuccess>()]),
      );

      bloc.add(const ShopStarted());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<ShopLoadInProgress>());

      storeCompleter.complete(MemoryShopStore.seeded());
      await expectation;
    });

    test('emits a load error when repository initialization fails', () async {
      final bloc = ShopBloc(
        storeLoader: () async => throw StateError('Storage unavailable'),
      );
      addTearDown(bloc.close);

      bloc.add(const ShopStarted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<ShopLoadFailure>().having(
            (state) => state.message,
            'message',
            'Storage unavailable',
          ),
        ),
      );
    });

    test('changes users and favorites only in response to events', () async {
      final bloc = ShopBloc(storeLoader: () async => MemoryShopStore.seeded());
      addTearDown(bloc.close);

      bloc.add(const ShopStarted());
      await bloc.stream.firstWhere((state) => state is ShopLoadSuccess);

      bloc.add(const UserSelected('max'));
      final selected = await bloc.stream
          .where((state) => state is ShopLoadSuccess)
          .cast<ShopLoadSuccess>()
          .firstWhere(
            (state) =>
                state.action == ShopAction.selectUser &&
                state.actionStatus == ShopActionStatus.success,
          );
      expect(selected.currentUser.id, 'max');
      expect(selected.isFavorite('lebron'), isFalse);

      bloc.add(const FavoriteToggled('lebron'));
      final favorite = await bloc.stream
          .where((state) => state is ShopLoadSuccess)
          .cast<ShopLoadSuccess>()
          .firstWhere(
            (state) =>
                state.action == ShopAction.toggleFavorite &&
                state.actionStatus == ShopActionStatus.success,
          );
      expect(favorite.isFavorite('lebron'), isTrue);
    });
  });
}
