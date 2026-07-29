# Соц-логины: нативные плагины и результаты activity

Короткая, но важная тема: **нативный плагин соц-логина попадает в сборку
продукта, даже если этот вход нигде не включён**. Соц-логины гасятся на уровне
UI (`NsgLoginParams.socialLoginTypes`), а нативная часть регистрируется всегда.

## Грабли, которые это уже стоило

Titan LK: вход только по телефону, `socialLoginTypes` пуст, VK нигде не
используется. Тестер жалуется: **«при попытке прикрепить файл — сбой и вылет
из приложения»**. Стек:

```
Failure delivering result … data=content://…/document/image:35889
  → FlutterActivity.onActivityResult
  → ru.innim.flutter_login_vk.ActivityListener.onActivityResult
  → com.vk.api.sdk.VK.onActivityResult
  → kotlin.UninitializedPropertyAccessException:
       lateinit property authManager has not been initialized
```

Что произошло:

1. Android возвращает результат выбора файла в `MainActivity.onActivityResult`.
2. Flutter раздаёт этот результат **всем** зарегистрированным плагинам.
3. `ActivityListener` из pub-версии `flutter_login_vk` вызывает
   `VK.onActivityResult(...)` **безусловно** — не проверяя ни свой ли это
   `requestCode`, ни инициализирован ли VK SDK.
4. `VK.initialize()` вызывается только внутри VK-входа
   (`vk_default_login.dart` → `initSdk()`), то есть в продукте без VK —
   никогда. `authManager` (lateinit) не инициализирован → нативный краш.

Итог: **любой** выбор файла/фото роняет приложение. В Titan LK это вскрылось,
когда появился чат поддержки с вложениями, но причина была бы та же у любой
функции с выбором файла.

## Как это решено в nsg_login

`flutter_login_vk` подключён **не с pub, а пропатченным форком**, вендоренным
в сам `nsg_login`:

```yaml
flutter_login_vk:
  path: packages/flutter_login_vk
```

Патч в `ActivityListener.kt`:

```kotlin
override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (!loginCallback.hasPendingResult()) {
        return false          // VK-логина не ждём — чужой результат не трогаем
    }
    return try {
        VK.onActivityResult(requestCode, resultCode, data, loginCallback)
    } catch (_: UninitializedPropertyAccessException) {
        false                 // SDK не инициализирован — не роняем приложение
    }
}
```

### Почему путём, а не `dependency_overrides`

**`dependency_overrides` работают только в корневом пакете приложения.**
Из библиотеки закрыть проблему override-ом невозможно: он был бы обязателен
в каждом продукте, и о нём пришлось бы помнить. Зависимость путём внутри
`nsg_login` получают все потребители автоматически — в приложении не нужно
ни строчки.

Проверка, что всё подхватилось (в приложении, после `flutter pub get`):

```
flutter_login_vk:
  dependency: transitive
  description:
    path: "../nsg_login/packages/flutter_login_vk"
  source: path
```

Если вместо этого видите `source: hosted` — форк не применился, краш вернётся.

### Почему нельзя было просто «инициализировать VK на старте»

`VKLogin().initSdk()` → `VK.initialize(context)` требует строковый ресурс
`com_vk_sdk_AppId`. В продукте без VK его нет, а заводить фиктивный ради
инициализации неиспользуемого SDK — хуже, чем починить плагин.

## Правило на будущее

Добавляя в `nsg_login` любой соц-логин с нативным плагином, проверьте, что его
`ActivityResultListener` / `onNewIntent`:

1. **не трогает чужие `requestCode`** (возвращает `false`, если результат не его);
2. **не падает, если его SDK не инициализирован** — в продукте без этого входа
   инициализации не будет никогда.

Если плагин этого не гарантирует — вендорьте пропатченную копию в
`packages/` и подключайте путём, как сделано с VK. Иначе мина сработает
у первого же продукта, который добавит выбор файла, камеру или шаринг.

## Если продукту VK не нужен вовсе

Сейчас плагин приходит всем потребителям `nsg_login`. Более чистое решение —
вынести VK (и другие соц-логины) в отдельные опциональные пакеты
(`nsg_login_vk` и т.п.), чтобы продукты без соц-входов не тащили нативный код.
Это требует API регистрации типов входа и изменений в продуктах, которые VK
используют, — пока не сделано.
