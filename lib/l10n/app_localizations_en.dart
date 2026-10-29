// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Split the bill and see who owes whom';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Save';

  @override
  String get you => 'You';

  @override
  String get youSuffix => ' (you)';

  @override
  String nameWithYou(String name) {
    return '$name (you)';
  }

  @override
  String get authName => 'Your name';

  @override
  String get authNameRequired => 'Enter your name';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordShort => 'At least 8 characters';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authOr => 'or';

  @override
  String get authDemo => 'Try the demo without signing up';

  @override
  String get authToSignIn => 'Already have an account? Sign in';

  @override
  String get authToSignUp => 'No account yet? Create one';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get groupsLogout => 'Sign out';

  @override
  String get groupsLogoutDemo => 'Leave demo';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteTitle => 'Delete your account?';

  @override
  String accountDeleteText(String email) {
    return 'Deletion is done on request: we delete your account, email and name within 30 days. Expense records in shared groups are anonymized — other members\' balances depend on them.\n\nAn email to $email will open next — just send it.';
  }

  @override
  String get accountDeleteWrite => 'Write email';

  @override
  String get accountDeleteSubject => 'Splitly account deletion';

  @override
  String accountDeleteBody(String email, String id) {
    return 'Please delete my Splitly account.\n\nEmail: $email\nID: $id';
  }

  @override
  String get groupsNew => 'New group';

  @override
  String get groupsEmpty => 'No groups yet.\nCreate one or join with an invite code.';

  @override
  String get groupsJoinByCode => 'Join with an invite code';

  @override
  String get demoBanner =>
      'Demo mode: data lives in memory and disappears when you leave; the server isn\'t used. Sign up to work with the real API.';

  @override
  String get groupName => 'Name';

  @override
  String get groupNameHint => 'Trip to Samarkand';

  @override
  String get groupCreate => 'Create';

  @override
  String get groupJoinTitle => 'Join a group';

  @override
  String get groupInviteCode => 'Invite code';

  @override
  String get groupJoin => 'Join';

  @override
  String groupMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '$count member',
    );
    return '$_temp0';
  }

  @override
  String groupInviteCopied(String code) {
    return 'Code $code copied — send it to the people you\'re inviting';
  }

  @override
  String get groupLeave => 'Leave group';

  @override
  String get groupLeaveConfirm => 'Leave the group?';

  @override
  String get groupLeaveHint =>
      'The server won\'t let you leave while your balance in this group isn\'t zero.';

  @override
  String get groupLeaveAction => 'Leave';

  @override
  String get tabExpenses => 'Expenses';

  @override
  String get tabBalances => 'Balances';

  @override
  String get tabSettle => 'Settle up';

  @override
  String get expensesAdd => 'Expense';

  @override
  String get expensesEmpty => 'No expenses yet.\nAdd the first one with the button below.';

  @override
  String get expensesMore => 'Show more';

  @override
  String get balancesHint => 'Plus means you\'re owed, minus means you owe. The total is always zero.';

  @override
  String get balancesEmpty => 'Nothing to settle yet';

  @override
  String get settleHint => 'The fewest transfers needed. Only the person paying can mark a transfer as done.';

  @override
  String get settleEmpty => 'All settled up 🎉';

  @override
  String get settleToYou => 'you';

  @override
  String get settlePaid => 'I paid';

  @override
  String get settleConfirm => 'Mark as paid?';

  @override
  String settleConfirmText(String name, String amount) {
    return 'You paid $name $amount. This changes the balances of the whole group.';
  }

  @override
  String get settleConfirmAction => 'Yes, I paid';

  @override
  String get expenseTitle => 'Expense';

  @override
  String get expenseDelete => 'Delete';

  @override
  String get expenseDeleteConfirm => 'Delete the expense?';

  @override
  String get expenseDeleteHint => 'Group balances will be recalculated.';

  @override
  String expensePaidBy(String name, String date) {
    return 'Paid by $name · $date';
  }

  @override
  String expenseShares(String split) {
    return 'Shares · $split';
  }

  @override
  String get splitEqual => 'equally';

  @override
  String get splitShares => 'by shares';

  @override
  String get splitExact => 'exact amounts';

  @override
  String get splitEqualShort => 'Equally';

  @override
  String get splitSharesShort => 'Shares';

  @override
  String get splitExactShort => 'Amounts';

  @override
  String get formTitle => 'New expense';

  @override
  String get formWhat => 'What for';

  @override
  String get formWhatHint => 'Taxi to the airport';

  @override
  String get formWhatRequired => 'Describe the expense';

  @override
  String get formAmount => 'Amount';

  @override
  String get formAmountInvalid => 'For example, 300.50';

  @override
  String get formAmountPositive => 'Must be above zero';

  @override
  String get formWhen => 'When';

  @override
  String get formToday => 'Today';

  @override
  String get formPayer => 'Paid by';

  @override
  String get formBetween => 'Split between';

  @override
  String get formBetweenShares => 'Split between · shares';

  @override
  String get formBetweenExact => 'Split between · amounts';

  @override
  String get formShareInteger => 'Whole';

  @override
  String get formNoParticipants => 'Pick at least one participant';

  @override
  String get formZeroShares => 'At least one participant needs a share above zero';

  @override
  String get formExactDone => 'Fully allocated';

  @override
  String formExactLeft(String amount) {
    return '$amount left to allocate';
  }

  @override
  String formExactOver(String amount) {
    return 'Over by $amount';
  }

  @override
  String get errorOffline => 'Can\'t reach the server';

  @override
  String get errorTimeout => 'The server didn\'t respond in time';

  @override
  String get errorNetwork => 'Network error';

  @override
  String errorServer(int status) {
    return 'Server error ($status)';
  }

  @override
  String get demoGroup => 'Trip to Samarkand';

  @override
  String get demoMe => 'Timur';

  @override
  String get demoMaria => 'Maria';

  @override
  String get demoIgor => 'Igor';

  @override
  String get demoHotel => 'Hotel, two nights';

  @override
  String get demoDinner => 'Dinner at the teahouse';

  @override
  String get demoTaxi => 'Taxi to Registan';

  @override
  String get demoOneGroup => 'Only one group is available in the demo';

  @override
  String get demoNoJoin => 'You can\'t join other groups in the demo';

  @override
  String get demoNoLeave => 'You can\'t leave the demo group — it\'s a sandbox';

  @override
  String get demoNotFound => 'Expense not found';

  @override
  String get demoNoParticipants => 'At least one participant is required';

  @override
  String get demoAmountPositive => 'The amount must be above zero';

  @override
  String get demoSharesPositive => 'Shares must be positive';

  @override
  String get demoSumMismatch => 'Shares don\'t add up to the expense amount';
}
