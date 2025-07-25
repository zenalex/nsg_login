# Changelog

Все значимые изменения в этом проекте будут документированы в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/),
и этот проект придерживается [Semantic Versioning](https://semver.org/lang/ru/).

## [1.0.0-beta.1] - 2024-12-19

### Добавлено
- Перенос визуальных компонентов авторизации из nsg_data
- Поддержка входа по телефону с SMS-верификацией
- Поддержка входа по email
- Поддержка входа по паролю
- Система валидации паролей с индикатором сложности
- Настраиваемые тексты и сообщения
- Кастомизируемый дизайн (цвета, размеры, стили)
- Поддержка капчи для защиты от ботов
- Функция "Запомнить пользователя"
- Callback функции для обработки событий входа
- Адаптивный дизайн для различных размеров экранов

### Исправлено
- Проверка на совпадение паролей при регистрации
- Валидация паролей и улучшение логики проверки
- Исправления в дизайне и текстах интерфейса
- Улучшение подсказок для полей телефона и email
- Исправления в логике входа по телефону
- Улучшения в процессе регистрации
- Исправления в проверке номера телефона

### Изменено
- Файлы проверки пароля перенесены в nsg_data
- Обновлен Flutter до версии 3.32.2
- Обновлен flutter_multi_formatter до версии 2.13.7
- Email логин установлен по умолчанию
- Добавлен callback eventLoginWidgweClosed для отслеживания закрытия окна входа

### Технические улучшения
- Улучшена структура кода и организация файлов
- Добавлены дополнительные проверки и валидации
- Оптимизирована производительность компонентов
- Улучшена обработка ошибок и исключений

## [0.0.1] - 2024-01-01

### Добавлено
- Начальная версия пакета
- Базовая структура проекта
- Основные компоненты авторизации

---

## Типы изменений

- **Добавлено** - для новых функций
- **Исправлено** - для исправлений ошибок
- **Изменено** - для изменений в существующих функциях
- **Удалено** - для удаленных функций
- **Безопасность** - для исправлений уязвимостей
