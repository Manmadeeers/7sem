enum UserRole {
  customer('Customer'),
  manager('Manager'),
  admin('Administrator');

  const UserRole(this.label);

  final String label;

  bool get canManageProducts => this == manager || this == admin;
}

class ShopUser {
  const ShopUser({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final UserRole role;

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'role': role.name};

  factory ShopUser.fromMap(Map<dynamic, dynamic> map) {
    return ShopUser(
      id: map['id'] as String,
      name: map['name'] as String,
      role: UserRole.values.byName(map['role'] as String),
    );
  }
}

const seededUsers = <ShopUser>[
  ShopUser(id: 'anna', name: 'Anna', role: UserRole.customer),
  ShopUser(id: 'max', name: 'Max', role: UserRole.manager),
  ShopUser(id: 'root', name: 'Admin', role: UserRole.admin),
];
