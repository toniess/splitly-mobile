import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('ru')];

  /// No description provided for @appTagline.
  ///
  /// In ru, this message translates to:
  /// **'Делим счёт и считаем, кто кому должен'**
  String get appTagline;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @you.
  ///
  /// In ru, this message translates to:
  /// **'Вы'**
  String get you;

  /// No description provided for @youSuffix.
  ///
  /// In ru, this message translates to:
  /// **' (вы)'**
  String get youSuffix;

  /// No description provided for @nameWithYou.
  ///
  /// In ru, this message translates to:
  /// **'{name} (вы)'**
  String nameWithYou(String name);

  /// No description provided for @authName.
  ///
  /// In ru, this message translates to:
  /// **'Как вас зовут'**
  String get authName;

  /// No description provided for @authNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите имя'**
  String get authNameRequired;

  /// No description provided for @authEmail.
  ///
  /// In ru, this message translates to:
  /// **'Почта'**
  String get authEmail;

  /// No description provided for @authEmailInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Нужна почта'**
  String get authEmailInvalid;

  /// No description provided for @authPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get authPassword;

  /// No description provided for @authPasswordShort.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 8 символов'**
  String get authPasswordShort;

  /// No description provided for @authSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get authSignUp;

  /// No description provided for @authOr.
  ///
  /// In ru, this message translates to:
  /// **'или'**
  String get authOr;

  /// No description provided for @authDemo.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть демо без регистрации'**
  String get authDemo;

  /// No description provided for @authToSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть аккаунт? Войти'**
  String get authToSignIn;

  /// No description provided for @authToSignUp.
  ///
  /// In ru, this message translates to:
  /// **'Ещё нет аккаунта? Создать'**
  String get authToSignUp;

  /// No description provided for @groupsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Группы'**
  String get groupsTitle;

  /// No description provided for @groupsLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get groupsLogout;

  /// No description provided for @groupsLogoutDemo.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из демо'**
  String get groupsLogoutDemo;

  /// No description provided for @privacyPolicy.
  ///
  /// In ru, this message translates to:
  /// **'Политика конфиденциальности'**
  String get privacyPolicy;

  /// No description provided for @accountDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get accountDelete;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт?'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteText.
  ///
  /// In ru, this message translates to:
  /// **'Удаление выполняется по запросу: мы удалим аккаунт, почту и имя в течение 30 дней. Записи о тратах в общих группах обезличим — они нужны для балансов других участников.\n\nСейчас откроется письмо на {email} — просто отправьте его.'**
  String accountDeleteText(String email);

  /// No description provided for @accountDeleteWrite.
  ///
  /// In ru, this message translates to:
  /// **'Написать письмо'**
  String get accountDeleteWrite;

  /// No description provided for @accountDeleteSubject.
  ///
  /// In ru, this message translates to:
  /// **'Удаление аккаунта Splitly'**
  String get accountDeleteSubject;

  /// No description provided for @accountDeleteBody.
  ///
  /// In ru, this message translates to:
  /// **'Прошу удалить мой аккаунт Splitly.\n\nПочта: {email}\nID: {id}'**
  String accountDeleteBody(String email, String id);

  /// No description provided for @groupsNew.
  ///
  /// In ru, this message translates to:
  /// **'Новая группа'**
  String get groupsNew;

  /// No description provided for @groupsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока ни одной группы.\nСоздайте свою или вступите по коду.'**
  String get groupsEmpty;

  /// No description provided for @groupsJoinByCode.
  ///
  /// In ru, this message translates to:
  /// **'Вступить по коду приглашения'**
  String get groupsJoinByCode;

  /// No description provided for @demoBanner.
  ///
  /// In ru, this message translates to:
  /// **'Демо-режим: данные живут в памяти и исчезнут при выходе, сервер не используется. Чтобы поработать с настоящим API — зарегистрируйтесь.'**
  String get demoBanner;

  /// No description provided for @groupName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get groupName;

  /// No description provided for @groupNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Поездка в Самарканд'**
  String get groupNameHint;

  /// No description provided for @groupCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get groupCreate;

  /// No description provided for @groupJoinTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вступить в группу'**
  String get groupJoinTitle;

  /// No description provided for @groupInviteCode.
  ///
  /// In ru, this message translates to:
  /// **'Код приглашения'**
  String get groupInviteCode;

  /// No description provided for @groupJoin.
  ///
  /// In ru, this message translates to:
  /// **'Вступить'**
  String get groupJoin;

  /// No description provided for @groupMembers.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} участник} few{{count} участника} other{{count} участников}}'**
  String groupMembers(int count);

  /// No description provided for @groupInviteCopied.
  ///
  /// In ru, this message translates to:
  /// **'Код {code} скопирован — отправьте его тем, кого зовёте'**
  String groupInviteCopied(String code);

  /// No description provided for @groupLeave.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из группы'**
  String get groupLeave;

  /// No description provided for @groupLeaveConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из группы?'**
  String get groupLeaveConfirm;

  /// No description provided for @groupLeaveHint.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не отпустит, пока у вас ненулевой баланс в этой группе.'**
  String get groupLeaveHint;

  /// No description provided for @groupLeaveAction.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get groupLeaveAction;

  /// No description provided for @tabExpenses.
  ///
  /// In ru, this message translates to:
  /// **'Траты'**
  String get tabExpenses;

  /// No description provided for @tabBalances.
  ///
  /// In ru, this message translates to:
  /// **'Балансы'**
  String get tabBalances;

  /// No description provided for @tabSettle.
  ///
  /// In ru, this message translates to:
  /// **'Расчёт'**
  String get tabSettle;

  /// No description provided for @expensesAdd.
  ///
  /// In ru, this message translates to:
  /// **'Трата'**
  String get expensesAdd;

  /// No description provided for @expensesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Трат пока нет.\nДобавьте первую кнопкой внизу.'**
  String get expensesEmpty;

  /// No description provided for @expensesMore.
  ///
  /// In ru, this message translates to:
  /// **'Показать ещё'**
  String get expensesMore;

  /// No description provided for @balancesHint.
  ///
  /// In ru, this message translates to:
  /// **'Плюс — должны вам, минус — должны вы. Сумма всегда равна нулю.'**
  String get balancesHint;

  /// No description provided for @balancesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нечего считать'**
  String get balancesEmpty;

  /// No description provided for @settleHint.
  ///
  /// In ru, this message translates to:
  /// **'Минимальный набор переводов. Отметить перевод может только тот, кто отдаёт деньги.'**
  String get settleHint;

  /// No description provided for @settleEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Все в расчёте 🎉'**
  String get settleEmpty;

  /// No description provided for @settleToYou.
  ///
  /// In ru, this message translates to:
  /// **'вам'**
  String get settleToYou;

  /// No description provided for @settlePaid.
  ///
  /// In ru, this message translates to:
  /// **'Я отдал'**
  String get settlePaid;

  /// No description provided for @settleConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Отметить перевод?'**
  String get settleConfirm;

  /// No description provided for @settleConfirmText.
  ///
  /// In ru, this message translates to:
  /// **'Вы отдали {name} {amount}. Это изменит балансы всей группы.'**
  String settleConfirmText(String name, String amount);

  /// No description provided for @settleConfirmAction.
  ///
  /// In ru, this message translates to:
  /// **'Да, отдал'**
  String get settleConfirmAction;

  /// No description provided for @expenseTitle.
  ///
  /// In ru, this message translates to:
  /// **'Трата'**
  String get expenseTitle;

  /// No description provided for @expenseDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get expenseDelete;

  /// No description provided for @expenseDeleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить трату?'**
  String get expenseDeleteConfirm;

  /// No description provided for @expenseDeleteHint.
  ///
  /// In ru, this message translates to:
  /// **'Балансы группы пересчитаются.'**
  String get expenseDeleteHint;

  /// No description provided for @expensePaidBy.
  ///
  /// In ru, this message translates to:
  /// **'Платил(а) {name} · {date}'**
  String expensePaidBy(String name, String date);

  /// No description provided for @expenseShares.
  ///
  /// In ru, this message translates to:
  /// **'Доли · {split}'**
  String expenseShares(String split);

  /// No description provided for @splitEqual.
  ///
  /// In ru, this message translates to:
  /// **'поровну'**
  String get splitEqual;

  /// No description provided for @splitShares.
  ///
  /// In ru, this message translates to:
  /// **'по долям'**
  String get splitShares;

  /// No description provided for @splitExact.
  ///
  /// In ru, this message translates to:
  /// **'точными суммами'**
  String get splitExact;

  /// No description provided for @splitEqualShort.
  ///
  /// In ru, this message translates to:
  /// **'Поровну'**
  String get splitEqualShort;

  /// No description provided for @splitSharesShort.
  ///
  /// In ru, this message translates to:
  /// **'Доли'**
  String get splitSharesShort;

  /// No description provided for @splitExactShort.
  ///
  /// In ru, this message translates to:
  /// **'Суммы'**
  String get splitExactShort;

  /// No description provided for @formTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новая трата'**
  String get formTitle;

  /// No description provided for @formWhat.
  ///
  /// In ru, this message translates to:
  /// **'На что'**
  String get formWhat;

  /// No description provided for @formWhatHint.
  ///
  /// In ru, this message translates to:
  /// **'Такси до аэропорта'**
  String get formWhatHint;

  /// No description provided for @formWhatRequired.
  ///
  /// In ru, this message translates to:
  /// **'Опишите трату'**
  String get formWhatRequired;

  /// No description provided for @formAmount.
  ///
  /// In ru, this message translates to:
  /// **'Сколько'**
  String get formAmount;

  /// No description provided for @formAmountInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Например, 300.50'**
  String get formAmountInvalid;

  /// No description provided for @formAmountPositive.
  ///
  /// In ru, this message translates to:
  /// **'Больше нуля'**
  String get formAmountPositive;

  /// No description provided for @formWhen.
  ///
  /// In ru, this message translates to:
  /// **'Когда'**
  String get formWhen;

  /// No description provided for @formToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get formToday;

  /// No description provided for @formPayer.
  ///
  /// In ru, this message translates to:
  /// **'Кто платил'**
  String get formPayer;

  /// No description provided for @formBetween.
  ///
  /// In ru, this message translates to:
  /// **'Между кем'**
  String get formBetween;

  /// No description provided for @formBetweenShares.
  ///
  /// In ru, this message translates to:
  /// **'Между кем · доли'**
  String get formBetweenShares;

  /// No description provided for @formBetweenExact.
  ///
  /// In ru, this message translates to:
  /// **'Между кем · суммы'**
  String get formBetweenExact;

  /// No description provided for @formShareInteger.
  ///
  /// In ru, this message translates to:
  /// **'Целое'**
  String get formShareInteger;

  /// No description provided for @formNoParticipants.
  ///
  /// In ru, this message translates to:
  /// **'Выберите хотя бы одного участника'**
  String get formNoParticipants;

  /// No description provided for @formZeroShares.
  ///
  /// In ru, this message translates to:
  /// **'Хотя бы у одного участника доля должна быть больше нуля'**
  String get formZeroShares;

  /// No description provided for @formExactDone.
  ///
  /// In ru, this message translates to:
  /// **'Распределено полностью'**
  String get formExactDone;

  /// No description provided for @formExactLeft.
  ///
  /// In ru, this message translates to:
  /// **'Осталось распределить {amount}'**
  String formExactLeft(String amount);

  /// No description provided for @formExactOver.
  ///
  /// In ru, this message translates to:
  /// **'Перебор на {amount}'**
  String formExactOver(String amount);

  /// No description provided for @errorOffline.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи с сервером'**
  String get errorOffline;

  /// No description provided for @errorTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не ответил вовремя'**
  String get errorTimeout;

  /// No description provided for @errorNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сервера ({status})'**
  String errorServer(int status);

  /// No description provided for @demoGroup.
  ///
  /// In ru, this message translates to:
  /// **'Поездка в Самарканд'**
  String get demoGroup;

  /// No description provided for @demoMe.
  ///
  /// In ru, this message translates to:
  /// **'Тимур'**
  String get demoMe;

  /// No description provided for @demoMaria.
  ///
  /// In ru, this message translates to:
  /// **'Мария'**
  String get demoMaria;

  /// No description provided for @demoIgor.
  ///
  /// In ru, this message translates to:
  /// **'Игорь'**
  String get demoIgor;

  /// No description provided for @demoHotel.
  ///
  /// In ru, this message translates to:
  /// **'Отель, две ночи'**
  String get demoHotel;

  /// No description provided for @demoDinner.
  ///
  /// In ru, this message translates to:
  /// **'Ужин в чайхане'**
  String get demoDinner;

  /// No description provided for @demoTaxi.
  ///
  /// In ru, this message translates to:
  /// **'Такси до Регистана'**
  String get demoTaxi;

  /// No description provided for @demoOneGroup.
  ///
  /// In ru, this message translates to:
  /// **'В демо доступна только одна группа'**
  String get demoOneGroup;

  /// No description provided for @demoNoJoin.
  ///
  /// In ru, this message translates to:
  /// **'В демо нельзя вступать в другие группы'**
  String get demoNoJoin;

  /// No description provided for @demoNoLeave.
  ///
  /// In ru, this message translates to:
  /// **'Из демо-группы не уйти — это песочница'**
  String get demoNoLeave;

  /// No description provided for @demoNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Трата не найдена'**
  String get demoNotFound;

  /// No description provided for @demoNoParticipants.
  ///
  /// In ru, this message translates to:
  /// **'Нужен хотя бы один участник'**
  String get demoNoParticipants;

  /// No description provided for @demoAmountPositive.
  ///
  /// In ru, this message translates to:
  /// **'Сумма должна быть больше нуля'**
  String get demoAmountPositive;

  /// No description provided for @demoSharesPositive.
  ///
  /// In ru, this message translates to:
  /// **'Доли должны быть положительными'**
  String get demoSharesPositive;

  /// No description provided for @demoSumMismatch.
  ///
  /// In ru, this message translates to:
  /// **'Сумма долей не равна сумме траты'**
  String get demoSumMismatch;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
