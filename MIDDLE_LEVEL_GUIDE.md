# Middle Level Guide

Этот файл нужен не для запуска проекта, а для обучения.
Если читать проект как учебник, двигайся по разделам ниже.

## 1. Что должен понять middle-разработчик

После разбора проекта ты должен уметь объяснить:

- зачем нужен composition root
- чем `store/repository/service/view model` отличаются по ответственности
- когда использовать `NavigationStack`, а когда `NavigationSplitView`
- чем `SceneStorage` отличается от `AppStorage`
- чем `ObservableObject` отличается от `@Observable`
- в чём разница между `Core Data` и `SwiftData`
- зачем нужен `actor`
- как шарить данные между app target и widget extension
- как устроен `Live Activity` от модели до UI

## 2. Порядок чтения

### Шаг 1. Точка входа приложения

Открой:

- [StudyDemoApp.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/StudyDemoApp.swift>)
- [AppContainer.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/App/AppContainer.swift>)

Что понять:

- кто создаёт зависимости
- где инициализируются `Core Data`, `SwiftData`, widget sync
- как `scenePhase` влияет на сохранение и обновление snapshot для виджета

### Шаг 2. Корневая навигация

Открой:

- [ContentView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/ContentView.swift>)

Что понять:

- как `TabView` используется как верхний контейнер приложения
- почему в разных табах удобно держать отдельные `NavigationStack`
- как `SceneStorage` сохраняет выбранный таб

### Шаг 3. Рабочее место пользователя

Открой:

- [PlannerWorkspaceView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/PlannerWorkspaceView.swift>)
- [TaskListView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/TaskListView.swift>)
- [TaskDetailView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/TaskDetailView.swift>)

Что понять:

- как работает `NavigationSplitView`
- где хранится `selection`
- как связываются sidebar, список и detail
- где UI читает состояние, а где отправляет actions

### Шаг 4. Слой данных

Открой:

- [TaskStore.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/Repositories/TaskStore.swift>)
- [CoreDataStack.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/CoreData/CoreDataStack.swift>)
- [TaskEntity.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/CoreData/TaskEntity.swift>)
- [StudySessionStore.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/Repositories/StudySessionStore.swift>)
- [StudySessionRecord.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/SwiftData/StudySessionRecord.swift>)

Что понять:

- почему задачи лежат в `Core Data`, а аналитика в `SwiftData`
- где бизнес-правила живут в store, а не во view
- почему UI не должен напрямую писать в базу

## 3. Что здесь важно архитектурно

### Composition root

`AppContainer` собирает приложение в одном месте.
Это удобно, потому что:

- зависимости не размазываются по view
- легко заменить хранилище на in-memory режим
- удобно тестировать

### Store как граница между UI и данными

`TaskStore` и `StudySessionStore` здесь играют роль учебного “межслоя”.
Это не единственный правильный вариант, но он хорош для обучения.

Почему это полезно:

- view остаются тоньше
- бизнес-операции собраны вместе
- изменение базы не ломает UI-структуру напрямую

### UI как функция состояния

Во многих местах view ничего не “вычисляет сложно”, а просто показывает уже подготовленные данные.
Это хороший признак.

## 4. Observable state: что тут стоит знать

Сейчас проект использует:

- `ObservableObject`
- `@Published`
- `@EnvironmentObject`

Почему это норм:

- это классический, понятный и широко используемый путь
- его часто знают и спрашивают на собеседованиях
- он хорошо подходит как база

Почему можно захотеть `@Observable`:

- меньше boilerplate
- более современный стиль Observation framework

Почему здесь пока не он:

- локальная автоматическая сборка падала на macro pipeline
- для учебного проекта важнее стабильная сборка, чем “самая новая магия”

## 5. Конкурентность: что тут именно изучать

### `Task`

Используется для запуска async-работы из UI.

Смотри:

- [PlannerWorkspaceView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/PlannerWorkspaceView.swift>)
- [TaskDetailView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/TaskDetailView.swift>)

### `actor`

Используется в:

- [TaskSyncActor.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Services/TaskSyncActor.swift>)

Что важно понять:

- actor сериализует доступ к внутреннему состоянию
- это проще и безопаснее, чем ручные lock-механизмы

### `TaskGroup`

Там же есть `withTaskGroup`.
Это демонстрирует параллельный расчёт рекомендаций.

Что middle должен уметь объяснить:

- когда выгодно параллелить
- когда это оверхед
- как собрать результат обратно

## 6. Core Data vs SwiftData

Это один из лучших учебных блоков проекта.

### Core Data здесь

Используется для основных задач.

Зачем:

- зрелая технология
- полезно знать старый и всё ещё очень распространённый стек
- удобно показать явную модель, context и fetch

### SwiftData здесь

Используется для history/analytics.

Зачем:

- показать современный API
- продемонстрировать coexistence двух подходов в одном приложении

### Что спросить себя

- почему задачи не перенесли полностью в SwiftData
- когда смешивание двух persistence-технологий оправдано
- где это усложняет архитектуру

## 7. Виджеты и Live Activities

Смотри:

- [WidgetSyncService.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Services/WidgetSyncService.swift>)
- [SharedAppGroup.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemoShared/SharedAppGroup.swift>)
- [TaskWidgetSnapshot.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemoShared/TaskWidgetSnapshot.swift>)
- [TaskOverviewWidget.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemoWidgets/TaskOverviewWidget.swift>)
- [LiveActivityManager.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Services/LiveActivityManager.swift>)
- [FocusTimerLiveActivity.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemoWidgets/FocusTimerLiveActivity.swift>)

Что понять:

- app target не “отдаёт” модели виджету напрямую
- вместо этого формируется небольшой snapshot
- общий `App Group` нужен для обмена данными между target’ами

## 8. Практические задания для middle

Если хочешь реально вырасти, не просто читай, а сделай эти задания.

### Блок A. Данные

1. Добавь подзадачи к `TaskEntity`.
2. Сделай сортировку задач по нескольким стратегиям.
3. Добавь фильтр “просроченные”.
4. Сделай soft-delete и экран архива.

### Блок B. Архитектура

1. Вынеси протоколы `TaskRepository` и `StudySessionRepository`.
2. Сделай `inMemory` implementation для превью и тестов.
3. Добавь unit-тесты бизнес-операций store-слоя.

### Блок C. Concurrency

1. Сделай cancel для синхронизации.
2. Добавь debounce для поиска по задачам.
3. Добавь отдельный `actor` для кэша аналитики.

### Блок D. UI

1. Сделай drag-and-drop между колонками канбана.
2. Добавь sheet для создания/редактирования задачи.
3. Сделай отдельный экран timeline истории задачи.

### Блок E. Widget / Live Activity

1. Добавь интенты для запуска focus session из виджета.
2. Покажи оставшееся время до конца текущего pomodoro.
3. Добавь разные размеры widget layout.

## 9. Вопросы на самопроверку

Если ты не можешь ответить на эти вопросы без подсказки, проект надо перечитать.

1. Почему `AppContainer` лучше, чем создание store прямо внутри view?
2. Почему `TaskStore` лучше, чем прямой `@FetchRequest` в каждом экране?
3. Чем `SceneStorage` отличается от `AppStorage` на практике?
4. Почему `actor` безопаснее обычного класса для shared mutable state?
5. Когда `Core Data` здесь лучше подходит, чем `SwiftData`, и наоборот?
6. Почему виджету не стоит читать весь граф объектов приложения?
7. Где в проекте граница между presentation logic и business logic?
8. Какие части проекта было бы сложнее тестировать в текущем виде?

## 10. Что ещё можно улучшить

До настоящего “middle study pack” ещё можно добить:

- `README` со схемой слоёв в mermaid
- unit tests
- UI tests
- отдельные markdown-файлы по `Core Data`, `SwiftData`, `Concurrency`
- диаграмму data flow
- раздел “антипаттерны и типовые ошибки”

## 11. Честная оценка текущего состояния

Сейчас проект уже:

- хороший учебный проект
- покрывает твой исходный функциональный запрос
- подходит как база для подготовки к уровню `junior strong -> middle`

Но для полноценного `middle` тебе нужно не только читать его, а ещё:

- переписывать куски сам
- писать тесты
- уметь защищать архитектурные решения словами
- видеть trade-offs, а не только “рабочий код”
