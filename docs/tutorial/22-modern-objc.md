# Глава 22. Современный Objective-C

Язык, который ты прошёл за двадцать одну главу, написан в конце 1980-х.
Но писать на нём сегодня — совсем не то же самое, что писать на нём
тогда. За годы Apple добавила в Objective-C целый слой удобств и
страховок: короткие литералы вместо громоздких вызовов, типобезопасные
перечисления вместо голых `enum`, аннотации `nullable`/`nonnull`, чтобы
описать, где допустим `nil`, дженерики у коллекций, проверку версии ОС
прямо в коде. Часть этого уже мелькала в прошлых главах поодиночке.
Теперь соберём «современное лицо» языка в одном месте и разберём каждый
знак.

Главное, что объединяет всё в этой главе: **компилятор начинает ловить
больше ошибок за тебя**. Раньше многое всплывало только в рантайме
падением или мусором на экране — теперь `clang` ругается ещё на этапе
сборки. В конце главы мы возьмём наивный класс из ранних глав и
«осовременим» его, наблюдая, как с каждой аннотацией компилятор
становится строже.

## Что мы сделаем

- Сведём в одну таблицу литералы и субскрипты и увидим, что это сахар
  над обычными методами; добавим субскрипт в свой класс.
- Заменим голый `enum` на `NS_ENUM` и битовые флаги на `NS_OPTIONS`.
- Опишем контракт по `nil` через `nullable`/`nonnull` и макросы
  `NS_ASSUME_NONNULL_BEGIN/END`.
- Навесим на коллекции дженерики `NSArray<NSString *> *`.
- Вспомним `instancetype` и пометим назначенный инициализатор
  `NS_DESIGNATED_INITIALIZER`.
- Проверим версию ОС через `@available`.
- Подключим Foundation модулем `@import`.
- Соберём всё это в одном осовремененном классе.

## Литералы и субскрипты — сводка

Литерал-строку `@"..."` ты используешь с главы 1, а литералы коллекций
`@[]` и `@{}` — с главы 9 (подробно они разобраны в главе 17). Здесь
важно понять одну мысль: **каждый литерал и каждый субскрипт — это просто
короткая запись обычного вызова метода**. Компилятор разворачивает её сам.

Вот вся «короткая запись» в одном списке:

```objc
NSNumber *n     = @42;          // [NSNumber numberWithInt:42]
NSNumber *flag  = @YES;         // [NSNumber numberWithBool:YES]
NSNumber *pi    = @3.14;        // [NSNumber numberWithDouble:3.14]
NSString *s     = @"строка";    // объект NSString
NSArray  *arr   = @[@"a", @"b"];        // массив
NSDictionary *d = @{@"one": @1};        // словарь
NSNumber *boxed = @(x + y);     // @() — упаковка любого выражения
```

Знак `@` здесь каждый раз говорит: «то, что справа, — это объект
Objective-C, а не голое си-значение». `@42` — это не число `int`, а
полноценный объект `NSNumber`, которому можно слать сообщения.

Субскрипты — квадратные скобки доступа — тоже сахар:

```objc
arr[1]          // = [arr objectAtIndexedSubscript:1]
m[1] = @"b";    // = [m setObject:@"b" atIndexedSubscript:1]
d[@"one"]       // = [d objectForKeyedSubscript:@"one"]
md[@"k"] = @1;  // = [md setObject:@1 forKeyedSubscript:@"k"]
```

Здесь `m` — это `NSMutableArray *`, а `md` — `NSMutableDictionary *`. У
неизменяемых `NSArray`/`NSDictionary` метода записи нет, и строка
`arr[1] = @"b";` не соберётся: `expected method to write array element
not found on object of type 'NSArray *'`. Для чтения у `NSArray` метод
`objectAtIndexedSubscript:` делает то же, что привычный `objectAtIndex:`,
а `objectForKeyedSubscript:` у словаря — то же, что `objectForKey:`.

То есть скобки бывают двух видов, и компилятор различает их по типу
ключа:

- **индексный субскрипт** (`arr[i]`, ключ — целое число) раскрывается в
  `objectAtIndexedSubscript:` для чтения и
  `setObject:atIndexedSubscript:` для записи;
- **ключевой субскрипт** (`d[key]`, ключ — объект) раскрывается в
  `objectForKeyedSubscript:` и `setObject:forKeyedSubscript:`.

> **Отличие от Си.** В Си `arr[i]` — это адресная арифметика: `*(arr + i)`,
> прямой доступ к байтам в памяти, без всякой проверки. В Objective-C
> `arr[i]` для объекта — это вызов метода: runtime найдёт
> `objectAtIndexedSubscript:` и выполнит его, со всеми проверками границ
> внутри. Одинаковые скобки, совершенно разная механика.

### Свой субскрипт

Раз субскрипт — это просто пара методов, мы можем поддержать его в любом
своём классе. Достаточно объявить нужные методы — и `obj[0]` заработает.
Сделаем «полку» с ячейками:

```objc
@interface Shelf : NSObject
- (instancetype)initWithCapacity:(NSUInteger)capacity;
- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;
@end
```

Объявив именно эти два метода с такими именами, мы включаем синтаксис
`shelf[i]`. Реализация хранит элементы в обычном `NSMutableArray`, но с
проверкой границ:

```objc
- (id)objectAtIndexedSubscript:(NSUInteger)index {
    if (index >= _slots.count) {
        return @"(нет такой полки)";   // не падаем на выходе за границу
    }
    return _slots[index];
}

- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index {
    if (index < _slots.count) {
        _slots[index] = object;
    }
}
```

Теперь снаружи класс ведёт себя как массив:

```objc
Shelf *shelf = [[Shelf alloc] initWithCapacity:3];
NSLog(@"новая полка[0] = %@", shelf[0]);  // objectAtIndexedSubscript:
shelf[0] = @"книга";                       // setObject:atIndexedSubscript:
shelf[1] = @"чашка";
NSLog(@"полка[9] = %@", shelf[9]);        // выход за границы — не падаем
```

Полный файл — `code/22-literals-subscript.m`. Реальный вывод:

```text
число 42, флаг 1, пи 3.14
строка: строка
arr[1] = b
d["two"] = 2
сумма в коробке: 12
новая полка[0] = (пусто)
полка[0] = книга, полка[1] = чашка
полка[9] = (нет такой полки)
```

Обрати внимание: `@YES` напечаталось как `1` — внутри `NSNumber` булево
хранится как число. А `shelf[9]` не уронил программу, потому что мы сами
проверили границу внутри метода-субскрипта.

## NS_ENUM — типобезопасные перечисления

В главе 7 `NS_ENUM` упоминался только мимоходом, как обещание. Теперь
разберём, что это и зачем.

Раньше состояния кодировали голым си-`enum`:

```objc
enum { TaskTodo, TaskInProgress, TaskDone };   // старый способ
```

Проблема в том, что у такого `enum` **нет своего типа**. Это просто набор
именованных целых. Переменную под него ты заведёшь как `int` или
`NSInteger`, и компилятор не будет следить, что туда кладут именно
значения этого перечисления. Можно по ошибке присвоить `42`, и никто не
возразит.

`NS_ENUM` чинит это наполовину. Он одновременно задаёт **имя типа** и
**тип хранения**:

```objc
typedef NS_ENUM(NSInteger, TaskStatus) {
    TaskStatusTodo,         // 0
    TaskStatusInProgress,   // 1
    TaskStatusDone,         // 2
};
```

Разберём строку `NS_ENUM(NSInteger, TaskStatus)`:

- первый аргумент `NSInteger` — **на чём хранить** значения (целое
  машинного размера);
- второй аргумент `TaskStatus` — **имя нового типа**.

Теперь переменная `TaskStatus st;` имеет настоящий тип. Что это даёт:

1. **Документирование.** По сигнатуре `- (void)setStatus:(TaskStatus)st`
   сразу видно, какие значения уместны.
2. **Проверка `switch`.** Если в `switch` по `TaskStatus` забыть один из
   случаев, компилятор предупредит (`-Wswitch`). Для голого `int` он
   молчит — ему не из чего узнать полный список.
3. **Мост в Swift.** `NS_ENUM` приезжает в Swift настоящим `enum`
   (`TaskStatus.inProgress`), а голый си-`enum` — нет. Подробнее о мосте —
   в главе 23.

Одного `NS_ENUM` не делает: запретить присвоить «чужое» число он не может.
Строка `TaskStatus st = 42;` соберётся даже с `-Wall -Wextra` без единого
предупреждения (мы проверили) — правила Си для `enum` никуда не делись.
Тип помогает читать код и проверять `switch`, но не стережёт присваивания.

Превращаем статус в текст и пользуемся защитой `switch`:

```objc
static NSString *statusName(TaskStatus status) {
    switch (status) {
        case TaskStatusTodo:        return @"в очереди";
        case TaskStatusInProgress:  return @"в работе";
        case TaskStatusDone:        return @"готово";
    }
    return @"?";
}
```

Если ты допишешь в перечисление `TaskStatusCancelled`, но забудешь
добавить его в этот `switch`, `clang` скажет прямо при сборке:

```text
warning: enumeration value 'TaskStatusCancelled' not handled in switch
```

То есть компилятор напоминает обновить все разборы статуса. С голым `int`
такого напоминания нет — ошибка дожила бы до рантайма.

> **Отличие от Си.** В Си `enum` — это просто способ дать имена
> целым числам; под капотом это `int`, и никакой типобезопасности нет:
> любое целое влезет в `enum`-переменную без возражений. `NS_ENUM`
> поверх того же си-механизма добавляет настоящий именованный тип, на
> который опираются и компилятор (проверка `switch`), и Swift (честный
> `enum` при импорте). Сама форма записи остаётся си-совместимой —
> `NS_ENUM` разворачивается в `typedef enum` с явным типом хранения:
> `enum TaskStatus : NSInteger { ... }` плюс служебный атрибут для Swift.

## NS_OPTIONS — битовые флаги

Иногда значение — не одно из списка, а **набор** одновременно: права
«чтение И запись», стороны выравнивания «слева И сверху». Это битовые
маски, и для них есть `NS_OPTIONS`.

Выглядит почти как `NS_ENUM`, но значения — степени двойки, чтобы каждое
занимало свой отдельный бит:

```objc
typedef NS_OPTIONS(NSUInteger, Permissions) {
    PermissionNone   = 0,        // 0000
    PermissionRead   = 1 << 0,   // 0001
    PermissionWrite  = 1 << 1,   // 0010
    PermissionDelete = 1 << 2,   // 0100
    PermissionAll    = PermissionRead | PermissionWrite | PermissionDelete,
};
```

Запись `1 << 0`, `1 << 1`, `1 << 2` — это **сдвиг влево**: берём единицу и
двигаем её на 0, 1, 2 разряда. Получаем `0001`, `0010`, `0100` — по одному
поднятому биту в каждом флаге. Тип хранения здесь `NSUInteger` —
беззнаковое целое, потому что биты, а не «номер из списка».

Два оператора работают с такими флагами:

- `|` (ИЛИ) — **собрать** флаги вместе: `Read | Write` поднимет оба бита.
- `&` (И) — **проверить**, поднят ли бит: `perms & Read` даст ненулевое
  значение, если чтение разрешено.

Соберём права и проверим их по отдельности:

```objc
// 0001 | 0010 = 0011, то есть 3
Permissions perms = PermissionRead | PermissionWrite;

if (perms & PermissionRead)   { NSLog(@"можно читать"); }
if (perms & PermissionDelete) { /* не сработает: бита нет */ }
```

Добавить флаг — `|=`. Снять флаг — `&=` с инверсией `~` (она переворачивает
все биты, так что `& ~Write` гасит именно бит записи):

```objc
perms |= PermissionDelete;     // выдали право на удаление
perms &= ~PermissionWrite;     // отозвали право на запись
```

Полный пример — `code/22-enum-options.m`. Реальный вывод:

```text
статус: в работе (код 1)
маска прав: 3
можно читать
удалять нельзя
после выдачи delete маска: 7
полные права? да
после отзыва write маска: 5
```

Проследи числа: `Read|Write` = `3` (биты 0011); после `|= Delete` стало
`7` (0111) — это и есть `PermissionAll`; после `&= ~Write` осталось `5`
(0101 — чтение и удаление). Маска — это просто число, где каждый бит =
один флаг.

`NS_OPTIONS` от `NS_ENUM` отличается ровно намерением: первое — «можно
комбинировать через `|`», второе — «ровно одно значение из списка».
Компилятор и Swift это намерение учитывают (в Swift `NS_OPTIONS`
приезжает как `OptionSet`).

## Nullability — где допустим nil

Указатель на объект может быть `nil`. Но из объявления
`- (NSString *)name;` не видно: метод **гарантирует** строку или **может**
вернуть `nil`? Долгие годы это знание жило только в голове автора и в
документации. Аннотации **nullability** позволяют записать его прямо в коде.

Два главных слова:

- `nonnull` — «здесь `nil` не бывает». Контракт: и не передавай `nil`, и
  не жди его в ответ.
- `nullable` — «здесь `nil` допустим». Надо проверять.

Есть ещё два, реже:

- `null_unspecified` — «не указано» (нейтральное состояние, как было до
  аннотаций);
- `null_resettable` — особый случай для свойств: геттер всегда вернёт
  значение, но сеттеру **можно** передать `nil`, чтобы сбросить к
  значению по умолчанию (классика — `tintColor` в UIKit).

Применяют их к свойствам и параметрам:

```objc
@property (nonatomic, copy, nonnull)  NSString *name;   // всегда есть
@property (nonatomic, copy, nullable) NSString *email;  // может быть nil

- (void)sendTo:(nonnull NSString *)address
          body:(nullable NSString *)body;
```

В типах-указателях внутри сложных объявлений (например, в параметрах
функций Си или в указателях на указатели) пишут подчёркнутые варианты
`_Nonnull` и `_Nullable` — они ставятся прямо рядом со звёздочкой:

```objc
NSString * _Nullable findName(NSDictionary * _Nonnull dict);
```

Размечать каждый указатель утомительно. Поэтому почти весь код по
умолчанию считают `nonnull`, а явно помечают лишь исключения. Для этого
есть пара макросов-«скобок»:

```objc
NS_ASSUME_NONNULL_BEGIN
// ... здесь всё nonnull по умолчанию,
// помечаем только то, что nullable ...
NS_ASSUME_NONNULL_END
```

Между `BEGIN` и `END` каждый объектный указатель без явной пометки
считается `nonnull`. Это резко сокращает шум: вместо десятка `nonnull`
ты пишешь один `nullable` там, где `nil` действительно возможен.

Зачем всё это, если в рантайме `nil` всё равно проглатывается молча?

1. **Контракт в коде.** Объявление само рассказывает, чего ждать. Не надо
   лезть в документацию.
2. **Предупреждения компилятора.** Передал `nil` туда, где объявлен
   `nonnull`, — `clang` предупредит. Это ловит ошибку до запуска.
3. **Мост в Swift.** Это главный приз. `nonnull`-тип приезжает в Swift как
   обычный `String`, а `nullable` — как опционал `String?`. Без аннотаций
   Swift вынужден импортировать всё как «неявно развёрнутый опционал»
   `String!` — небезопасно. Аннотируя Objective-C, ты делаешь его
   удобным и безопасным со стороны Swift (тизер главы 23).

> **Отличие от Си.** В Си указатель либо валидный, либо `NULL`, и язык
> никак не помогает отличить одно от другого — разыменование `NULL`
> просто роняет программу в рантайме. Nullability добавляет к указателю
> «настроение»: компилятор знает, где `nil` ожидаем, а где нет, и
> предупреждает заранее. Сам указатель в памяти при этом не меняется —
> это чистая подсказка на этапе компиляции.

## Lightweight generics — дженерики у коллекций

`NSArray` хранит `id` — любые объекты. Из объявления `NSArray *names;` не
видно, что внутри строки. Достанешь элемент — получишь `id`, и компилятор
пропустит к нему любое сообщение, даже бессмысленное.

**Lightweight generics** (облегчённые дженерики) позволяют указать тип
элементов в угловых скобках:

```objc
NSArray<NSString *> *names;                       // массив строк
NSMutableArray<NSNumber *> *scores;               // изменяемый массив чисел
NSDictionary<NSString *, NSNumber *> *salaries;   // ключ-строка → число
NSSet<NSURL *> *links;                            // множество URL
```

Что это даёт:

- При чтении элемент имеет конкретный тип, а не `id`:
  `NSString *first = names[0];` — компилятор знает, что это строка, и
  подскажет её методы.
- При записи проверяется тип: положить `NSNumber` в
  `NSArray<NSString *>` — предупреждение.

Например:

```objc
NSMutableArray<NSString *> *skills = [NSMutableArray array];
[skills addObject:@"Swift"];   // ок
[skills addObject:@42];        // warning: несовместимый тип элемента
```

Слово «облегчённые» здесь ключевое. **Эти аннотации существуют только для
компилятора и стираются в рантайме.** В памяти `NSArray<NSString *>` —
тот же самый `NSArray`, что хранит `id`. Никакой проверки типов во время
выполнения дженерики не добавляют: если очень захотеть, через `id` или
приведение можно положить «не тот» объект, и рантайм это пропустит.
Дженерики — это страховка на этапе сборки, не больше.

Свой класс тоже можно сделать обобщённым, объявив параметр типа в угловых
скобках у `@interface`. Параметр иногда помечают `__covariant`
(ковариантный) — это говорит компилятору, что `Box<NSString *> *` можно
использовать там, где ждут `Box<id> *` (по той же логике, по которой
`NSArray<NSString *> *` подходит под `NSArray<id> *`):

```objc
@interface Box<__covariant T> : NSObject
- (void)put:(T)value;
- (T)get;
@end
```

Здесь `T` — заполнитель: при объявлении `Box<NSNumber *> *b` компилятор
подставит вместо `T` тип `NSNumber *` и будет проверять `put:`/`get`
именно по нему. Но, как и у коллекций, в рантайме `T` исчезает.

> **Отличие от Си.** В Си нет ни коллекций-объектов, ни дженериков —
> массив там это кусок одинаковых байтов фиксированного типа, и точка.
> А `NSArray<NSString *>` — это не шаблон в духе C++ `std::vector<T>`,
> который порождает отдельный машинный код под каждый тип. Это лишь
> подсказка компилятору, стираемая после проверки: один и тот же класс
> `NSArray` в рантайме, разные аннотации в исходнике.

## instancetype вместо id

`instancetype` мы подробно разбирали в главе 7, здесь — короткое
напоминание в общем ряду «современных» вещей.

У инициализаторов и фабричных методов тип возврата пишут не `id`, а
`instancetype`:

```objc
- (instancetype)initWithName:(NSString *)name;
+ (instancetype)personWithName:(NSString *)name;
```

`instancetype` означает «объект **того самого** класса, у которого вызвали
метод». Разница с `id` — в точности типа на этапе компиляции.

Тонкость, которую легко упустить: для методов семейства `init` (и для
`alloc`, `new`) clang выводит точный тип сам, даже если написано `id`.
Мы проверили: с `- (id)init` строка `[[[Person alloc] init] length]` всё
равно даёт ошибку `no visible @interface for 'Person' declares the
selector 'length'`. А вот у фабрики вроде `+ (id)personWithName:` такого
вывода нет: `[[Person personWithName:@"A"] length]` соберётся молча и
упадёт уже в рантайме. С `+ (instancetype)personWithName:` та же строка
станет ошибкой компиляции. Поэтому правило простое: для всего, что
создаёт и возвращает экземпляр своего класса, пиши `instancetype` —
и у `init`, и у фабрик, чтобы не держать в голове, где вывод сработает.

## NS_DESIGNATED_INITIALIZER — назначенный инициализатор

Назначенный инициализатор (designated initializer) — тот главный `init`,
через который проходит вся настройка объекта; остальные инициализаторы
обязаны звать его. Понятие из главы 7. Современный синтаксис позволяет
**пометить** такой инициализатор, и компилятор начнёт следить за
правилами:

```objc
- (instancetype)initWithName:(NSString *)name
                      status:(EmployeeStatus)status NS_DESIGNATED_INITIALIZER;
```

Что проверяет компилятор, увидев эту пометку:

- любой другой инициализатор класса должен в итоге вызвать назначенный
  (а не `[super init]` напрямую) — иначе предупреждение;
- назначенный инициализатор должен вызвать назначенный инициализатор
  родителя через `super`;
- назначенный инициализатор родителя (у `NSObject` это `init`) нужно
  переопределить в своём классе — или объявить недоступным. Иначе
  `clang` предупредит: `method override for the designated initializer
  of the superclass '-init' not found`.

Последнее правило и объясняет частую пару: рядом с назначенным
инициализатором запрещают «голый» `init`, чтобы заставить пользоваться
полноценным конструктором:

```objc
- (instancetype)init NS_UNAVAILABLE;
```

`NS_UNAVAILABLE` помечает метод недоступным. Теперь `[[Person alloc] init]`
не скомпилируется — компилятор направит к `initWithName:status:`. Это
прямой пример темы главы: больше ошибок ловится при сборке.

## @available — проверка версии ОС

Новые классы и методы появляются в конкретных версиях macOS/iOS. Если
твоя программа должна работать и на старых системах, нельзя слепо звать
свежий API — на старой ОС его просто нет. Проверку версии делают прямо в
коде через `@available`:

```objc
if (@available(macOS 12.0, iOS 15.0, *)) {
    // здесь можно звать API, появившиеся в macOS 12 / iOS 15
} else {
    // запасной путь для старых систем
}
```

Разберём `@available(macOS 12.0, iOS 15.0, *)`:

- `macOS 12.0`, `iOS 15.0` — минимальные версии для каждой платформы;
- `*` — «на всех остальных платформах (tvOS, watchOS, будущих) условие
  считается выполненным». Звёздочка обязательна — она про платформы,
  которые ты явно не перечислил.

Условие истинно, когда программа выполняется на версии не ниже указанной.
Пара с `@available` — атрибут `API_AVAILABLE(...)`, которым помечают
собственные методы/классы, доступные только с определённой версии; тогда
компилятор предупредит о каждом вызове, не обёрнутом в `@available`
(`'Future' is only available on macOS 30.0 or newer`).

Проверим на живом примере (`code/22-available.m`). Создание
`NSISO8601DateFormatter` (появился в macOS 10.12) обернём в проверку:

```objc
if (@available(macOS 10.12, *)) {
    NSISO8601DateFormatter *fmt = [[NSISO8601DateFormatter alloc] init];
    NSString *now = [fmt stringFromDate:[NSDate date]];
    NSLog(@"сейчас по ISO-8601: %@", now);
} else {
    NSLog(@"ISO-8601 форматтер недоступен на этой ОС");
}
```

Реальный вывод (дата будет своя):

```text
ОС достаточно свежая: можно звать новые API
macOS пока младше 99 — используем старый код
сейчас по ISO-8601: 2026-06-28T07:45:33Z
```

Первая ветка сработала (система свежее macOS 12), вторая — проверка на
заведомо будущую macOS 99 — ушла в `else`, третья создала форматтер,
потому что 10.12 давно позади.

## Модули: @import вместо #import

Весь код книги начинается с `#import <Foundation/Foundation.h>`. Есть
более современная запись — **импорт модуля**:

```objc
@import Foundation;
```

Одна строка вместо подключения заголовка. Разница не только в краткости:

- `#import` текстово вставляет заголовок и заново разбирает его в каждом
  файле; модуль компилируется один раз и кешируется — сборка идёт
  **быстрее**;
- модуль несёт информацию о том, с какой библиотекой линковаться, поэтому
  флаг `-framework Foundation` при `@import` часто не нужен —
  **автолинковка**;
- можно импортировать отдельный подмодуль: `@import Foundation.NSString;`.

У `@import` есть нюанс компиляции: ему нужен флаг `-fmodules`. Без него
clang говорит прямым текстом:

```text
file.m:1:1: error: use of '@import' when modules are disabled
    1 | @import Foundation;
      | ^
```

В Xcode модули включены по умолчанию, а в нашей «голой» команде из
терминала их надо включить явно:

```text
clang -fobjc-arc -fmodules -framework Foundation -O2 file.m -o file
```

Поэтому файлы-примеры в книге оставлены на привычном `#import` — чтобы
собираться той же командой, что и везде. Но знать `@import` полезно: в
реальном Xcode-проекте он встречается часто, и теперь он тебя не удивит.

> **Отличие от Си.** `#import` (как и си-шный `#include`) — это работа
> препроцессора: грубая текстовая подстановка содержимого файла. `@import`
> — другое: компилятор подключает уже разобранный, заранее собранный
> образ библиотеки. В чистом Си модулей нет — там только текстовое
> включение заголовков.

## KVO и dispatch блоками — пара слов

Две темы из прошлых глав — и обе упираются в блоки.

**KVO** (наблюдение за свойствами, глава 20) в Objective-C так и остался
на методе `observeValueForKeyPath:ofObject:change:context:` — с ручным
`context`-указателем и одним общим обработчиком на все ключи. Блочного
KVO в Foundation для Objective-C нет. Удобный вариант с замыканием —
`observe(_:options:changeHandler:)`, возвращающий `NSKeyValueObservation`, —
существует только в Swift. Если в objc-коде хочется обработчик-блок прямо
у подписки, берут уведомления `NSNotificationCenter`: у него есть метод
`addObserverForName:object:queue:usingBlock:`.

```objc
id token = [[NSNotificationCenter defaultCenter]
    addObserverForName:@"StatusChanged"
                object:nil
                 queue:nil
            usingBlock:^(NSNotification *note) {
    NSLog(@"статус изменился: %@", note.userInfo[@"status"]);
}];
```

Обработчик-блок (глава 12) лежит прямо рядом с подпиской и замыкает нужные
переменные. Возвращённый `token` потом передают в `removeObserver:`, чтобы
отписаться.

**Dispatch** — Grand Central Dispatch из главы 21 — изначально построен на
блоках: `dispatch_async(queue, ^{ ... })` принимает блок с работой.
Старый стиль с `NSThread` и отдельными методами-точками входа уступил
место очередям и блокам. Общий мотив один: **современный Objective-C
тяготеет к блокам** — код-обработчик пишут на месте, а не отдельным
методом где-то в стороне.

## Строим с нуля: осовремениваем класс

Соберём всё вместе. Возьмём наивный `Person` из главы 7 — у него был
голый `init`, ivars без проверок и никаких аннотаций — и шаг за шагом
сделаем из него современный класс, наблюдая, как растёт строгость
компилятора.

### Шаг 1. Что было

Исходный класс из главы 7 выглядел так:

```objc
@interface Person : NSObject {
    NSString *_name;
    NSInteger _age;
}
- (instancetype)init;
- (void)describe;
@end
```

Никаких подсказок: компилятор не знает, может ли `name` быть `nil`, какие
бывают статусы, что лежит в коллекциях. Всё это всплыло бы только в
рантайме.

### Шаг 2. Типы для статуса и прав

Добавим `NS_ENUM` для статуса сотрудника и `NS_OPTIONS` для прав доступа —
вместо того чтобы хранить их безымянными числами:

```objc
typedef NS_ENUM(NSInteger, EmployeeStatus) {
    EmployeeStatusActive,
    EmployeeStatusVacation,
    EmployeeStatusFired,
};

typedef NS_OPTIONS(NSUInteger, AccessRights) {
    AccessNone  = 0,
    AccessRead  = 1 << 0,
    AccessWrite = 1 << 1,
    AccessAdmin = 1 << 2,
};
```

### Шаг 3. Nullability и дженерики в интерфейсе

Оборачиваем интерфейс в `NS_ASSUME_NONNULL_BEGIN/END`, помечаем
единственное необязательное свойство `email` как `nullable`, а коллекциям
даём типы элементов:

```objc
NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject

@property (nonatomic, copy)   NSString *name;          // nonnull по умолчанию
@property (nonatomic, copy, nullable) NSString *email; // может быть nil
@property (nonatomic, assign) EmployeeStatus status;
@property (nonatomic, assign) AccessRights rights;

@property (nonatomic, strong) NSMutableArray<NSString *> *skills;
@property (nonatomic, strong)
    NSDictionary<NSString *, NSNumber *> *salaryByYear;

- (instancetype)initWithName:(NSString *)name
                      status:(EmployeeStatus)status NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSString *)objectAtIndexedSubscript:(NSUInteger)index;  // person[0]
- (void)describe;

@end

NS_ASSUME_NONNULL_END
```

За один интерфейс мы навесили на класс пять видов современных
аннотаций. Реализация назначенного инициализатора привычна, но теперь
`email` законно стартует с `nil`, а коллекции — пустыми:

```objc
- (instancetype)initWithName:(NSString *)name status:(EmployeeStatus)status {
    self = [super init];
    if (self) {
        _name = [name copy];
        _status = status;
        _email = nil;                  // nullable — это законно
        _rights = AccessRead;
        _skills = [NSMutableArray array];
        _salaryByYear = @{};
    }
    return self;
}
```

Субскрипт по навыкам — тот же приём, что у «полки» выше:

```objc
- (NSString *)objectAtIndexedSubscript:(NSUInteger)index {
    if (index >= self.skills.count) {
        return @"(нет навыка)";
    }
    return self.skills[index];
}
```

### Шаг 4. Смотрим, как компилятор ловит ошибки

Класс собран (`code/22-nullability-generics.m`). Теперь — главное ради
чего всё затевалось. Допиши в файл функцию с четырьмя намеренными
ошибками, собери — и почитай, что скажет компилятор. Ни одну из них
старый наивный класс из главы 7 не заметил бы.

```objc
Person *p1 = [[Person alloc] init];
```

```text
error: 'init' is unavailable
```

`NS_UNAVAILABLE` запретил голый `init`, и это **ошибка**: файл не
соберётся, пока не позовёшь `initWithName:status:`. Единственная из
четырёх, которая останавливает сборку.

```objc
p.name = nil;
```

```text
warning: null passed to a callee that requires a non-null argument
      [-Wnonnull]
```

`name` объявлен `nonnull` (по умолчанию внутри `NS_ASSUME_NONNULL_BEGIN`),
и передача `nil` ловится прямо в месте присваивания.

```objc
[p.skills addObject:@42];
```

```text
warning: incompatible pointer types sending 'NSNumber *' to parameter
      of type 'NSString * _Nonnull' [-Wincompatible-pointer-types]
```

Дженерик `NSMutableArray<NSString *>` не пускает число в массив строк —
и, обрати внимание, в тексте предупреждения виден и дженерик, и
подставленный `_Nonnull` из наших аннотаций.

```objc
switch (p.status) {
    case EmployeeStatusActive: break;
    case EmployeeStatusVacation: break;
}
```

```text
warning: enumeration value 'EmployeeStatusFired' not handled in switch
      [-Wswitch]
```

`NS_ENUM` заставляет `switch` покрыть все статусы и по имени называет
забытый.

Заметь: **три из четырёх диагностик — предупреждения, а не ошибки**. Программа с ними соберётся и
запустится. Компилятор не запрещает тебе писать так — он предупреждает,
что ты нарушаешь контракт, который сам же и объявил. Поэтому в серьёзных
проектах предупреждения не терпят: собирают с `-Werror`, превращающим их
в ошибки, и правят сразу. В этом и смысл «современного» Objective-C: ты
записываешь свои намерения в коде — а компилятор следит, чтобы их не
нарушали.

### Шаг 5. Запускаем правильную версию

Корректное использование собирается и работает:

```objc
Person *p = [[Person alloc] initWithName:@"Айгуль"
                                  status:EmployeeStatusActive];
p.email = @"aigul@example.kz";
p.rights = AccessRead | AccessWrite | AccessAdmin;
[p.skills addObject:@"Objective-C"];
[p.skills addObject:@"Swift"];
[p.skills addObject:@"SQL"];
[p describe];
NSLog(@"первый навык: %@", p[0]);     // субскрипт
```

Реальный вывод полного файла `code/22-nullability-generics.m` (там после
этого ещё читается несуществующий навык `p[9]`, зарплата из словаря и
создаётся второй сотрудник, «Аноним»):

```text
Айгуль [работает], aigul@example.kz, навыков: 3
  -> администратор
первый навык: Objective-C
навык №9: (нет навыка)
зарплата 2025: 620000
Аноним [в отпуске], почта не указана, навыков: 0
  -> только чтение
```

Заметь две детали: у «Анонима» `email` равен `nil`, и `describe`
аккуратно подставил «почта не указана» через `?:` — потому что мы заранее
знали (и пометили), что почта `nullable`. А `p[0]` достал первый навык
через наш субскрипт. Класс из главы 7 ничего из этого не умел.

## Проверяем

Файлы главы:

- `code/22-literals-subscript.m` — литералы, субскрипты, свой субскрипт.
- `code/22-enum-options.m` — `NS_ENUM` и `NS_OPTIONS`.
- `code/22-nullability-generics.m` — осовремененный `Person`.
- `code/22-available.m` — `@available`.

Компиляция и запуск каждого — той же командой, что и всю книгу:

```text
clang -fobjc-arc -framework Foundation -Wall -Wextra -O2 \
      code/22-enum-options.m -o /tmp/t && /tmp/t
```

Все четыре собираются без единого предупреждения. Чтобы попробовать
`@import Foundation;` из текста, добавь флаг `-fmodules`.

## Частые ошибки

- **Флаги `NS_OPTIONS` не степени двойки.** Если задать
  `PermissionWrite = 3`, его биты пересекутся с `Read` и `Write`, и
  проверки `&` начнут врать. Каждому флагу — свой отдельный бит
  (`1 << n`).
- **Ждать от дженериков рантайм-проверки.** `NSArray<NSString *>` не
  бросит исключение, если через `id` туда попадёт число, — аннотация
  стирается в рантайме. Это страховка компилятора, а не гарантия памяти.
- **`@available` без звёздочки.** `if (@available(macOS 12.0))` без `, *`
  не скомпилируется: звёздочка для неперечисленных платформ обязательна.
- **`NS_ASSUME_NONNULL_BEGIN` без `END`.** Макросы идут парой. Забыл
  `END` — поедет nullability в остальной части файла и посыплются
  странные предупреждения.
- **`@import` без `-fmodules`.** Вне Xcode появится ошибка `use of
  '@import' when modules are disabled`. Либо добавь флаг, либо вернись к
  `#import`.
- **Думать, что аннотации меняют рантайм.** `nullable`, дженерики,
  `instancetype` — всё это работает на этапе компиляции. Объект в памяти
  от них не меняется ни на байт.

## Упражнения

1. Добавь в `NS_ENUM TaskStatus` новое значение `TaskStatusCancelled` и
   собери `code/22-enum-options.m`, **не** дописывая `switch`. Прочитай
   предупреждение компилятора, потом добавь недостающий `case`.
2. Дай классу `Shelf` ещё и ключевой субскрипт: реализуй
   `objectForKeyedSubscript:` и `setObject:forKeyedSubscript:`, чтобы
   работало `shelf[@"полка-А"]`.
3. В `Person` объяви `email` как `nonnull` (убери `nullable`) и попробуй
   присвоить ему `nil`. Найди, на что ругается компилятор, и верни
   `nullable`.
4. Заведи свой обобщённый класс `Stack<T>` с методами `push:`/`pop` и
   проверь, что `Stack<NSString *>` не даёт положить `NSNumber`.
5. Оберни вызов любого свежего метода Foundation в `@available` и
   намеренно укажи будущую версию (`macOS 99.0, *`) — убедись, что
   срабатывает ветка `else`.
6. Перепиши `code/22-available.m` на `@import Foundation;` и собери его с
   `-fmodules`. Сравни, нужен ли при этом `-framework Foundation`.

## Что мы получили

Мы собрали «современное лицо» Objective-C: литералы и субскрипты как сахар
над методами (и свой субскрипт в придачу), типобезопасные `NS_ENUM` и
битовые `NS_OPTIONS`, аннотации nullability, облегчённые дженерики у
коллекций, `instancetype` и `NS_DESIGNATED_INITIALIZER`, проверку версии
`@available` и импорт модулей `@import`. Сквозная мысль одна: **ты
записываешь намерения в коде, а компилятор следит за их соблюдением** —
и ловит при сборке то, что раньше падало в рантайме.

Почти каждая из этих вещей придумана не в последнюю очередь ради дружбы со
Swift: `NS_ENUM` становится Swift-перечислением, `nullable` —
опционалом, дженерики — настоящими дженериками Swift. Это и есть мостик к
финальной главе. В главе 23 разберём, как два языка живут в одном проекте:
как Swift видит твой Objective-C-код и как Objective-C дотягивается до
Swift.

## Документация Apple

- Programming with Objective-C (литералы, субскрипты, инициализаторы) —
  developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html
- Adopting Modern Objective-C (`NS_ENUM`, `NS_OPTIONS`, `instancetype`,
  designated initializers) —
  developer.apple.com/library/archive/releasenotes/ObjectiveC/ModernizationObjC/AdoptingModernObjective-C/AdoptingModernObjective-C.html
- Designating Nullability in Objective-C APIs (аннотации nullability и
  мост в Swift-опционалы) —
  developer.apple.com/documentation/swift/designating-nullability-in-objective-c-apis
- Using Imported Lightweight Generics in Swift (обобщённые коллекции и
  свои обобщённые классы) —
  developer.apple.com/documentation/swift/using-imported-lightweight-generics-in-swift
- Marking API Availability in Objective-C (`@available`,
  `API_AVAILABLE`) —
  developer.apple.com/documentation/swift/marking-api-availability-in-objective-c
- Modules / `@import` (документация clang, не Apple) —
  clang.llvm.org/docs/Modules.html
