# Глава 23. Взаимодействие со Swift

Во введении мы договорились честно: новый проект с чистого листа сегодня
обычно начинают на Swift, а Objective-C учат, чтобы работать с существующим
кодом и понимать платформу изнутри. Эти два мира живут в одном приложении,
в одних файлах проекта, и зовут друг друга по именам. Эта глава — про мост
между ними: как написать Objective-C так, чтобы из Swift он выглядел красиво
и безопасно, и как устроена сама связь.

Глава во многом **концептуальная**. Полноценный Swift-компилятор и проект
Xcode мы тут собирать не будем. Уговор такой: Objective-C-сторону мы пишем
по-настоящему, компилируем и запускаем (вывод в книге — реальный), а
Swift-куски показываем рядом как **иллюстрацию** — «вот как этот же класс
выглядит в Swift». Их мы не компилируем, и в `code/` они не лежат. Зато ты
увидишь главное: какие аннотации в objc-коде делают Swift-сторону
аккуратной.

## Что мы сделаем

- Поймём, зачем вообще нужен мост и чем он отличается от обычной линковки.
- Разберём, как Objective-C виден из Swift (bridging header, module map).
- Разберём, как Swift виден из Objective-C (`-Swift.h`, `@objc`).
- Пройдём по маппингу типов: `NSString` ↔ `String`, `NSArray` ↔ `[T]`,
  nullable ↔ опционал, `NSError**` ↔ `throws`; научимся управлять именами
  через `NS_SWIFT_NAME`.
- Соберём настоящий objc-класс, который мостится в Swift «как родной».

## Зачем это вообще нужно

Представь живой проект Apple-экосистемы. Ему восемь лет. Ядро — сеть,
модели, база — на Objective-C, потому что в год старта Swift только
появился. Новые экраны команда пишет на Swift. А под ними обоими лежат
системные библиотеки — Foundation, UIKit, — тоже во многом Objective-C.
Три слоя, и все должны спокойно звать друг друга:

```text
   Swift-экраны (новое)
        │  зовут
        ▼
   Objective-C-ядро (старое, рабочее)
        │  зовут
        ▼
   Foundation / UIKit (системное, ObjC)
```

Переписать всё на Swift одним движением невозможно — годы работы и риск
сломать рабочее. Поэтому языки живут вместе: новый код на Swift, старый на
Objective-C, и между ними — официально поддерживаемый двусторонний мост.
Без знания, как он устроен, ты не подключишь старый класс к новому экрану.

> **Отличие от Си.** Си и так линкуется с чем угодно: у него есть
> двоичный интерфейс (ABI), и любая программа может вызвать сишную
> функцию, зная её имя и сигнатуру. Но линковка переносит только адрес и
> голые байты аргументов — «понимания» типов в ней нет. Мост Objective-C
> ↔ Swift делает больше: он переносит **имена методов, типы, опциональность
> и способ сообщать об ошибках**. Это семантический мост, а не просто
> «нашли функцию по символу». Поэтому Swift видит не `id` и `void *`, а
> `String`, `[Product]` и `throws` — компилятор Swift по-настоящему
> понимает, что приехало с другой стороны.

## Как Objective-C виден из Swift

Swift умеет напрямую читать заголовочные файлы Objective-C (`.h`). Ему не
нужен переходник на каждый метод — компилятор Swift сам разбирает
`@interface`, видит свойства и методы и строит из них Swift-API. Вопрос
только в том, **какие** заголовки ему показать. Тут два сценария.

### Сценарий 1: один модуль (приложение) — bridging header

Когда Objective-C и Swift лежат в одном таргете (обычное приложение),
Xcode заводит специальный файл — **bridging header**, «мост-заголовок».
Имя по умолчанию: `ИмяПроекта-Bridging-Header.h`. Когда ты впервые
добавляешь Swift-файл в objc-проект (или наоборот), Xcode предлагает
создать его автоматически.

Внутри — просто `#import` тех objc-заголовков, которые ты хочешь видеть
из Swift:

```objc
// MyApp-Bridging-Header.h
#import "ShoppingCart.h"
#import "NetworkClient.h"
#import "LegacyImageCache.h"
```

Всё, что подключено здесь, становится видимым из любого Swift-файла этого
таргета — без `import`, без обёрток. Добавил класс в проект — дописал
строку в bridging header — зовёшь его из Swift.

### Сценарий 2: фреймворк — umbrella header и module map

Если Objective-C-код оформлен как **фреймворк** (отдельный
переиспользуемый модуль), bridging header не используют. Вместо него у
фреймворка есть **umbrella header** («зонтичный заголовок») — один
публичный `.h`, который подключает все остальные публичные заголовки
модуля:

```objc
// PaymentKit.h — umbrella header фреймворка PaymentKit
#import <PaymentKit/ShoppingCart.h>
#import <PaymentKit/PaletteColor.h>
```

И **module map** — описание модуля для компилятора (обычно его генерирует
Xcode автоматически):

```text
framework module PaymentKit {
    umbrella header "PaymentKit.h"
    export *
    module * { export * }
}
```

После этого из Swift фреймворк подключается одной строкой, как любой
другой модуль:

```swift
import PaymentKit   // и все публичные ObjC-классы PaymentKit доступны
```

Разница простая: **bridging header** — для «своих» файлов внутри
приложения; **umbrella header + module map** — для упакованного
фреймворка, который импортируют по имени.

## Как Swift виден из Objective-C

Обратное направление чуть хитрее. Objective-C не умеет читать `.swift`
напрямую. Поэтому компилятор Swift **сам генерирует** заголовок —
`ИмяПродукта-Swift.h`. Это автоматический `.h`, в котором Swift-классы
описаны на языке Objective-C. Ты его не пишешь и не редактируешь; ты его
только подключаешь там, где зовёшь Swift из objc:

```objc
// в любом .m-файле, где нужен Swift-класс
#import "MyApp-Swift.h"

// теперь можно
OrderViewModel *vm = [[OrderViewModel alloc] init];
[vm reload];
```

Но генерируется этот заголовок не сам по себе для всего подряд. Swift по
умолчанию **закрыт** от Objective-C. Чтобы Swift-класс или метод попал в
`-Swift.h`, его надо явно пометить.

### `@objc` и `@objcMembers`

Атрибут `@objc` говорит компилятору Swift: «этот класс/метод/свойство
покажи Objective-C». Чтобы класс вообще был виден из objc, он должен
наследоваться от `NSObject`. Помечать каждый член по отдельности утомительно
— `@objcMembers` ставит `@objc` сразу на весь класс:

```swift
// Swift-сторона (иллюстрация)
@objcMembers class OrderViewModel: NSObject {
    var title: String = ""              // автоматически @objc, видно из ObjC
    func reload() { /* ... */ }         // автоматически @objc
    @objc func ping() { }               // можно и точечно, без @objcMembers
}
```

### Что из Swift в принципе НЕ видно из Objective-C

Часть возможностей Swift не имеет аналога в Objective-C, и мостить их
нечем. Их нельзя пометить `@objc`, и из objc они недоступны в принципе:

- **`struct`** — значимые типы Swift. В объектной модели Objective-C для
  них нет места, поэтому в objc они не видны вовсе.
- **enum с ассоциированными значениями** — `enum Result { case ok(Int);
  case fail(String) }`. Обычный «целочисленный» `@objc enum` мостится, а
  с ассоциированными значениями — нет.
- **Дженерики Swift** — свои обобщённые типы (`Stack<T>`) в objc не показать.
- **Кортежи** (`(Int, String)`), протоколы с `associatedtype` и прочее
  «чисто-swift'овое».

Правило в голове: **из Objective-C видно только то, что выражается в
объектной модели Objective-C**. Классы-наследники `NSObject`, их методы,
свойства и обычные перечисления — да. Уникальные swift-конструкции — нет.

> **Отличие от Си.** В Си «видимость» — это вопрос наличия объявления в
> заголовке: есть прототип функции — можешь звать. Тут видимость
> определяется ещё и тем, **выразима ли вообще конструкция** в чужой
> системе типов. Swift-структуру нельзя «объявить» в objc-заголовке не
> потому, что забыли, а потому, что в объектной модели Objective-C для
> неё нет места.

## Маппинг типов: что во что превращается

Самое полезное в мосте — автоматический перевод типов. Один и тот же
объект на стороне Objective-C и на стороне Swift называется по-разному, но
это один объект. Вот основные пары.

```text
   Objective-C                     Swift
   ─────────────────────────────   ─────────────────────────
   NSString *                      String
   NSArray<Product *> *            [Product]
   NSDictionary<NSString *, T *>   [String: T]
   NSSet<T *> *                    Set<T>
   NSInteger / NSUInteger          Int / UInt
   CGFloat / double                CGFloat / Double
   BOOL                            Bool
   nullable NSString *             String?       (опционал)
   nonnull NSString *              String        (НЕ опционал)
   void (^)(NSString *)            (String) -> Void   (замыкание)
   - (...)error:(NSError **)       throws
```

**`NSString` ↔ `String`.** `NSString *` в параметре или возврате — это в
Swift `String`. Мост конвертирует между двумя представлениями сам, руками
ничего делать не надо.

**`NSArray<Product *>` ↔ `[Product]`.** Вот ради чего в главе 22 мы
писали дженерик-параметр у коллекций. Без него `NSArray *` приехал бы в
Swift как `[Any]` — бесполезный мешок с приведением каждого элемента к
типу. С `NSArray<Product *> *` Swift видит честный `[Product]`. То же с
`NSDictionary<K, V>` → `[K: V]`.

**`nullable`/`nonnull` ↔ опционал.** Это второй большой повод для главы
22. Опционал в Swift — это тип, который либо хранит значение, либо пуст
(`nil`). `String?` (со знаком вопроса) — «строка или ничего». `String`
(без вопроса) — «строка точно есть». Компилятор Swift заставляет
проверять опционалы перед использованием, и в этом его безопасность.

Наши аннотации переводятся в это различие напрямую: `nullable NSString *`
→ `String?` (распаковать перед работой), `nonnull NSString *` → `String`
(пользоваться сразу).

А что, если у objc-метода **нет** аннотации nullability? Тогда Swift не
знает, бывает ли там `nil`, и подставляет **неявно развёрнутый опционал**
— `String!`. Это «опционал, который Swift разрешает использовать без
проверки». Удобно, но опасно: если там всё-таки прилетит `nil`,
приложение упадёт. Поэтому неаннотированный objc-API в Swift выглядит
россыпью восклицательных знаков — некрасиво и небезопасно. Аккуратные
`NS_ASSUME_NONNULL_BEGIN`/`END` и точечные `nullable` убирают эти `!`.

> **Отличие от Си.** В Си указатель либо ненулевой, либо `NULL`, и
> компилятор не следит, проверил ты его или нет — забыл проверку, получил
> разыменование нуля и падение. Опционал Swift поднимает это на уровень
> типа: «может быть пусто» вписано в тип, и компилятор не даст
> попользоваться значением, не распаковав его. Наши `nullable`/`nonnull`
> — это ровно тот мостик, по которому знание «бывает ли тут nil»
> переезжает из objc-заголовка в систему типов Swift.

**Блоки ↔ замыкания.** Блок Objective-C (`^{ }` из главы 12) — это и есть
замыкание Swift. `void (^)(NSString *)` приезжает как `(String) -> Void`.

**`NSError**` ↔ `throws`.** Метод, который принимает последним параметром
`NSError **`, возвращает `nil`/`NO` при неудаче и заполняет `*error`,
Swift распознаёт и делает **throwing** — бросающим ошибку. Вместо разбора
`NSError` ты пишешь `try` и ловишь ошибку в `catch`. Покажем на живом
классе.

## Собираем класс, который хорошо мостится

Хватит теории — напишем настоящую objc-сторону: корзину покупок
`ShoppingCart`. Задача — аннотировать её так, чтобы в Swift она выглядела
как написанный на Swift класс. Файл `code/23-bridgeable.m`.

```objc
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN   // всё ниже nonnull, кроме явного nullable

@interface ShoppingCart : NSObject

// nonnull -> в Swift String, НЕ String?
@property (nonatomic, copy, readonly) NSString *ownerName;

// дженерик -> в Swift [String], а не [Any]
@property (nonatomic, copy, readonly) NSArray<NSString *> *items;

// nullable -> в Swift String? (опционал)
@property (nonatomic, copy, nullable) NSString *promoCode;

// initWithOwner: -> в Swift init(owner:)
- (instancetype)initWithOwner:(NSString *)ownerName NS_DESIGNATED_INITIALIZER;

// запрещаем пустой init: в Swift его не будет видно
- (instancetype)init NS_UNAVAILABLE;

- (void)addItem:(NSString *)item;

// nullable-возврат -> в Swift item(at:) -> String?
- (nullable NSString *)itemAtIndex:(NSUInteger)index;

// блок; NS_NOESCAPE -> не «убегающий»
- (void)enumerateItemsUsingBlock:(void (NS_NOESCAPE ^)(NSString *item,
                                                       NSUInteger index))block;

// error: последним -> в Swift throws
- (nullable NSNumber *)checkoutWithPricePerItem:(double)price
                                          error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
```

### `NS_ASSUME_NONNULL_BEGIN` / `END`

Эта пара (мы видели её в главе 22) включает «по умолчанию всё ненулевое»
для всех указателей между ними. Внутри блока помечаешь только
**исключения** — то, что действительно может быть `nil`, словом
`nullable`. И читается легче, и в Swift даёт чистый API без лишних `!`.

### Свойства: `ownerName`, `items`, `promoCode`

Три свойства из листинга в Swift выглядят так (иллюстрация, не компилируем):

```swift
// Swift видит ShoppingCart примерно так:
class ShoppingCart: NSObject {
    var ownerName: String { get }      // nonnull -> не опционал
    var items: [String] { get }        // дженерик -> массив строк
    var promoCode: String?             // nullable -> опционал
}
```

`ownerName` — `String`, потому что он nonnull (мы внутри ASSUME_NONNULL).
`items` — `[String]`, потому что у `NSArray` указан параметр
`<NSString *>`. `promoCode` — `String?`, потому что помечен `nullable`.
Каждая аннотация на своём месте — и Swift-сторона выглядит идеально.

### Инициализаторы: `initWithOwner:` и запрет `init`

Имя `initWithOwner:` Swift автоматически превращает в `init(owner:)` —
часть «With» отрезается, а первый аргумент получает метку из остатка. А
`NS_UNAVAILABLE` на пустом `init` говорит Swift: этого инициализатора нет,
не предлагай его. В итоге:

```swift
let cart = ShoppingCart(owner: "Алия")   // есть
let bad  = ShoppingCart()                // ошибка компиляции: init недоступен
```

> **Отличие от Си.** В Си «создание» — это `malloc` плюс ручное
> заполнение полей; никаких именованных параметров. Мост переносит
> именно **имена аргументов**: `initWithOwner:` → `init(owner:)`. Имя
> метода как часть API — этого в Си нет вовсе.

### Блок с `NS_NOESCAPE`

`NS_NOESCAPE` помечает блок как **не убегающий**: он отработает прямо
внутри метода и не сохранится где-то на потом. Для Swift это важно: не
убегающее замыкание не требует пометки `@escaping`, и внутри него можно
писать `self.foo` без явного захвата `self`. В Swift:

```swift
cart.enumerateItems { item, index in     // без @escaping
    print("[\(index)] \(item)")
}
```

### Метод с `NSError**` → `throws`

Шаблон «возвращаем `nil` + заполняем `*error`» Swift распознаёт и делает
из метода throwing. Заметь, что nullable-возврат `NSNumber *` в Swift
становится **не**-опциональным: раз о провале теперь сообщает `throw`,
значению-результату опционал больше не нужен.

```swift
do {
    let total = try cart.checkout(pricePerItem: 1500)   // NSNumber, не опционал
    print("К оплате: \(total) ₸")
} catch {
    print("Ошибка checkout: \(error.localizedDescription)")
}
```

Имя метода тоже причесалось: хвост `error:` Swift убирает (он стал
`throws`), а `checkoutWithPricePerItem:` превратился в
`checkout(pricePerItem:)`.

## Запускаем objc-сторону

Swift мы не компилируем, но objc-класс — настоящий и рабочий. В `main`
(он есть в файле) мы создаём корзину, добавляем товары, перебираем их
блоком и дважды зовём checkout — на полной и пустой корзине. Собираем:

```text
clang -fobjc-arc -framework Foundation code/23-bridgeable.m -o cart
./cart
```

Реальный вывод:

```text
2026-06-28 12:41:47.247 cart[63741:1281717] Владелец: Алия
2026-06-28 12:41:47.247 cart[63741:1281717] Товаров: 3
2026-06-28 12:41:47.248 cart[63741:1281717] Товар 0: Клавиатура
2026-06-28 12:41:47.248 cart[63741:1281717] Товар 99: (null)
2026-06-28 12:41:47.248 cart[63741:1281717]   [0] Клавиатура
2026-06-28 12:41:47.248 cart[63741:1281717]   [1] Мышь
2026-06-28 12:41:47.248 cart[63741:1281717]   [2] Коврик
2026-06-28 12:41:47.248 cart[63741:1281717] К оплате: 4500 ₸
2026-06-28 12:41:47.248 cart[63741:1281717] Ошибка checkout: Корзина
пуста — нечего оформлять
```

`Товар 99: (null)` — наш `nullable`-возврат: вне диапазона метод вернул
`nil` (в Swift — `nil` опционала). Последняя строка — сработавший
`NSError**`: на стороне Swift она прилетела бы в `catch`. Один код — две
стороны моста.

## Управляем именами: `NS_SWIFT_NAME` и компания

Иногда автоперевод имени выходит неуклюжим, и хочется задать Swift-имя
руками. Для этого есть набор макросов — соберём их в файле
`code/23-annotations.m`.

### `NS_SWIFT_NAME` — переименовать для Swift

```objc
@interface PaletteColor : NSObject
@property (nonatomic, readonly) double red;
@property (nonatomic, readonly) double green;
@property (nonatomic, readonly) double blue;

// без аннотации Swift увидел бы color(red:green:blue:) — фабричный метод.
// с NS_SWIFT_NAME он становится обычным инициализатором.
+ (instancetype)colorWithRed:(double)red
                       green:(double)green
                        blue:(double)blue
    NS_SWIFT_NAME(init(red:green:blue:));

// длинное имя ужимаем до hexString()
- (NSString *)hexStringRepresentation NS_SWIFT_NAME(hexString());
@end
```

`NS_SWIFT_NAME(...)` принимает Swift-подпись метода. Для фабричного метода
`colorWithRed:green:blue:` мы просим Swift показать его как **инициализатор**
`init(red:green:blue:)` — так в Swift привычнее создавать объекты. Для
метода `hexStringRepresentation` просто даём короткое имя `hexString()`
(скобки означают «это метод»).

```swift
// Swift-сторона (иллюстрация)
let lime = PaletteColor(red: 0.6, green: 0.9, blue: 0.2)  // вместо color(red:...)
let hex  = lime.hexString()                                // вместо hexStringRepresentation()
```

`NS_SWIFT_NAME` работает не только на методах — им переименовывают классы,
свойства, перечисления, даже сишные функции и типы. Этим инструментом
системные фреймворки Apple причёсывают свой objc-API под современный Swift.

### `error:` → `throws` и `NS_SWIFT_NOTHROW`

```objc
@interface ConfigLoader : NSObject

// error: последним -> в Swift throwing: try loader.load(from: text)
- (nullable NSDictionary<NSString *, NSString *> *)loadFromString:(NSString *)text
                                                            error:(NSError **)error
    NS_SWIFT_NAME(load(from:));

// тоже принимает error:, но BOOL здесь — настоящий результат, а не «успех».
// NS_SWIFT_NOTHROW оставляет метод обычным, возвращающим Bool.
- (BOOL)isValidConfig:(NSString *)text error:(NSError **)error NS_SWIFT_NOTHROW;
@end
```

Первый метод — классический «загрузить или ошибка», и `throws` ему к
лицу. Заодно `NS_SWIFT_NAME(load(from:))` даёт короткое имя.

Второй — ловушка. Он принимает `error:`, и Swift по умолчанию сделал бы
его throwing. Но `BOOL` здесь — **смысловой результат** («валиден ли
конфиг»), а не сигнал успеха. `NS_SWIFT_NOTHROW` отменяет автоперевод:
метод останется обычным и вернёт `Bool`.

```swift
// Swift-сторона (иллюстрация)
let cfg = try loader.load(from: "host=localhost;port=5432")  // throwing
let ok  = loader.isValidConfig("a=b", error: nil)            // Bool, не throws
```

Рядом с этими тремя (`NS_SWIFT_NAME`, `NS_NOESCAPE`, `NS_SWIFT_NOTHROW`)
есть и другие — `NS_SWIFT_UNAVAILABLE`, `NS_REFINED_FOR_SWIFT` и прочие, —
но перечисленные закрывают подавляющее большинство случаев.

## Запускаем второй файл

```text
clang -fobjc-arc -framework Foundation code/23-annotations.m -o annot
./annot
```

Реальный вывод:

```text
2026-06-28 12:41:48.573 annot[63746:1281768] Цвет в hex: #99E633
2026-06-28 12:41:48.573 annot[63746:1281768] host = localhost, port = 5432
2026-06-28 12:41:48.573 annot[63746:1281768] Ошибка: Пустая строка
конфигурации
2026-06-28 12:41:48.573 annot[63746:1281768] Конфиг валиден: да
```

Объектная логика та же, что и без аннотаций: при сборке objc макросы
вроде `NS_SWIFT_NAME` компилятор просто игнорирует. Их единственная работа
— подсказать **Swift-стороне**, как назвать и подать API. Поэтому вывод
обычный, а вся польза проявилась бы в соседнем Swift-файле.

## Что мостится плохо: подводные камни

Мост хорош, но не всесилен — несколько мест, где он буксует.

**Множественное наследование протоколов в одном имени.** Objective-C
спокойно объявляет `id<Drawable, Serializable>` — объект, реализующий два
протокола сразу. В Swift это `Drawable & Serializable`, и обычно
переезжает нормально, но сложные `id<...>`-сигнатуры мост иногда упрощает
— проверяй, как именно приехал тип.

**Перегрузка по типам аргументов.** В Objective-C методы различаются
полным именем с двоеточиями, «перегрузки» по типам как в Swift нет.
Несколько `@objc`-методов с одним базовым именем должны различаться в
objc-имени — иначе конфликт селекторов. На границе моста имена важнее
типов.

**Указатели и небезопасные типы.** Сырые сишные указатели (`void *`,
`int *`), C-структуры (не Foundation), указатели на функции мостятся в
Swift как «небезопасные» (`UnsafePointer` и пр.) или не мостятся вовсе.
Метод, торчащий наружу сырым указателем, в Swift неудобен и опасен —
прячь такое за объектным API.

**Селекторы и KVC.** Динамические механизмы Objective-C из Swift доступны,
но через специальный синтаксис. Селектор (имя сообщения, см. главу 5) в
Swift записывают через `#selector`:

```swift
// Swift-сторона (иллюстрация)
button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
```

А чтобы метод вообще годился в `#selector`, он должен быть `@objc` —
ведь `#selector` опирается на objc-runtime. Так же и KVC
(`value(forKey:)`, глава 20) работает из Swift только по `@objc`-членам:
без objc-видимости runtime просто не найдёт свойство по строковому имени.

> **Отличие от Си.** В Си нет ни селекторов, ни доступа к полю по строке-
> имени: всё прибито на этапе компиляции. `#selector` и KVC живут только
> потому, что под Swift в этих местах работает objc-runtime. Граница со
> Swift — это ещё и граница между «всё известно заранее» (Си) и «имена
> разрешаются во время выполнения» (objc-runtime).

## Современная связка: как смешать языки в проекте

Соберём по шагам, концептуально (Xcode сделает большую часть сам).

**Добавить Swift-файл в старый Objective-C-проект:**

1. В Xcode `File → New → File → Swift File`. Xcode заметит, что проект
   objc-шный, и предложит создать bridging header — **соглашайся**.
2. В появившийся `ИмяПроекта-Bridging-Header.h` впиши `#import` тех
   objc-заголовков, которые нужны Swift-коду.
3. Пиши Swift-класс. Чтобы потом звать его из Objective-C, наследуй от
   `NSObject` и помечай `@objc` (или `@objcMembers`).
4. В `.m`-файле, где зовёшь Swift, подключи `#import "ИмяПроекта-Swift.h"`
   — этот заголовок Xcode генерирует сам при каждой сборке.

**Добавить Objective-C-файл в Swift-проект:** `File → New → File →
Objective-C File`, согласиться на bridging header, вписать туда
`#import "ТвойКласс.h"` — и зови objc-класс из Swift напрямую (`import` не
нужен). Аннотируй заголовок (`NS_ASSUME_NONNULL_BEGIN`, дженерики у
коллекций, `NS_SWIFT_NAME`) — и Swift-сторона станет аккуратной, как мы
разбирали всю главу.

Ключевая мысль: направление «ObjC → Swift» идёт через **bridging header**
(или module map у фреймворка), а «Swift → ObjC» — через автогенерируемый
**`-Swift.h`** плюс пометки `@objc`. Два канала, по одному в каждую
сторону.

## Проверяем

Файлы главы — `code/23-bridgeable.m` и `code/23-annotations.m`. Оба —
настоящая objc-сторона моста; собираются обычной командой
`clang -fobjc-arc -framework Foundation code/23-*.m -o ...` и запускаются.
Ожидаемый вывод обоих показан выше (дата и числа в скобках будут свои).
Swift-блоки в главе — иллюстративные: их собирать нечем, и в `code/` они
не лежат. Но именно ради них мы и расставляли все эти аннотации.

## Частые ошибки

- **Забыл `@objc` на Swift-классе/методе** — и из Objective-C он не
  виден, `-Swift.h` про него молчит. Нужен `@objc` (или `@objcMembers`)
  и наследование от `NSObject`.
- **Не аннотировал nullability** — Swift подставит неявно развёрнутые
  опционалы (`String!`), и приложение упадёт на первом же неожиданном
  `nil`. Оборачивай заголовок в `NS_ASSUME_NONNULL_BEGIN/END`.
- **Забыл дженерик у коллекции** — `NSArray *` приедет как `[Any]`, и в
  Swift каждый элемент придётся приводить к типу. Пиши
  `NSArray<Product *> *`.
- **Ждёшь, что Swift-`struct`/enum-с-ассоциированными-значениями увидит
  Objective-C** — не увидит. Эти типы невыразимы в objc; мости через
  класс-наследник `NSObject`.
- **Не пометил метод `@objc`, а зовёшь его в `#selector` или через KVC**
  — runtime его не найдёт. Динамика Objective-C требует objc-видимости.
- **Поставил `NS_SWIFT_NOTHROW` там, где `error:` действительно сигналит
  провал** — потерял удобный `try/catch`. Отменяй throws только когда
  `BOOL`/возврат — это смысловой результат, а не «успех».

## Упражнения

1. Добавь в `ShoppingCart` свойство `nullable NSString *giftMessage` и
   метод `- (void)clear;`. Напиши рядом (в комментарии) иллюстративный
   Swift-блок: как эти члены выглядели бы в Swift.
2. В `PaletteColor` добавь метод `- (PaletteColor *)blendedWith:(PaletteColor *)other;`
   и подбери ему красивое Swift-имя через `NS_SWIFT_NAME` (например,
   `blended(with:)`). Скомпилируй objc-сторону.
3. Сделай метод `- (nullable NSData *)exportConfig:(NSError **)error;` и
   объясни в комментарии, почему в Swift он станет throwing и почему
   возврат перестанет быть опционалом.
4. Объясни своими словами, чем bridging header отличается от
   автогенерируемого `-Swift.h` и почему в смешанном проекте нужны оба.

## Что мы получили

Ты увидел мост между Objective-C и Swift не как магию, а как набор
понятных правил. Objective-C виден из Swift через bridging header (или
umbrella header + module map у фреймворка) — Swift читает `.h` напрямую.
Swift виден из Objective-C через автогенерируемый `-Swift.h`, и только то,
что помечено `@objc` и живёт в объектной модели. Между сторонами
автоматически переводятся типы: `NSString` ↔ `String`, дженерик-коллекции
↔ массивы и словари, nullable/nonnull ↔ опционалы, блоки ↔ замыкания,
`NSError**` ↔ `throws`. А `NS_SWIFT_NAME`, `NS_NOESCAPE`,
`NS_SWIFT_NOTHROW` позволяют точно причесать имена под Swift.

Теперь понятно и зачем была глава 22: nullability и дженерики — это не
украшение заголовка, а материал, из которого строится безопасная и
красивая Swift-сторона. Хорошо аннотированный Objective-C из Swift
неотличим от написанного на Swift — в этом весь смысл моста.

На этом основная часть книги завершается: ты прошёл путь от первой строки
на Си до того, как объект во время выполнения находит метод, и до стыка
двух языков Apple. В приложениях ждут дерево классов Foundation и
шпаргалка по синтаксису — возвращайся к ним за справкой.

## Документация Apple

- Importing Objective-C into Swift — developer.apple.com →
  «Importing Objective-C into Swift» (bridging header, module map).
- Importing Swift into Objective-C — developer.apple.com →
  «Importing Swift into Objective-C» (`-Swift.h`, `@objc`, `@objcMembers`).
- Migrating Your Objective-C Code to Swift — developer.apple.com →
  руководство по постепенному переносу кода.
- Cocoa Design Patterns — developer.apple.com → «Programming with
  Objective-C» → Cocoa-паттерны (инициализаторы, делегаты, ошибки).
- NS_SWIFT_NAME и группа макросов — developer.apple.com → «Customizing
  Your Objective-C APIs» / справочник по `swift_name` и nullability.
