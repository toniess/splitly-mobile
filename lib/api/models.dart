// Модели повторяют record-ы бэкенда и типы веб-клиента.
//
// Деньги везде строки: "300.33", а не double. Арифметика остаётся на
// сервере, клиент только показывает и пересылает значения как есть.

class TokenPair {
  final String accessToken;
  final String refreshToken;

  const TokenPair({required this.accessToken, required this.refreshToken});

  factory TokenPair.fromJson(Map<String, dynamic> json) =>
      TokenPair(accessToken: json['accessToken'] as String, refreshToken: json['refreshToken'] as String);
}

class User {
  final String id;
  final String email;
  final String displayName;

  const User({required this.id, required this.email, required this.displayName});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String,
  );
}

class GroupSummary {
  final String id;
  final String name;
  final String currency;

  const GroupSummary({required this.id, required this.name, required this.currency});

  factory GroupSummary.fromJson(Map<String, dynamic> json) => GroupSummary(
    id: json['id'] as String,
    name: json['name'] as String,
    currency: json['currency'] as String,
  );
}

class Group extends GroupSummary {
  final String inviteCode;

  const Group({required super.id, required super.name, required super.currency, required this.inviteCode});

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'] as String,
    name: json['name'] as String,
    currency: json['currency'] as String,
    inviteCode: json['inviteCode'] as String,
  );
}

enum MemberRole { owner, member }

class GroupMember {
  final String userId;
  final String displayName;
  final MemberRole role;

  const GroupMember({required this.userId, required this.displayName, required this.role});

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String,
    role: json['role'] == 'OWNER' ? MemberRole.owner : MemberRole.member,
  );
}

enum SplitType {
  equal('EQUAL'),
  shares('SHARES'),
  exact('EXACT');

  final String wire;

  const SplitType(this.wire);

  static SplitType parse(String value) =>
      SplitType.values.firstWhere((t) => t.wire == value, orElse: () => SplitType.equal);
}

class ExpenseSummary {
  final String id;
  final String description;
  final String amount;
  final String payerId;
  final DateTime spentAt;

  const ExpenseSummary({
    required this.id,
    required this.description,
    required this.amount,
    required this.payerId,
    required this.spentAt,
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) => ExpenseSummary(
    id: json['id'] as String,
    description: json['description'] as String,
    amount: json['amount'].toString(),
    payerId: json['payerId'] as String,
    spentAt: DateTime.parse(json['spentAt'] as String),
  );
}

class ExpenseFeedPage {
  final List<ExpenseSummary> items;
  final String? nextCursor;

  const ExpenseFeedPage({required this.items, this.nextCursor});

  factory ExpenseFeedPage.fromJson(Map<String, dynamic> json) => ExpenseFeedPage(
    items: (json['items'] as List).map((e) => ExpenseSummary.fromJson(e as Map<String, dynamic>)).toList(),
    nextCursor: json['nextCursor'] as String?,
  );
}

class Share {
  final String userId;
  final String displayName;
  final String amount;

  const Share({required this.userId, required this.displayName, required this.amount});

  factory Share.fromJson(Map<String, dynamic> json) => Share(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String,
    amount: json['amount'].toString(),
  );
}

class Expense {
  final String id;
  final String groupId;
  final String payerId;
  final String amount;
  final String currency;
  final String description;
  final DateTime spentAt;
  final SplitType splitType;
  final List<Share> shares;

  const Expense({
    required this.id,
    required this.groupId,
    required this.payerId,
    required this.amount,
    required this.currency,
    required this.description,
    required this.spentAt,
    required this.splitType,
    required this.shares,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    groupId: json['groupId'] as String,
    payerId: json['payerId'] as String,
    amount: json['amount'].toString(),
    currency: json['currency'] as String,
    description: json['description'] as String,
    spentAt: DateTime.parse(json['spentAt'] as String),
    splitType: SplitType.parse(json['splitType'] as String),
    shares: (json['shares'] as List).map((e) => Share.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

/// Участник траты в запросе на создание. При равном делении [value] пустой:
/// доли считает сервер.
class Participant {
  final String userId;
  final String? value;

  const Participant(this.userId, this.value);

  Map<String, dynamic> toJson() => {'userId': userId, 'value': value};
}

class NewExpense {
  final String description;
  final String amount;
  final String payerId;
  final DateTime spentAt;
  final SplitType splitType;
  final List<Participant> participants;

  const NewExpense({
    required this.description,
    required this.amount,
    required this.payerId,
    required this.spentAt,
    required this.splitType,
    required this.participants,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'amount': amount,
    'payerId': payerId,
    'spentAt': spentAt.toUtc().toIso8601String(),
    'splitType': splitType.wire,
    'participants': participants.map((p) => p.toJson()).toList(),
  };
}

class Balance {
  final String userId;
  final String displayName;
  final String balance;

  const Balance({required this.userId, required this.displayName, required this.balance});

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String,
    balance: json['balance'].toString(),
  );
}

class Transfer {
  final String from;
  final String to;
  final String amount;

  const Transfer({required this.from, required this.to, required this.amount});

  factory Transfer.fromJson(Map<String, dynamic> json) =>
      Transfer(from: json['from'] as String, to: json['to'] as String, amount: json['amount'].toString());
}
