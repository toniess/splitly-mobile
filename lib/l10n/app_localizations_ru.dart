// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTagline => 'Делим счёт и считаем, кто кому должен';

  @override
  String get cancel => 'Отмена';

  @override
  String get retry => 'Повторить';

  @override
  String get save => 'Сохранить';

  @override
  String get you => 'Вы';

  @override
  String get youSuffix => ' (вы)';

  @override
  String nameWithYou(String name) {
    return '$name (вы)';
  }

  @override
  String get authName => 'Как вас зовут';

  @override
  String get authNameRequired => 'Укажите имя';

  @override
  String get authEmail => 'Почта';

  @override
  String get authEmailInvalid => 'Нужна почта';

  @override
  String get authPassword => 'Пароль';

  @override
  String get authPasswordShort => 'Минимум 8 символов';

  @override
  String get authSignIn => 'Войти';

  @override
  String get authSignUp => 'Зарегистрироваться';

  @override
  String get authOr => 'или';

  @override
  String get authDemo => 'Посмотреть демо без регистрации';

  @override
  String get authToSignIn => 'Уже есть аккаунт? Войти';

  @override
  String get authToSignUp => 'Ещё нет аккаунта? Создать';

  @override
  String get groupsTitle => 'Группы';

  @override
  String get groupsLogout => 'Выйти';

  @override
  String get groupsLogoutDemo => 'Выйти из демо';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get accountDelete => 'Удалить аккаунт';

  @override
  String get accountDeleteTitle => 'Удалить аккаунт?';

  @override
  String accountDeleteText(String email) {
    return 'Удаление выполняется по запросу: мы удалим аккаунт, почту и имя в течение 30 дней. Записи о тратах в общих группах обезличим — они нужны для балансов других участников.\n\nСейчас откроется письмо на $email — просто отправьте его.';
  }

  @override
  String get accountDeleteWrite => 'Написать письмо';

  @override
  String get accountDeleteSubject => 'Удаление аккаунта Splitly';

  @override
  String accountDeleteBody(String email, String id) {
    return 'Прошу удалить мой аккаунт Splitly.\n\nПочта: $email\nID: $id';
  }

  @override
  String get groupsNew => 'Новая группа';

  @override
  String get groupsEmpty => 'Пока ни одной группы.\nСоздайте свою или вступите по коду.';

  @override
  String get groupsJoinByCode => 'Вступить по коду приглашения';

  @override
  String get demoBanner =>
      'Демо-режим: данные живут в памяти и исчезнут при выходе, сервер не используется. Чтобы поработать с настоящим API — зарегистрируйтесь.';

  @override
  String get groupName => 'Название';

  @override
  String get groupNameHint => 'Поездка в Самарканд';

  @override
  String get groupCreate => 'Создать';

  @override
  String get groupJoinTitle => 'Вступить в группу';

  @override
  String get groupInviteCode => 'Код приглашения';

  @override
  String get groupJoin => 'Вступить';

  @override
  String groupMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count участников',
      few: '$count участника',
      one: '$count участник',
    );
    return '$_temp0';
  }

  @override
  String groupInviteCopied(String code) {
    return 'Код $code скопирован — отправьте его тем, кого зовёте';
  }

  @override
  String get groupLeave => 'Выйти из группы';

  @override
  String get groupLeaveConfirm => 'Выйти из группы?';

  @override
  String get groupLeaveHint => 'Сервер не отпустит, пока у вас ненулевой баланс в этой группе.';

  @override
  String get groupLeaveAction => 'Выйти';

  @override
  String get tabExpenses => 'Траты';

  @override
  String get tabBalances => 'Балансы';

  @override
  String get tabSettle => 'Расчёт';

  @override
  String get expensesAdd => 'Трата';

  @override
  String get expensesEmpty => 'Трат пока нет.\nДобавьте первую кнопкой внизу.';

  @override
  String get expensesMore => 'Показать ещё';

  @override
  String get balancesHint => 'Плюс — должны вам, минус — должны вы. Сумма всегда равна нулю.';

  @override
  String get balancesEmpty => 'Пока нечего считать';

  @override
  String get settleHint =>
      'Минимальный набор переводов. Отметить перевод может только тот, кто отдаёт деньги.';

  @override
  String get settleEmpty => 'Все в расчёте 🎉';

  @override
  String get settleToYou => 'вам';

  @override
  String get settlePaid => 'Я отдал';

  @override
  String get settleConfirm => 'Отметить перевод?';

  @override
  String settleConfirmText(String name, String amount) {
    return 'Вы отдали $name $amount. Это изменит балансы всей группы.';
  }

  @override
  String get settleConfirmAction => 'Да, отдал';

  @override
  String get expenseTitle => 'Трата';

  @override
  String get expenseDelete => 'Удалить';

  @override
  String get expenseDeleteConfirm => 'Удалить трату?';

  @override
  String get expenseDeleteHint => 'Балансы группы пересчитаются.';

  @override
  String expensePaidBy(String name, String date) {
    return 'Платил(а) $name · $date';
  }

  @override
  String expenseShares(String split) {
    return 'Доли · $split';
  }

  @override
  String get splitEqual => 'поровну';

  @override
  String get splitShares => 'по долям';

  @override
  String get splitExact => 'точными суммами';

  @override
  String get splitEqualShort => 'Поровну';

  @override
  String get splitSharesShort => 'Доли';

  @override
  String get splitExactShort => 'Суммы';

  @override
  String get formTitle => 'Новая трата';

  @override
  String get formWhat => 'На что';

  @override
  String get formWhatHint => 'Такси до аэропорта';

  @override
  String get formWhatRequired => 'Опишите трату';

  @override
  String get formAmount => 'Сколько';

  @override
  String get formAmountInvalid => 'Например, 300.50';

  @override
  String get formAmountPositive => 'Больше нуля';

  @override
  String get formWhen => 'Когда';

  @override
  String get formToday => 'Сегодня';

  @override
  String get formPayer => 'Кто платил';

  @override
  String get formBetween => 'Между кем';

  @override
  String get formBetweenShares => 'Между кем · доли';

  @override
  String get formBetweenExact => 'Между кем · суммы';

  @override
  String get formShareInteger => 'Целое';

  @override
  String get formNoParticipants => 'Выберите хотя бы одного участника';

  @override
  String get formZeroShares => 'Хотя бы у одного участника доля должна быть больше нуля';

  @override
  String get formExactDone => 'Распределено полностью';

  @override
  String formExactLeft(String amount) {
    return 'Осталось распределить $amount';
  }

  @override
  String formExactOver(String amount) {
    return 'Перебор на $amount';
  }

  @override
  String get errorOffline => 'Нет связи с сервером';

  @override
  String get errorTimeout => 'Сервер не ответил вовремя';

  @override
  String get errorNetwork => 'Ошибка сети';

  @override
  String errorServer(int status) {
    return 'Ошибка сервера ($status)';
  }

  @override
  String get demoGroup => 'Поездка в Самарканд';

  @override
  String get demoMe => 'Тимур';

  @override
  String get demoMaria => 'Мария';

  @override
  String get demoIgor => 'Игорь';

  @override
  String get demoHotel => 'Отель, две ночи';

  @override
  String get demoDinner => 'Ужин в чайхане';

  @override
  String get demoTaxi => 'Такси до Регистана';

  @override
  String get demoOneGroup => 'В демо доступна только одна группа';

  @override
  String get demoNoJoin => 'В демо нельзя вступать в другие группы';

  @override
  String get demoNoLeave => 'Из демо-группы не уйти — это песочница';

  @override
  String get demoNotFound => 'Трата не найдена';

  @override
  String get demoNoParticipants => 'Нужен хотя бы один участник';

  @override
  String get demoAmountPositive => 'Сумма должна быть больше нуля';

  @override
  String get demoSharesPositive => 'Доли должны быть положительными';

  @override
  String get demoSumMismatch => 'Сумма долей не равна сумме траты';
}
