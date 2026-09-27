# Приложение B. Шпаргалка по синтаксису Objective-C

Это справочник, а не глава. Здесь всё коротко: листинг плюс одна-две
строки пояснения, чтобы быстро вернуться за синтаксисом. Если что-то
непонятно — соответствующая глава объясняет это подробно.

## Компиляция

```text
clang -fobjc-arc -framework Foundation -Wall -Wextra -O2 file.m -o prog
./prog
```

Основной режим: ARC включён, подключён Foundation, предупреждения видны.

- `-fobjc-arc` — включить ARC (автоподсчёт ссылок). Память объектов
  считает компилятор.
- `-framework Foundation` — подключить библиотеку `NSString`, `NSArray`,
  `NSLog` и прочих. Старые версии clang без неё ругались `Undefined
  symbols`; свежий Apple clang (по нашей проверке — clang 21 из Xcode 26)
  для `.m`-файлов подставляет её сам. В книге пишем флаг явно.
- `-Wall -Wextra` — показать предупреждения. Чистый код собирается без них.
- `-O2` — оптимизация. `-O0` или без флага — отладочная сборка.
- `-o prog` — имя результата. Без `-o` получится `a.out`.

```text
# ручная память (MRR):
clang -fno-objc-arc -framework Foundation file.m -o prog
# чистый Си (.c):
clang -std=c11 -Wall -Wextra -O2 file.c -o prog
```

`-fno-objc-arc` — отключить ARC, тогда `retain`/`release`/`autorelease`
зовёшь сам (глава 13). Си-файлы компилируются как обычный Си.

## Скелет программы

```objc
#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        NSLog(@"%@", @"Привет");
    }
    return 0;
}
```

`#import` подключает заголовок (не вставит дважды, в отличие от
`#include`). Объектная работа идёт внутри `@autoreleasepool` — пула
автоосвобождения для временных объектов.

## Отправка сообщений

```objc
[receiver message];              // без аргументов
[receiver message:a];            // один аргумент
[receiver message:a with:b];     // имя метода — message:with:
[obj doThis:[other doThat]];     // вложенный вызов: внутренний первый
id result = [array objectAtIndex:0];
SEL sel = @selector(setName:);   // селектор как значение
```

Квадратные скобки — отправка сообщения. Двоеточия — части имени метода
(`message:with:`). `@selector(name:)` берёт само имя метода значением
типа `SEL`. Сообщение к `nil` безопасно и возвращает `nil`/0.

> **Отличие от Си.** В Си `foo(obj, 5)` — адрес функции известен при
> компиляции. `[obj foo:5]` — runtime ищет метод во время выполнения.

## Объявление класса

```objc
// Counter.h
@interface Counter : NSObject {
    NSInteger _hidden;          // ivar (поле экземпляра), необязательно
}
@property (nonatomic, assign) NSInteger value;   // свойство
- (void)increment;              // метод экземпляра
+ (instancetype)counter;        // метод класса
@end

// Counter.m
@implementation Counter
- (void)increment { self.value += 1; }
+ (instancetype)counter { return [[self alloc] init]; }
@end
```

`@interface … @end` — объявление (что есть), `@implementation … @end` —
реализация (как работает). `-` — метод экземпляра, `+` — метод класса.
Ivar'ы для свойств генерируются автоматически как `_value`.

### Атрибуты @property

```objc
@property (nonatomic, copy)     NSString *name;
@property (nonatomic, strong)   NSArray  *items;
@property (nonatomic, weak)     id<MyDelegate> delegate;
@property (nonatomic, assign)   NSInteger count;
@property (nonatomic, readonly) BOOL ready;
@property (nonatomic, getter=isEnabled) BOOL enabled;
```

| Атрибут        | Когда применять                                            |
|----------------|------------------------------------------------------------|
| `strong`       | владеющая ссылка на объект (по умолчанию для объектов)      |
| `weak`         | невладеющая, обнуляется при удалении — для delegate, циклов |
| `copy`         | для `NSString`, блоков, изменяемых-в-неизменяемые — хранит копию |
| `assign`       | для скаляров (`NSInteger`, `BOOL`, `double`), без владения  |
| `atomic`       | потокобезопасный доступ к геттеру/сеттеру (по умолчанию)    |
| `nonatomic`    | без блокировок, быстрее — почти всегда ставят его           |
| `readonly`     | только геттер; `readwrite` (по умолчанию) — геттер и сеттер |
| `getter=name`  | задать имя геттера, частый случай — `isEnabled` для `BOOL`  |
| `setter=name:` | задать имя сеттера                                          |

`copy` для `NSString`-свойства обязателен: иначе кто-то передаст
`NSMutableString` и поменяет её у тебя за спиной.

## Создание объектов

```objc
Counter *c = [[Counter alloc] init];          // alloc + init
NSString *s = [[NSString alloc] initWithFormat:@"x=%d", 5];
NSArray  *a = [NSArray arrayWithObjects:@"a", @"b", nil];  // фабрика
Counter *c2 = [Counter counter];              // своя фабрика
```

`alloc` выделяет память, `init…` настраивает объект — всегда парой.
Фабричные методы (`+`) делают то же одним вызовом. Возвращают
`instancetype` — «объект этого же класса», поэтому тип сохраняется.

```objc
- (instancetype)initWithName:(NSString *)name {
    self = [super init];        // сначала инициализирует базовый класс
    if (self) {                 // проверка: super мог вернуть nil
        _name = [name copy];    // пишем напрямую в ivar
    }
    return self;
}
```

Канонический инициализатор: `self = [super init]`, проверка `if (self)`,
заполнение полей, `return self`. Назначенный инициализатор зовёт
`[super init…]`; остальные (удобные) зовут назначенный.

## Наследование

```objc
@interface Dog : Animal            // Dog наследует Animal
@end

@implementation Dog
- (NSString *)sound {
    NSString *base = [super sound]; // вызов версии родителя
    return [base stringByAppendingString:@" гав"];  // переопределение
}
@end
```

`: Super` после имени — наследование. `[super message]` зовёт реализацию
родителя. Переопределение — просто объявить метод с тем же именем.

## Протоколы

```objc
@protocol Drawing <NSObject>
- (void)draw;                       // @required по умолчанию
@optional
- (void)drawHighlighted;            // @optional — можно не реализовывать
@required
- (CGFloat)area;
@end

@interface Shape : NSObject <Drawing>   // класс принимает протокол
@end

id<Drawing> thing = someShape;          // «любой объект, умеющий Drawing»
```

```objc
if ([obj respondsToSelector:@selector(drawHighlighted)]) {
    [obj drawHighlighted];                          // проверка @optional
}
if ([obj conformsToProtocol:@protocol(Drawing)]) { … } // принят ли протокол
```

Протокол — список методов-обязательств. `<Drawing>` после класса —
«реализует». `id<Drawing>` — тип «любой объект с этим протоколом».
`@optional`-методы перед вызовом проверяй через `respondsToSelector:`.

## Категории и расширения

```objc
// Категория: добавить методы к существующему классу (даже чужому)
@interface NSString (Reversing)
- (NSString *)reversedString;
@end
@implementation NSString (Reversing)
- (NSString *)reversedString { … }
@end
```

```objc
// Расширение класса (анонимная категория) — приватные свойства/методы,
// объявляется в .m своего класса
@interface Counter ()
@property (nonatomic, assign, readwrite) BOOL ready;  // readonly наружу
- (void)privateHelper;
@end
```

Категория `Class (Name)` дописывает методы к готовому классу. Расширение
`Class ()` — для приватной начинки своего класса, добавляет и ivar'ы.

> **Отличие от Си.** В Си нельзя дописать функцию-метод к чужому `struct`.
> Категория добавляет методы к любому классу, включая `NSString`.

## Блоки

```objc
int (^add)(int, int) = ^(int a, int b) { return a + b; };  // переменная-блок
int r = add(2, 3);                                          // вызов: 5

typedef void (^Completion)(BOOL success);   // имя для типа блока
- (void)loadWithCompletion:(Completion)done;

NSArray *sorted = [arr sortedArrayUsingComparator:
    ^NSComparisonResult(id x, id y) { return [x compare:y]; }];
```

`^` объявляет блок — функцию с захватом окружающих переменных. По
умолчанию захваченные переменные доступны только для чтения.

```objc
__block int total = 0;                  // __block — можно менять внутри блока
void (^addUp)(int) = ^(int x) { total += x; };
addUp(2);
addUp(3);                               // total == 5

__weak typeof(self) weakSelf = self;    // разрыв retain cycle
self.handler = ^{ [weakSelf doWork]; }; // блок не удерживает self
```

`__block` — позволяет блоку менять переменную. `weakSelf`-паттерн нужен,
когда объект хранит блок, а блок зовёт `self`: иначе retain cycle.

## Память

```objc
@property (nonatomic, strong) Node *next;   // владеет: держит живым
@property (nonatomic, weak)   Node *parent; // не владеет: обнулится в nil

__strong id keep = obj;     // владеющая локальная (по умолчанию)
__weak   id watch = obj;    // слабая: станет nil, когда obj удалят
```

ARC сам считает strong-ссылки: пока есть хоть одна — объект жив. `weak`
не считается и автоматически становится `nil` после удаления цели.

Признаки retain cycle (два объекта держат друг друга strong и не
освобождаются): родитель↔ребёнок, объект хранит блок, зовущий `self`,
delegate объявлен `strong`. Лечение — сделать одну из ссылок `weak`.

```objc
for (int i = 0; i < 1000000; i++) {
    @autoreleasepool {          // пул внутри цикла, а не снаружи
        NSString *s = [NSString stringWithFormat:@"%d", i];
        (void)s;                // … работа с s …
        // временные объекты освобождаются на каждой итерации
    }
}
```

## Литералы

```objc
NSString     *s = @"text";
NSNumber     *i = @42;          // = [NSNumber numberWithInt:42]
NSNumber     *b = @YES;
NSNumber     *f = @3.14;
NSNumber     *e = @(1 + 2);     // @(выражение)
NSArray      *a = @[@"a", @"b", @"c"];
NSDictionary *d = @{@"key": @1, @"name": @"Bob"};
```

```objc
NSString *first = a[0];         // = [a objectAtIndexedSubscript:0]
NSNumber *one   = d[@"key"];    // = [d objectForKeyedSubscript:@"key"]
NSMutableArray *m = [a mutableCopy];
m[0] = @"z";                    // = [m setObject:@"z" atIndexedSubscript:0]
```

Знак `@` строит объект из обычного значения. Субскрипты `[i]`/`[key]` —
короткая запись доступа к элементам.

## Интроспекция

```objc
[obj isKindOfClass:[NSString class]];    // obj — NSString ИЛИ потомок
[obj isMemberOfClass:[NSString class]];  // ровно NSString, без потомков
[obj respondsToSelector:@selector(length)];  // есть ли такой метод
[obj class];                             // объект Class данного экземпляра
[a isEqual:b];                           // сравнение по значению
[s isEqualToString:@"x"];                // быстрее для строк
```

`isKindOfClass:` учитывает наследников, `isMemberOfClass:` — нет.
`isEqual:` сравнивает содержимое (а `==` — адреса/указатели).

## Частые типы

```objc
NSString  *s  = @"hi";
NSUInteger n  = s.length;
NSString  *up = [s uppercaseString];
NSString  *c  = [s stringByAppendingString:@"!"];
BOOL same = [s isEqualToString:@"hi"];

NSMutableString *ms = [@"a" mutableCopy];
[ms appendString:@"b"];                  // изменяемая строка
```

```objc
NSNumber *num = @42;
int  iv = num.intValue;
double dv = num.doubleValue;
BOOL  bv = num.boolValue;
```

```objc
NSArray<NSString *> *a = @[@"x", @"y"];
NSString *x = a[0];
NSUInteger cnt = a.count;
BOOL has = [a containsObject:@"x"];

NSMutableArray<NSString *> *ma = [a mutableCopy];
[ma addObject:@"z"];
[ma removeObjectAtIndex:0];

NSDictionary<NSString *, NSNumber *> *d = @{@"k": @1};
NSNumber *v = d[@"k"];

NSSet<NSString *> *set = [NSSet setWithArray:a];     // уникальные элементы
NSMutableSet *mset = [set mutableCopy];
[mset addObject:@"q"];
```

```objc
NSData *data = [@"hi" dataUsingEncoding:NSUTF8StringEncoding];
NSUInteger bytes = data.length;

NSDate *now = [NSDate date];
NSTimeInterval secs = [now timeIntervalSince1970];
```

### Паттерн NSError

```objc
- (BOOL)doWork:(NSError **)error {       // BOOL-результат + NSError**
    if (failed) {
        if (error) {
            *error = [NSError errorWithDomain:@"MyDomain"
                                         code:42
                                     userInfo:nil];
        }
        return NO;
    }
    return YES;
}

NSError *err = nil;
if (![obj doWork:&err]) {                // проверяй РЕЗУЛЬТАТ, не err
    NSLog(@"%@", err.localizedDescription);
}
```

Метод возвращает `BOOL`/объект, ошибку пишет в `*error`. Признак неудачи —
возвращённое `NO`/`nil`, а не сам `error`.

## Современный Objective-C

```objc
typedef NS_ENUM(NSInteger, Direction) {  // перечисление
    DirectionNorth,
    DirectionEast,
    DirectionSouth,
};

typedef NS_OPTIONS(NSUInteger, Options) {  // битовые флаги
    OptionNone  = 0,
    OptionBold  = 1 << 0,
    OptionItalic = 1 << 1,
};
Options o = OptionBold | OptionItalic;
```

`NS_ENUM` — типобезопасное перечисление, `NS_OPTIONS` — флаги под `|`.

```objc
NS_ASSUME_NONNULL_BEGIN          // всё внутри по умолчанию nonnull
@interface User : NSObject
@property (nonatomic, copy) NSString *name;            // nonnull
@property (nonatomic, copy, nullable) NSString *nick;  // может быть nil
- (nullable User *)friendNamed:(NSString *)name;
@end
NS_ASSUME_NONNULL_END
```

Nullability помечает, где `nil` допустим. Между `_BEGIN`/`_END` всё
считается `nonnull`, исключения метим `nullable`.

```objc
NSArray<NSString *> *names;                       // дженерик: массив строк
NSDictionary<NSString *, NSNumber *> *scores;     // строка → число
NSMutableArray<User *> *users;
```

Дженерики уточняют тип элементов — компилятор проверит и подскажет.

## Спецификаторы формата NSLog

```objc
NSLog(@"%@", obj);                  // любой объект (зовёт description)
NSLog(@"%d", 42);                   // int
NSLog(@"%ld", (long)bigInt);        // long / NSInteger — кастуй к long
NSLog(@"%lu", (unsigned long)u);    // NSUInteger — кастуй к unsigned long
NSLog(@"%f", 3.14);                 // double / float
NSLog(@"%zu", sizeof(int));         // size_t (sizeof, strlen)
NSLog(@"%p", obj);                  // адрес объекта
NSLog(@"%@ — %ld", name, (long)age);
```

`%@` — для объектов, остальное — как в `printf`. `NSInteger`/`NSUInteger`
кастуй к `long`/`unsigned long`. Объект в `%p` можно передать как есть:
с `-Wall -Wextra` clang молчит (ворчит только `-Wformat-pedantic`).
`(__bridge void *)obj` нужен лишь тогда, когда объект явно приводишь к
`void *` — без `__bridge` ARC такое приведение не пропустит.

## Частые грабли — одной строкой

- `==` сравнивает указатели, для содержимого строк — `isEqualToString:`.
- `NSString`-свойство объявляй `copy`, иначе словят мутацию через `NSMutableString`.
- KVO-наблюдателя снимай `removeObserver:` до того, как он умрёт (иначе крэш).
- `delegate` всегда `weak` — `strong` даёт retain cycle.
- Нельзя менять коллекцию внутри `for (x in collection)` — будет исключение.
- Блок, хранимый объектом и зовущий `self`, — retain cycle: бери `weakSelf`.
- `%d` для `NSInteger` ломается на 64 битах — кастуй к `(long)` и пиши `%ld`.
- Изменяемую копию делай `mutableCopy`, не `copy` (тот вернёт неизменяемую).
- Литерал `@[…]`/`@{…}` не принимает `nil` среди элементов — упадёт.

## Документация Apple

- Programming with Objective-C (язык целиком) —
  developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html
- Working with Blocks (раздел про блоки того же руководства) —
  developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html
- Objective-C Runtime — developer.apple.com/documentation/objectivec
- Foundation — developer.apple.com/documentation/foundation
