/// Куда пользователю обращаться — тот же адрес указан в политике
/// конфиденциальности и на странице приложения в Google Play.
const supportEmail = 'contact@toniess.dev';

/// Как удалить аккаунт. Google Play требует такую страницу вне приложения:
/// удалить аккаунт должен суметь и тот, кто приложение уже снёс.
final deleteAccountUrl = Uri.parse(
  'https://github.com/toniess/splitly-mobile/blob/main/docs/delete-account.md',
);

final privacyPolicyUrl = Uri.parse('https://github.com/toniess/splitly-mobile/blob/main/docs/privacy.md');
