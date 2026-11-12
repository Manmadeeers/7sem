import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/product.dart';
import '../models/shop_user.dart';

abstract class ShopStore extends ChangeNotifier {
  List<Product> get products;
  List<ShopUser> get users;
  ShopUser get currentUser;
  String get storageDescription;
  String get keyFingerprint;

  bool isFavorite(String productId);
  Future<void> selectUser(String userId);
  Future<void> toggleFavorite(String productId);
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String productId);
  Future<String> compactBoxes();
  Future<String> demonstrateWrongKey();
}

class MemoryShopStore extends ShopStore {
  MemoryShopStore.seeded()
    : _products = List<Product>.of(catalogProducts),
      _users = List<ShopUser>.of(seededUsers),
      _currentUserId = seededUsers.first.id,
      _favorites = {'anna:lebron'};

  final List<Product> _products;
  final List<ShopUser> _users;
  final Set<String> _favorites;
  String _currentUserId;

  @override
  List<Product> get products => List.unmodifiable(_products);

  @override
  List<ShopUser> get users => List.unmodifiable(_users);

  @override
  ShopUser get currentUser =>
      _users.firstWhere((user) => user.id == _currentUserId);

  @override
  String get storageDescription => 'In-memory test storage';

  @override
  String get keyFingerprint => 'TEST-KEY';

  String _favoriteKey(String productId) => '$_currentUserId:$productId';

  @override
  bool isFavorite(String productId) =>
      _favorites.contains(_favoriteKey(productId));

  @override
  Future<void> selectUser(String userId) async {
    _currentUserId = userId;
    notifyListeners();
  }

  @override
  Future<void> toggleFavorite(String productId) async {
    final key = _favoriteKey(productId);
    if (!_favorites.remove(key)) {
      _favorites.add(key);
    }
    notifyListeners();
  }

  @override
  Future<void> addProduct(Product product) async {
    _checkManagePermission();
    _products.add(product);
    notifyListeners();
  }

  @override
  Future<void> updateProduct(Product product) async {
    _checkManagePermission();
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      _products[index] = product;
      notifyListeners();
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    _checkManagePermission();
    _products.removeWhere((item) => item.id == productId);
    _favorites.removeWhere((key) => key.endsWith(':$productId'));
    notifyListeners();
  }

  @override
  Future<String> compactBoxes() async =>
      'Test storage has no files to compact.';

  @override
  Future<String> demonstrateWrongKey() async =>
      'Access denied: the second key cannot decrypt the box.';

  void _checkManagePermission() {
    if (!currentUser.role.canManageProducts) {
      throw StateError('Only a manager or administrator can change products.');
    }
  }
}

class HiveShopStore extends ShopStore {
  HiveShopStore._({
    required Box<dynamic> productsBox,
    required Box<dynamic> usersBox,
    required Box<dynamic> favoritesBox,
    required Box<dynamic> settingsBox,
    required List<int> encryptionKey,
    required String keyPath,
  }) : _productsBox = productsBox,
       _usersBox = usersBox,
       _favoritesBox = favoritesBox,
       _settingsBox = settingsBox,
       _encryptionKey = encryptionKey,
       _keyPath = keyPath;

  static const _productsName = 'products';
  static const _usersName = 'users';
  static const _favoritesName = 'favorites';
  static const _settingsName = 'settings';

  final Box<dynamic> _productsBox;
  final Box<dynamic> _usersBox;
  final Box<dynamic> _favoritesBox;
  final Box<dynamic> _settingsBox;
  final List<int> _encryptionKey;
  final String _keyPath;

  static Future<HiveShopStore> open() async {
    final appDirectory = await getApplicationSupportDirectory();
    final hiveDirectory = Directory('${appDirectory.path}/hive');
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);

    final keyFile = File('${appDirectory.path}/shoe_shop_hive.key');
    final List<int> encryptionKey;
    if (await keyFile.exists()) {
      encryptionKey = base64Decode(await keyFile.readAsString());
    } else {
      encryptionKey = Hive.generateSecureKey();
      await keyFile.writeAsString(base64Encode(encryptionKey), flush: true);
    }

    final cipher = HiveAesCipher(encryptionKey);
    bool compactWhenUseful(int entries, int deletedEntries) =>
        deletedEntries > 8 && deletedEntries > entries * .25;

    final productsBox = await Hive.openBox<dynamic>(
      _productsName,
      encryptionCipher: cipher,
      compactionStrategy: compactWhenUseful,
    );
    final usersBox = await Hive.openBox<dynamic>(
      _usersName,
      encryptionCipher: cipher,
      compactionStrategy: compactWhenUseful,
    );
    final favoritesBox = await Hive.openBox<dynamic>(
      _favoritesName,
      encryptionCipher: cipher,
      compactionStrategy: compactWhenUseful,
    );
    final settingsBox = await Hive.openBox<dynamic>(
      _settingsName,
      encryptionCipher: cipher,
      compactionStrategy: compactWhenUseful,
    );

    if (productsBox.isEmpty) {
      await productsBox.putAll({
        for (final product in catalogProducts) product.id: product.toMap(),
      });
    }
    if (usersBox.isEmpty) {
      await usersBox.putAll({
        for (final user in seededUsers) user.id: user.toMap(),
      });
    }
    if (!settingsBox.containsKey('currentUserId')) {
      await settingsBox.put('currentUserId', seededUsers.first.id);
    }
    if (favoritesBox.isEmpty) {
      await favoritesBox.put('anna:lebron', {
        'userId': 'anna',
        'productId': 'lebron',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    return HiveShopStore._(
      productsBox: productsBox,
      usersBox: usersBox,
      favoritesBox: favoritesBox,
      settingsBox: settingsBox,
      encryptionKey: encryptionKey,
      keyPath: keyFile.path,
    );
  }

  @override
  List<Product> get products {
    final result = _productsBox.values
        .map((value) => Product.fromMap(value as Map<dynamic, dynamic>))
        .toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  @override
  List<ShopUser> get users => _usersBox.values
      .map((value) => ShopUser.fromMap(value as Map<dynamic, dynamic>))
      .toList();

  @override
  ShopUser get currentUser {
    final id = _settingsBox.get('currentUserId') as String;
    final data = _usersBox.get(id) as Map<dynamic, dynamic>;
    return ShopUser.fromMap(data);
  }

  @override
  String get storageDescription => '4 encrypted Hive boxes; key: $_keyPath';

  @override
  String get keyFingerprint => base64Encode(_encryptionKey).substring(0, 12);

  String _favoriteKey(String productId) => '${currentUser.id}:$productId';

  @override
  bool isFavorite(String productId) =>
      _favoritesBox.containsKey(_favoriteKey(productId));

  @override
  Future<void> selectUser(String userId) async {
    if (!_usersBox.containsKey(userId)) {
      return;
    }
    await _settingsBox.put('currentUserId', userId);
    notifyListeners();
  }

  @override
  Future<void> toggleFavorite(String productId) async {
    final key = _favoriteKey(productId);
    if (_favoritesBox.containsKey(key)) {
      await _favoritesBox.delete(key);
    } else {
      await _favoritesBox.put(key, {
        'userId': currentUser.id,
        'productId': productId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    notifyListeners();
  }

  void _checkManagePermission() {
    if (!currentUser.role.canManageProducts) {
      throw StateError('Only a manager or administrator can change products.');
    }
  }

  @override
  Future<void> addProduct(Product product) async {
    _checkManagePermission();
    await _productsBox.put(product.id, product.toMap());
    notifyListeners();
  }

  @override
  Future<void> updateProduct(Product product) async {
    _checkManagePermission();
    await _productsBox.put(product.id, product.toMap());
    notifyListeners();
  }

  @override
  Future<void> deleteProduct(String productId) async {
    _checkManagePermission();
    await _productsBox.delete(productId);
    final relatedKeys = _favoritesBox.keys
        .where((key) => key.toString().endsWith(':$productId'))
        .toList();
    await _favoritesBox.deleteAll(relatedKeys);
    notifyListeners();
  }

  int _fileSize(Box<dynamic> box) {
    final path = box.path;
    if (path == null) {
      return 0;
    }
    final file = File(path);
    return file.existsSync() ? file.lengthSync() : 0;
  }

  @override
  Future<String> compactBoxes() async {
    final boxes = [_productsBox, _usersBox, _favoritesBox, _settingsBox];
    final before = boxes.fold<int>(0, (sum, box) => sum + _fileSize(box));
    for (final box in boxes) {
      await box.compact();
    }
    final after = boxes.fold<int>(0, (sum, box) => sum + _fileSize(box));
    return 'Compaction completed: $before → $after bytes. '
        'Deleted records were removed from all four boxes.';
  }

  @override
  Future<String> demonstrateWrongKey() async {
    const demoBoxName = 'wrong_key_demo';
    if (Hive.isBoxOpen(demoBoxName)) {
      await Hive.box<dynamic>(demoBoxName).close();
    }
    if (await Hive.boxExists(demoBoxName)) {
      await Hive.deleteBoxFromDisk(demoBoxName);
    }

    final demoBox = await Hive.openBox<dynamic>(
      demoBoxName,
      encryptionCipher: HiveAesCipher(_encryptionKey),
    );
    await demoBox.put('message', 'Encrypted shoe shop data');
    await demoBox.close();

    final wrongKey = Hive.generateSecureKey();
    try {
      final wrongBox = await Hive.openBox<dynamic>(
        demoBoxName,
        encryptionCipher: HiveAesCipher(wrongKey),
      );
      final value = wrongBox.get('message');
      await wrongBox.close();
      return 'Unexpected result: wrong key read $value.';
    } on HiveError catch (error) {
      return 'Access denied as expected: ${error.message}';
    } finally {
      if (Hive.isBoxOpen(demoBoxName)) {
        await Hive.box<dynamic>(demoBoxName).close();
      }
      if (await Hive.boxExists(demoBoxName)) {
        await Hive.deleteBoxFromDisk(demoBoxName);
      }
    }
  }
}
