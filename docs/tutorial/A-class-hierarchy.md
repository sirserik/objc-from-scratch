# Приложение A. Иерархия классов Foundation

Это справочник, а не глава: дерево классов Foundation с короткими
пометками. Держи его под рукой, когда читаешь чужой код или ищешь, от
кого унаследован незнакомый класс.

У дерева Foundation **два корня**. Из первого, `NSObject`,
растёт почти всё — строки, числа, коллекции, даты, сетевые классы, твои
собственные типы. Второй, `NSProxy`, — отдельный тонкий корень для
объектов-заместителей; он не наследует `NSObject` и в дереве стоит сам по
себе. Механику обоих корней (поле `isa`, метаклассы, поиск метода,
пересылка сообщений) мы разобрали в главе 14 — здесь её не повторяем,
только показываем, кто от кого происходит.

Как читать дерево ниже. Отступ и ветка `├─`/`└─` у класса означают
«наследник». Строки без префикса `NS` («Строки и атрибутированный
текст», «Коллекции» и т.д.) — не классы, а тематические группы: каждый
класс первого уровня внутри группы наследует прямо `NSObject`. Пометка
`(NSObject)` у части классов — то же самое, сказанное явно. Каждая связь «родитель →
наследник» в дереве сверена с runtime: мы прошли по всем классам
функцией `class_getSuperclass` на macOS 26. Имена даны как в SDK (с префиксом `NS`); в актуальном Swift у
многих из них есть «голые» имена без префикса (`String`, `URLRequest`),
но в Objective-C пишем с `NS`.

## Дерево классов Foundation

```text
NSObject  (корневой класс — базовое поведение: alloc/init, retain count,
│          isKindOfClass:, respondsToSelector:, description, пересылка)
│
├─ Строки и атрибутированный текст
│   ├─ NSString
│   │   └─ NSMutableString          изменяемая строка
│   └─ NSAttributedString           строка + атрибуты (шрифт, цвет, ссылки)
│       └─ NSMutableAttributedString
│
├─ Значения и числа
│   └─ NSValue                      обёртка над любым C-значением
│       │                           (NSRange, CGPoint, указатель …)
│       └─ NSNumber                 обёртка над числом/BOOL
│           └─ NSDecimalNumber      десятичная арифметика без потерь
│
├─ Коллекции
│   ├─ NSArray                      упорядоченный список
│   │   └─ NSMutableArray
│   ├─ NSDictionary                 пары ключ→значение
│   │   └─ NSMutableDictionary
│   ├─ NSSet                        множество (уникальные элементы)
│   │   └─ NSMutableSet
│   │       └─ NSCountedSet         множество со счётчиком повторов
│   ├─ NSOrderedSet                 уникальные + сохранён порядок
│   │   └─ NSMutableOrderedSet
│   └─ NSEnumerator                 курсор обхода коллекции (nextObject)
│       └─ NSDirectoryEnumerator    обход содержимого каталога
│
├─ Данные и время
│   ├─ NSData                       неизменяемый буфер байтов
│   │   └─ NSMutableData
│   ├─ NSDate                       момент времени (точка на оси)
│   ├─ NSCalendar          (NSObject) календарь, разбивка даты на компоненты
│   ├─ NSDateComponents    (NSObject) год/месяц/день/час … по отдельности
│   ├─ NSTimeZone          (NSObject) часовой пояс
│   └─ NSFormatter                  абстрактный «текст ⇄ объект»
│       ├─ NSDateFormatter          дата ⇄ строка
│       └─ NSNumberFormatter        число ⇄ строка (валюта, проценты)
│
├─ Разбор текста
│   ├─ NSCharacterSet               набор символов (фильтр/триммер)
│   │   └─ NSMutableCharacterSet
│   ├─ NSScanner          (NSObject) последовательный разбор строки
│   └─ NSRegularExpression (NSObject) регулярные выражения
│       └─ NSDataDetector           извлечение ссылок, дат, телефонов
│
├─ URL и сеть
│   ├─ NSURL              (NSObject) адрес ресурса (http, file, …)
│   ├─ NSURLComponents    (NSObject) сборка/разбор URL по частям
│   ├─ NSURLQueryItem     (NSObject) пара имя=значение строки запроса
│   ├─ NSURLRequest                 описание запроса
│   │   └─ NSMutableURLRequest
│   ├─ NSURLResponse      (NSObject) ответ сервера (общая часть)
│   │   └─ NSHTTPURLResponse        HTTP-ответ (коды, заголовки)
│   ├─ NSURLSession       (NSObject) современная загрузка по сети
│   ├─ NSURLSessionTask   (NSObject) абстрактная задача сессии
│   │   ├─ NSURLSessionDataTask          приём данных в память
│   │   │   └─ NSURLSessionUploadTask     отправка тела запроса
│   │   ├─ NSURLSessionDownloadTask       загрузка в файл
│   │   └─ NSURLSessionStreamTask         потоковое TCP-соединение
│   ├─ NSURLCredential    (NSObject) логин/пароль/сертификат
│   ├─ NSURLCache         (NSObject) кэш ответов
│   └─ NSURLConnection    (NSObject) УСТАРЕЛО — заменён NSURLSession
│
├─ Файлы и окружение
│   ├─ NSFileManager      (NSObject) операции с файлами и каталогами
│   ├─ NSFileHandle       (NSObject) низкоуровневое чтение/запись дескриптора
│   ├─ NSBundle           (NSObject) доступ к ресурсам приложения/фреймворка
│   ├─ NSProcessInfo      (NSObject) сведения о процессе, аргументы, env
│   └─ NSUserDefaults     (NSObject) хранилище пользовательских настроек
│
├─ Уведомления (NotificationCenter)
│   ├─ NSNotification       (NSObject) событие: имя + объект + userInfo
│   └─ NSNotificationCenter (NSObject) рассылка уведомлений подписчикам
│
├─ Потоки, очереди, синхронизация
│   ├─ NSThread           (NSObject) отдельный поток выполнения
│   ├─ NSOperation        (NSObject) единица работы для очереди
│   │   ├─ NSBlockOperation          оборачивает блок(и) ^{ }
│   │   └─ NSInvocationOperation     оборачивает вызов метода
│   ├─ NSOperationQueue   (NSObject) очередь, исполняющая NSOperation
│   ├─ NSRunLoop          (NSObject) цикл обработки событий потока
│   ├─ NSTimer            (NSObject) отложенный/повторяющийся вызов
│   │   (четыре блокировки ниже не наследуют друг друга — их роднит
│   │    только протокол NSLocking)
│   ├─ NSLock             (NSObject) обычный мьютекс
│   ├─ NSRecursiveLock    (NSObject) рекурсивный мьютекс
│   ├─ NSCondition        (NSObject) мьютекс + условие
│   └─ NSConditionLock    (NSObject) блокировка по «номеру условия»
│
├─ Архивация и сериализация
│   ├─ NSCoder                      абстрактный кодер/декодер объектов
│   │   ├─ NSKeyedArchiver          объект → данные (по ключам)
│   │   └─ NSKeyedUnarchiver        данные → объект
│   ├─ NSPropertyListSerialization (NSObject) plist ⇄ объекты
│   └─ NSJSONSerialization         (NSObject) JSON ⇄ объекты
│
├─ Запросы и сортировка
│   ├─ NSPredicate        (NSObject) условие фильтрации (как WHERE)
│   │   ├─ NSComparisonPredicate     сравнение «левое op правое»
│   │   └─ NSCompoundPredicate       AND/OR/NOT над предикатами
│   ├─ NSExpression       (NSObject) выражение внутри предиката
│   └─ NSSortDescriptor   (NSObject) правило сортировки (ключ + порядок)
│
├─ Интроспекция вызова (см. главу 14)
│   ├─ NSInvocation       (NSObject) упакованное сообщение целиком
│   └─ NSMethodSignature  (NSObject) описание сигнатуры метода
│
└─ Прочее, часто встречающееся
    ├─ NSError            (NSObject) ошибка: домен + код + userInfo
    ├─ NSException        (NSObject) исключение (бросается @throw)
    ├─ NSNull             (NSObject) «ничего» там, где nil нельзя
    │                                (внутри коллекций);
    │                                синглтон [NSNull null]
    └─ NSUUID             (NSObject) 128-битный уникальный идентификатор


NSProxy  (ВТОРОЙ, отдельный корень — НЕ наследует NSObject)
│         абстрактный суперкласс для объектов-заместителей: реализует
│         минимум и заставляет наследника определить пересылку
│         (-forwardInvocation: / -methodSignatureForSelector:).
│         На нём строят ленивую загрузку и удалённые прокси.
└─ твои прокси-классы
```

Дерево не исчерпывающее: в Foundation сотни классов, плюс к ним добавляют
свои AppKit, UIKit, Core Data и т.д. Здесь — костяк, который встречается в
повседневном коде. Если нужного класса нет, открой его страницу на
developer.apple.com: вверху всегда указана строка `Inherits From`.

## Пары «неизменяемый → изменяемый»

Foundation последовательно разделяет данные на неизменяемые (immutable) и
изменяемые (mutable). Изменяемый класс всегда **наследник** неизменяемого
и добавляет методы правки на месте (`addObject:`, `appendString:` …).
Базовый класс хранения общий, поэтому `NSMutableArray` — это и есть
`NSArray`, которому разрешили меняться.

| Неизменяемый          | Изменяемый                   |
| --------------------- | ---------------------------- |
| `NSString`            | `NSMutableString`            |
| `NSAttributedString`  | `NSMutableAttributedString`  |
| `NSArray`             | `NSMutableArray`             |
| `NSDictionary`        | `NSMutableDictionary`        |
| `NSSet`               | `NSMutableSet`               |
| `NSOrderedSet`        | `NSMutableOrderedSet`        |
| `NSData`              | `NSMutableData`              |
| `NSCharacterSet`      | `NSMutableCharacterSet`      |
| `NSURLRequest`        | `NSMutableURLRequest`        |

Практический вывод: метод, который принимает `NSArray *`, спокойно
примет и `NSMutableArray *` (наследник подходит везде, где ждут предка).
Обратное неверно. И помни про `copy` у свойств-строк (см. главу 8):
`copy` неизменяемого свойства фиксирует значение, даже если ему передали
мутабельный экземпляр.

## Ключевые протоколы Foundation

Иерархия типов — это не только классы. Многое в поведении задают
**протоколы** (см. главу 10): класс не наследует их, а *принимает* и
обязуется реализовать. Самые важные:

- **`NSObject` (протокол).** Не путать с одноимённым классом. Это
  корневой протокол: `class`, `superclass`, `isKindOfClass:`,
  `isEqual:`, `hash`, `respondsToSelector:`, `description`,
  `retain`/`release` (под MRR). Его принимают **оба** корня — и класс
  `NSObject`, и `NSProxy`, — поэтому объекты обоих деревьев умеют
  отвечать на эти сообщения. Подробности в главе 14.
- **`NSCopying`.** Требует `-copyWithZone:`. Объект умеет отдать свою
  копию (у пар «неизменяемый/изменяемый» — **неизменяемую**); вызывается
  через `[obj copy]`. Нужен, чтобы
  объект можно было класть ключом в `NSDictionary`.
- **`NSMutableCopying`.** Требует `-mutableCopyWithZone:`. Отдаёт
  **изменяемую** копию; вызывается через `[obj mutableCopy]`.
- **`NSCoding`.** Требует `-initWithCoder:` и `-encodeWithCoder:`.
  Объект умеет сериализоваться через `NSCoder` (архивация в данные и
  обратно).
- **`NSSecureCoding`.** Расширяет `NSCoding` и добавляет
  `+supportsSecureCoding`. Защищает от подмены класса при разборе
  архива; обязателен в современных API (например, при передаче объектов
  между процессами).
- **`NSFastEnumeration`.** Даёт объекту поддержку быстрого цикла
  `for (id x in collection)`. Его принимают все коллекции
  (`NSArray`, `NSSet`, `NSDictionary`, `NSOrderedSet`).
- **`NSLocking`.** Требует `-lock` и `-unlock`. Его принимают `NSLock`,
  `NSRecursiveLock`, `NSCondition`, `NSConditionLock` — поэтому их можно
  использовать единообразно.
- **Сравнение через `compare:`.** Отдельного протокола «Comparable» в
  Objective-C нет, но по соглашению классы, которые можно упорядочивать
  (`NSNumber`, `NSString`, `NSDate`), реализуют `-compare:` и возвращают
  `NSComparisonResult` (`NSOrderedAscending`/`NSOrderedSame`/
  `NSOrderedDescending`). На это соглашение опираются `sortedArrayUsingSelector:`
  и `NSSortDescriptor`.

И один **класс**, который логически относится сюда же:

- **`NSEnumerator`** — не протокол, а класс (наследник `NSObject`).
  Курсор обхода: `-nextObject` отдаёт следующий элемент и `nil` в конце.
  Его возвращают `-objectEnumerator` и `-reverseObjectEnumerator`
  коллекций. Сам `NSEnumerator` принимает `NSFastEnumeration`, поэтому по
  нему тоже работает `for (id x in enumerator)`.

## Предупреждение: toll-free bridging с Core Foundation

Часть классов Foundation имеет «близнеца» в Core Foundation — это
си-уровневый фреймворк с типами вроде `CFStringRef`, `CFArrayRef`,
`CFDictionaryRef`. Такие пары **toll-free bridged** («мост без пошлины»):
в памяти это один и тот же объект, и указатель можно приводить от одного
типа к другому без преобразования.

```text
NSString      <->  CFStringRef
NSArray       <->  CFArrayRef
NSDictionary  <->  CFDictionaryRef
NSData        <->  CFDataRef
NSDate        <->  CFDateRef
NSNumber      <->  CFNumberRef
```

То есть `CFStringRef` можно передать туда, где ждут `NSString *`, и
наоборот — но под ARC приведение требует ключевого слова `__bridge`
(или `__bridge_transfer`/`__bridge_retained`, когда нужно передать
владение). Core Foundation считает ссылки вручную
(`CFRetain`/`CFRelease`), ARC за его типами не следит — отсюда и нужда в
явных мостах. Это узкая тема; здесь достаточно знать, что мост
существует. Подробности — в документации Apple «Toll-Free Bridged Types».
Само слово `__bridge` ты уже встречал в главах 8 и 14 — там им приводили
объект к `void *`, чтобы напечатать адрес.

## Документация Apple

- Foundation (обзор фреймворка и полный список классов) —
  developer.apple.com/documentation/foundation
- Foundation → Numbers, Data, and Basic Values; Strings and Text;
  Collections; Dates and Times; Filtering and Sorting; URL Loading
  System — тематические разделы того же справочника.
- `NSObject` (класс) — developer.apple.com/documentation/objectivec/nsobject
- `NSObject` (протокол) —
  developer.apple.com/documentation/objectivec/nsobjectprotocol
- `NSProxy` — developer.apple.com/documentation/foundation/nsproxy
- Toll-Free Bridged Types (Core Foundation ↔ Foundation) —
  developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFDesignConcepts/Articles/tollFreeBridgedTypes.html
- Механику `isa`, метаклассов и пересылки см. в главе 14 этой книги.
