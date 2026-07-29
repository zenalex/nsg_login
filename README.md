# nsg_login

Визуальные компоненты для авторизации и регистрации пользователей в приложениях NSG. Пакет предоставляет готовые UI компоненты для входа по телефону, email и паролю с поддержкой SMS-верификации.

> ⚠️ Нативные плагины соц-логинов попадают в сборку продукта, даже если соц-вход
> нигде не включён, и могут ронять приложение на чужих результатах activity
> (выбор файла, камера, шаринг). Как это учтено и что проверять при добавлении
> новых соц-логинов — [docs/social-login-native-plugins.md](docs/social-login-native-plugins.md).

## Возможности

- 🔐 **Множественные способы авторизации**: телефон, email, пароль
- 📱 **SMS-верификация**: автоматическая отправка и проверка кодов
- 🎨 **Настраиваемый дизайн**: полная кастомизация цветов, размеров и текстов
- 🔒 **Валидация паролей**: встроенная проверка сложности паролей
- 💾 **Запоминание пользователя**: автоматическое сохранение токенов
- 🌐 **Поддержка капчи**: защита от ботов
- 📱 **Адаптивный дизайн**: поддержка различных размеров экранов

## Установка

Добавьте зависимость в ваш `pubspec.yaml`:

```yaml
dependencies:
  nsg_login: ^1.0.0-beta.1
```

## Быстрый старт

### 1. Импорт пакета

```dart
import 'package:nsg_login/nsg_login.dart';
```

### 2. Базовая настройка

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NsgLoginPage(
        provider, // Ваш NsgDataProvider
        widgetParams: () => NsgLoginParams(
          headerMessage: 'Моё приложение',
          usePhoneLogin: true,
          useEmailLogin: true,
          usePasswordLogin: true,
        ),
      ),
    );
  }
}
```

## Использование

### Основная страница входа

```dart
NsgLoginPage(
  provider,
  widgetParams: () => NsgLoginParams(
    // Основные настройки
    headerMessage: 'Добро пожаловать',
    usePhoneLogin: true,
    useEmailLogin: true,
    usePasswordLogin: true,
    
    // Кастомизация текстов
    textEnter: 'Войти',
    textRegistration: 'Регистрация',
    textRememberUser: 'Запомнить меня',
    
    // Цветовая схема
    cardColor: Colors.white,
    textColor: Colors.black,
    fillColor: Colors.blue,
    
    // Callback функции
    loginSuccessful: (context, parameter) {
      // Действие при успешном входе
      Navigator.pushReplacementNamed(context, '/home');
    },
    eventLoginWidgweClosed: (isLoginSuccessful) {
      // Действие при закрытии окна входа
      print('Login widget closed. Success: $isLoginSuccessful');
    },
  ),
)
```

### Настройка валидации паролей

```dart
NsgLoginParams(
  passwordValidator: (password) {
    if (password == null || password.length < 8) {
      return 'Пароль должен содержать минимум 8 символов';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Пароль должен содержать заглавную букву';
    }
    return null; // Пароль валиден
  },
  passwordIndicator: (password) {
    // Возвращает PasswordStrength из nsg_data
    if (password.length < 6) return PasswordStrength.weak;
    if (password.length < 10) return PasswordStrength.medium;
    return PasswordStrength.strong;
  },
)
```

### Настройка обработки ошибок

```dart
NsgLoginParams(
  errorMessageByStatusCode: (statusCode) {
    switch (statusCode) {
      case 40101:
        return 'Необходимо получить капчу';
      case 40300:
        return 'Неверный код подтверждения';
      case 40304:
        return 'Неверный логин или пароль';
      default:
        return 'Произошла ошибка: $statusCode';
    }
  },
)
```

## Параметры конфигурации

### Основные параметры

| Параметр | Тип | Описание |
|----------|-----|----------|
| `headerMessage` | String | Заголовок страницы входа |
| `usePhoneLogin` | bool | Разрешить вход по телефону |
| `useEmailLogin` | bool | Разрешить вход по email |
| `usePasswordLogin` | bool | Разрешить вход по паролю |
| `useCaptcha` | bool | Использовать капчу |

### Параметры дизайна

| Параметр | Тип | Описание |
|----------|-----|----------|
| `cardSize` | double | Размер карточки (по умолчанию: 345.0) |
| `iconSize` | double | Размер иконок (по умолчанию: 28.0) |
| `buttonSize` | double | Размер кнопок (по умолчанию: 42.0) |
| `cardColor` | Color | Цвет карточки |
| `textColor` | Color | Цвет текста |
| `fillColor` | Color | Цвет заполнения |

### Callback функции

| Параметр | Тип | Описание |
|----------|-----|----------|
| `loginSuccessful` | Function | Вызывается при успешном входе |
| `loginFailed` | Function | Вызывается при неудачном входе |
| `eventLoginWidgweClosed` | Function | Вызывается при закрытии окна входа |
| `onClose` | VoidCallback | Вызывается при закрытии окна |

## Зависимости

Пакет использует следующие зависимости:

- `nsg_data: ^1.0.0` - Основная библиотека данных NSG
- `nsg_controls: ^1.0.0-beta.1` - UI компоненты NSG
- `get: ^5.0.0-beta.52` - State management
- `hovering: ^1.0.4` - Эффекты наведения
- `flutter_multi_formatter: ^2.13.7` - Форматирование полей ввода
- `shared_preferences: ^2.0.6` - Локальное хранение данных

## Примеры

Полные примеры использования доступны в папке `/example` (если создана).

### Простой пример входа по телефону

```dart
NsgLoginPage(
  provider,
  widgetParams: () => NsgLoginParams(
    headerMessage: 'Вход в систему',
    usePhoneLogin: true,
    useEmailLogin: false,
    usePasswordLogin: false,
    textEnterPhone: 'Введите номер телефона',
    textSendSms: 'Отправить код',
    loginSuccessful: (context, parameter) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Успешный вход!')),
      );
    },
  ),
)
```

## Поддержка

- **GitHub**: [https://github.com/zenalex/nsg_login](https://github.com/zenalex/nsg_login)
- **Issues**: Создавайте issues на GitHub для сообщений об ошибках и предложений

## Лицензия

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для деталей.

## Версии

Текущая версия: `1.0.0-beta.1`

Для информации об изменениях между версиями см. [CHANGELOG.md](CHANGELOG.md).
