# Глава 14. Среда выполнения и иерархия классов

Эта глава — сердце книги. До сих пор мы пользовались объектами как
готовыми: создаём, шлём сообщения, наследуем. Но что такое объект на
самом деле? Что такое класс? Куда уходит сообщение `[obj foo]` в момент
выполнения и как оно находит нужный код?

Ответ даёт **среда выполнения** Objective-C (Objective-C runtime) —
небольшая библиотека `libobjc`, которая живёт рядом с каждой твоей
программой и всё время работает: хранит классы, ищет методы, пересылает
сообщения. В Си ничего подобного нет — там после компиляции от типов не
остаётся и следа. В Objective-C классы — это **живые объекты в памяти**,
у которых во время выполнения можно спросить имя, суперкласс, список
методов и даже дорастить им новый метод на лету.

Мы пойдём снизу вверх: от факта «объект знает свой класс» — к тому, что
класс это тоже объект, к метаклассам, к полной схеме указателей, к тому,
как `objc_msgSend` ищет метод, и закончим тремя механизмами, которые
делают язык по-настоящему динамическим: динамическим разрешением,
пересылкой сообщений и подменой методов (swizzling).

## Что мы сделаем

- Увидим через runtime, что объект — это структура, чьё первое поле
  `isa` указывает на класс.
- Поймём, что **класс — тоже объект**, и что его `isa` указывает на
  **метакласс**.
- Нарисуем и разберём классическую схему указателей `isa`/`superclass`.
- Разберём два корня иерархии: `NSObject` и `NSProxy`.
- Проследим, как `objc_msgSend` ищет реализацию по селектору.
- Напишем живой дамп иерархии и списка методов через функции runtime.
- Реализуем динамическое разрешение метода (`+resolveInstanceMethod:`).
- Сделаем рабочий объект-прокси через `-forwardingTargetForSelector:`.
- Подменим реализацию метода через `method_exchangeImplementations`.
- Увидим настоящее падение «unrecognized selector».

Весь runtime живёт в двух заголовках. Их мы и подключаем поверх
Foundation:

```objc
#import <Foundation/Foundation.h>
#import <objc/runtime.h>     /* object_getClass, class_getName, ... */
#import <objc/message.h>     /* objc_msgSend и компания */
```

`<objc/runtime.h>` — это набор Си-функций для работы с классами,
методами, селекторами и полями. `<objc/message.h>` — объявления самих
функций отправки сообщения. Дальше по тексту, когда функция нужна, я
буду указывать, из какого заголовка она пришла.

## Шаг 1. Объект знает свой класс

Вспомни из главы 3, что такое **структура** (`struct`): несколько полей,
лежащих в памяти подряд. Так вот, объект Objective-C — это обычная
си-структура, у которой **самое первое поле** называется `isa` и хранит
указатель на класс этого объекта. Само имя «isa» читается как «is a» —
«является»: `rex` *is a* `Dog`, rex является собакой.

Упрощённо объект в памяти выглядит так:

```text
объект rex в памяти:
+-----------------------------+   <- адрес объекта (то, что лежит в Dog *)
|  isa  -> указатель на Class |   первое поле, размер указателя (8 байт)
+-----------------------------+
|  ... поля экземпляра (ivar) |   дальше идут _name, _age и т.п.
+-----------------------------+
```

Раз `isa` — это просто поле, его можно прочитать. Высокоуровневое
сообщение `[rex class]` (см. главу 9) и низкоуровневая функция runtime
`object_getClass(rex)` обычно дают одно и то же: класс из поля `isa`.
Проверим, что это буквально один и тот же указатель.

Оговорка на будущее. «Первое поле — указатель на класс» — модель,
которой учит документация Apple, и думать о `isa` так удобно. В
современном 64-битном runtime в это слово памяти заодно упакованы
служебные биты (например, часть счётчика ссылок), поэтому читать его
руками бессмысленно: класс из него достаёт `object_getClass`. По нашему
эксперименту на Intel-маке сырое значение первого слова `rex` было
`0x11d800104d63261`, а адрес класса — `0x104d63260`: младшие разряды
совпадают, остальное — служебные биты.

```objc
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface Dog : NSObject
@end

@implementation Dog
@end

int main(void) {
    @autoreleasepool {
        Dog *rex = [[Dog alloc] init];

        Class c1 = [rex class];              /* через сообщение  */
        Class c2 = object_getClass(rex);     /* читаем isa напрямую */

        NSLog(@"[rex class]          = %s", class_getName(c1));
        NSLog(@"object_getClass(rex) = %s", class_getName(c2));
        NSLog(@"это один и тот же класс? %@",
              (c1 == c2) ? @"да" : @"нет");

        NSLog(@"адрес класса Dog     = %p", (__bridge void *)c1);

        Class super = class_getSuperclass(c1);
        NSLog(@"суперкласс Dog       = %s", class_getName(super));

        Dog *barsik = [[Dog alloc] init];
        NSLog(@"isa у rex и barsik совпадает? %@",
              (object_getClass(rex) == object_getClass(barsik))
              ? @"да" : @"нет");
    }
    return 0;
}
```

Разберём новые элементы.

- `Class` — это тип «класс». Под капотом это указатель на структуру
  класса (`struct objc_class *`). Переменная типа `Class` хранит адрес
  класса, ровно как `Dog *` хранит адрес объекта.
- `object_getClass(rex)` — функция из `<objc/runtime.h>`. Принимает
  любой объект, возвращает его `isa`, то есть класс. Это и есть «прочитать
  первое поле структуры» — с учётом упакованных битов из оговорки выше.
- `class_getName(c)` — принимает `Class`, возвращает **си-строку**
  (`const char *`) с именем класса. Поэтому печатаем через `%s`, а не
  `%@`: это обычный массив байтов, а не `NSString`.
- `(__bridge void *)c1` — приведение указателя-класса к «сырому»
  указателю, чтобы напечатать его адрес через `%p`. Слово `__bridge`
  нужно из-за ARC: оно говорит «просто перетолкуй указатель, владение не
  меняется». Без `__bridge` под ARC компилятор откажется приводить
  объектный указатель к `void *`.
- `class_getSuperclass(c)` — возвращает класс-родитель. Для `Dog` это
  `NSObject`.

Компилируем и запускаем:

```text
clang -fobjc-arc -framework Foundation -Wall -Wextra -O2 \
      code/14-isa.m -o t && ./t
```

Здесь и дальше в главе префикс `NSLog` (дата, время, имя программы)
в выводах опущен, а адреса у тебя будут свои:

```text
[rex class]          = Dog
object_getClass(rex) = Dog
это один и тот же класс? да
адрес класса Dog     = 0x10dbc80b8
суперкласс Dog       = NSObject
isa у rex и barsik совпадает? да
```

Два главных факта отсюда:

1. Класс `Dog` существует как **значение** — у него есть адрес в памяти
   (`0x10dbc80b8`). Это не абстракция компилятора, а реальный объект.
2. Все экземпляры одного класса делят **один** указатель `isa`. У `rex`
   и `barsik` он совпадает: класс на всех один, в каждый объект просто
   вложен адрес этого единственного класса.

> **Отличие от Си.** В Си у структуры нет никакого «знания о себе».
> Если ты объявил `struct Dog`, то после компиляции от имени `Dog` не
> останется ничего — в исполняемом файле это просто блок байтов нужного
> размера. Спросить у си-структуры «как тебя зовут?» невозможно: спрашивать
> некого. В Objective-C первое поле объекта — `isa` — постоянно держит
> связь с живым классом, и потому объект всегда знает, кто он.

## Шаг 2. Класс — это тоже объект

Раз у класса есть адрес и поля, логично спросить: а у класса самого есть
`isa`? Есть. **Класс — это объект**, и его первое поле тоже `isa`.

Зачем это нужно. Подумай про методы. Методы экземпляра (с минусом, `-`)
хранятся в классе: когда ты шлёшь сообщение объекту, runtime идёт в его
класс и ищет метод там. А где тогда хранятся методы класса (с плюсом,
`+`) — `alloc`, `new`, твои фабричные методы? Их нужно где-то держать по
той же схеме. Решение элегантное: у каждого класса есть свой невидимый
«класс класса» — **метакласс** (metaclass). Методы экземпляра лежат в
классе; методы класса лежат в метаклассе. Одна и та же машина поиска
работает на обоих уровнях.

```text
объект    ---isa--->   класс      ---isa--->   метакласс
(rex)                  (Dog)                   (Dog meta)
                       хранит -методы          хранит +методы
```

`isa` объекта — это его класс. `isa` класса — это его метакласс.
Прочитать метакласс можно той же функцией `object_getClass`, передав ей
не объект, а класс (ведь класс тоже объект):

```objc
Class dogClass = object_getClass(rex);        /* Dog        */
Class dogMeta  = object_getClass(dogClass);   /* Dog (meta) */
```

Метакласс невидим в коде — ты не пишешь его имя, не создаёшь его руками.
Компилятор и runtime заводят его автоматически для каждого класса.
Отличить класс от метакласса помогает `class_isMetaClass(c)` — вернёт
`YES`, если это метакласс. Вот программа, которая проходит по цепочке
`isa` и печатает её:

```objc
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface Animal : NSObject
@end
@implementation Animal
@end

@interface Dog : Animal
@end
@implementation Dog
@end

static void describe(Class c) {
    NSString *kind = class_isMetaClass(c) ? @"метакласс" : @"класс    ";
    Class super = class_getSuperclass(c);
    NSLog(@"%@ %-18s  isa=%p  super=%s",
          kind,
          class_getName(c),
          (__bridge void *)object_getClass(c),
          super ? class_getName(super) : "(none)");
}

int main(void) {
    @autoreleasepool {
        Dog *rex = [[Dog alloc] init];

        Class dogClass = object_getClass(rex);        /* Dog        */
        Class dogMeta  = object_getClass(dogClass);   /* Dog (meta) */

        NSLog(@"--- классы ---");
        describe(dogClass);
        describe([Animal class]);
        describe([NSObject class]);

        NSLog(@"--- метаклассы ---");
        describe(dogMeta);
        describe(object_getClass([Animal class]));
        describe(object_getClass([NSObject class]));

        Class rootMeta = object_getClass([NSObject class]);
        NSLog(@"--- замыкание ---");
        NSLog(@"isa корневого метакласса == он сам? %@",
              (object_getClass(rootMeta) == rootMeta) ? @"да" : @"нет");
        NSLog(@"superclass корневого метакласса = %s",
              class_getName(class_getSuperclass(rootMeta)));

        NSLog(@"Dog       — метакласс? %@",
              class_isMetaClass(dogClass) ? @"да" : @"нет");
        NSLog(@"Dog(meta) — метакласс? %@",
              class_isMetaClass(dogMeta)  ? @"да" : @"нет");
    }
    return 0;
}
```

Пара деталей синтаксиса печати:

- `%-18s` в строке формата — это «напечатай си-строку, выровняв по левому
  краю в поле шириной 18 символов». Минус означает выравнивание влево.
  Так колонки в выводе становятся ровными.
- `describe` берёт `Class` и печатает его вид, имя, `isa` (адрес его
  метакласса) и суперкласс. Заметь: для класса `isa` — это адрес
  метакласса, и мы это сейчас увидим в числах.

Запускаем:

```text
--- классы ---
класс     Dog                 isa=0x10e24a170  super=Animal
класс     Animal              isa=0x10e24a120  super=NSObject
класс     NSObject            isa=0x7ff84d568530  super=(none)
--- метаклассы ---
метакласс Dog                 isa=0x7ff84d568530  super=Animal
метакласс Animal              isa=0x7ff84d568530  super=NSObject
метакласс NSObject            isa=0x7ff84d568530  super=NSObject
--- замыкание ---
isa корневого метакласса == он сам? да
superclass корневого метакласса = NSObject
Dog       — метакласс? нет
Dog(meta) — метакласс? да
```

Вчитайся в адреса — в них вся картина:

- `isa` класса `Dog` = `...170`, а `isa` класса `Animal` = `...120`. Это
  адреса их метаклассов: у каждого класса свой метакласс.
- `isa` **всех** метаклассов одинаков: `0x7ff84d568530`. Это адрес
  **корневого метакласса** — метакласса `NSObject`. А сам метакласс
  `NSObject` своим `isa` указывает на себя же (`isa корневого метакласса
  == он сам? да`). Цепочка `isa` замкнулась.
- `superclass` метакласса `Dog` = `Animal`. Runtime тут
  печатает имя через `class_getSuperclass`, и для метакласса это
  метакласс родителя — но имя у метакласса то же, что у класса, поэтому в
  выводе видно `Animal`. Идея: иерархия метаклассов повторяет иерархию
  классов.
- `superclass` корневого метакласса (метакласса `NSObject`) — это сам
  **класс** `NSObject`. Так метаклассовая ветка «впадает» обратно в
  обычную, и поиск метода класса в самом конце доходит до методов
  экземпляра `NSObject`.

> **Отличие от Си.** В Си тип — это инструкция компилятору на этапе
> сборки, и только. У него нет ни адреса, ни «класса своего типа», ни
> возможности спросить о себе что-либо во время работы программы. Здесь
> же класс — полноценный объект, у которого есть свой класс (метакласс),
> а у того — свой (корневой метакласс). Целая живая структура там, где в
> Си пустота.

## Шаг 3. Полная схема указателей

Соберём всё в одну диаграмму — ту самую классическую картинку, которую
рисуют в документации Apple. Возьмём нашу тройку `Dog : Animal :
NSObject` и один объект `rex` класса `Dog`. Сплошные стрелки `isa`,
пунктирные `superclass`.

```text
  ЭКЗЕМПЛЯР        КЛАССЫ                  МЕТАКЛАССЫ

 +-------+  isa  +----------+   isa   +--------------------+
 |  rex  |------>|   Dog    |-------->|  Dog meta          |
 +-------+       +----------+         |  isa -> root meta  |
                      :               +--------------------+
                super :                     : super
                      v                     v
                 +----------+   isa   +--------------------+
                 |  Animal  |-------->|  Animal meta       |
                 +----------+         |  isa -> root meta  |
                      :               +--------------------+
                super :                     : super
                      v                     v
                 +----------+   isa   +--------------------+
                 | NSObject |-------->|  NSObject meta     |
                 +----------+         |  (root meta)       |
                   :    ^             |  isa -> сам себя   |
             super :    :             +--------------------+
                   v    :                   : super
                 (nil)  +...................+
```

Стрелки `isa` из метаклассов в корневой метакласс вписаны прямо в
прямоугольники, чтобы схема не превратилась в паутину. Нижняя пунктирная
линия — `superclass` корневого метакласса: он ведёт обратно в **класс**
`NSObject`.

Прочитаем по стрелкам, медленно — это карта всего runtime:

- `rex.isa -> Dog`. Объект знает свой класс.
- `Dog.isa -> Dog meta`. Класс знает свой метакласс.
- `Dog.superclass -> Animal`, `Animal.superclass -> NSObject`,
  `NSObject.superclass -> nil`. Это обычное дерево наследования; у корня
  родителя нет.
- `Dog meta.isa -> root metaclass`, `Animal meta.isa -> root metaclass`,
  `NSObject meta.isa -> сам NSObject meta`. Все метаклассы своим `isa`
  показывают на корневой метакласс, а тот — на себя. Цепочка `isa`
  конечна и замкнута.
- `Dog meta.superclass -> Animal meta`,
  `Animal meta.superclass -> NSObject meta`. Иерархия метаклассов
  параллельна иерархии классов.
- `NSObject meta.superclass -> NSObject (класс)`. Самый красивый узел:
  суперкласс корневого метакласса — это обычный класс `NSObject`.

Зачем последняя стрелка. Когда ты шлёшь сообщение **класса**
(`[Dog new]`), runtime ищет `+`-метод по метаклассовой ветке вверх:
`Dog meta -> Animal meta -> NSObject meta`. Если не нашёл и там — поиск
переходит в класс `NSObject` и продолжается по его `-`-методам.
Проверить мостик просто: добавь категорией (глава 11) метод экземпляра
`- (void)hi` в `NSObject` и пошли его **классу**: `[Dog hi]`. Метода
класса `+hi` нет нигде, но вызов сработает — поиск через мостик найдёт
`-hi` у класса `NSObject`, а `self` внутри будет классом `Dog`.

Запомни короткую формулу: **`isa` отвечает на вопрос «какого я вида»**
(объект -> класс -> метакласс), **`superclass` отвечает на вопрос «от
кого я унаследован»** (вверх по дереву до `nil`).

## Шаг 4. Два корня дерева: NSObject и NSProxy

Почти всё в Foundation и UIKit растёт из одного корня — класса
**`NSObject`**. Он даёт базовое поведение: `alloc`, `init`, подсчёт
ссылок, `isKindOfClass:`, `respondsToSelector:`, `description`, участие в
пересылке сообщений. Когда пишешь `@interface Dog : NSObject`, ты
встаёшь в это дерево.

Но корень не один. Есть второй, отдельный — **`NSProxy`**. Это тоже
абстрактный базовый класс, но «тонкий»: он создан специально для
объектов-заместителей, которые не делают работу сами, а пересылают почти
все сообщения куда-то ещё. `NSProxy` реализует совсем мало и заставляет
наследника определить пересылку. На нём строят, например, удалённые
прокси и ленивую загрузку.

```text
            корни иерархии классов Objective-C
            ----------------------------------

    NSObject  (основной корень — почти всё дерево)
    |
    +-- NSString --- NSMutableString
    +-- NSArray  --- NSMutableArray
    +-- NSNumber
    +-- NSDictionary
    +-- ... сотни классов Foundation/AppKit/UIKit ...
    +-- твои классы (Dog, Animal, ...)

    NSProxy   (отдельный корень — заместители/прокси)
    |
    +-- твои прокси-классы
```

Оба класса реализуют корневой протокол `NSObject` (одноимённый протокол,
не путать с классом) — поэтому у объектов обоих деревьев есть `class`,
`isKindOfClass:`, `respondsToSelector:` и так далее. Просто `NSObject`
тащит за собой ещё гору готового поведения, а `NSProxy` оставляет тебя
наедине с пересылкой. В быту ты почти всегда наследуешь `NSObject`; о
`NSProxy` достаточно знать, что второй корень существует.

## Шаг 5. Как сообщение находит метод: objc_msgSend

Теперь — главный механизм. Когда ты пишешь

```objc
[rex speak];
```

компилятор не вставляет прямой переход к коду метода. Он превращает эту
строку в **вызов функции отправки сообщения**:

```objc
objc_msgSend(rex, @selector(speak));
```

Разберём участников.

- **`objc_msgSend`** — функция из `<objc/message.h>`. Её первый аргумент —
  получатель (receiver), второй — селектор, дальше идут аргументы метода.
  Она находит реализацию и передаёт ей управление.
- **`SEL` (селектор)** — это **уникализированное имя сообщения**. Не
  строка, а её зарегистрированный в runtime «номерок»: для имени
  `"speak"` во всей программе существует ровно один `SEL`. Поэтому
  селекторы можно сравнивать через `==`, а не посимвольно. Получить
  селектор из имени: `@selector(speak)` на этапе компиляции или
  `sel_registerName("speak")` в рантайме. Обратно имя: `sel_getName(sel)`.
- **`IMP` (реализация, implementation)** — это **указатель на си-функцию**,
  которая и есть тело метода. У всякой `IMP` первые два скрытых аргумента —
  `self` (получатель) и `_cmd` (селектор), а дальше параметры метода.
- **Метод (`Method`)** — это **пара (`SEL`, `IMP`)**: имя сообщения и
  адрес кода, который на него отвечает (плюс строка с кодировкой типов,
  о ней в шаге 6). Класс хранит таблицу таких методов.

Алгоритм `objc_msgSend` по шагам:

```text
objc_msgSend(receiver, selector, аргументы...)

1. receiver == nil?  -> ничего не делаем, возвращаем 0/nil. (см. главу 5)
2. cls = класс из receiver->isa
3. смотрим в КЭШ cls: этот селектор уже вызывали?
      да  -> сразу прыгаем на запомненную IMP (самый частый случай)
4. ищем selector в таблице методов cls
      нашли  -> кладём (selector -> IMP) в кэш класса получателя
                и прыгаем на IMP, передав self, _cmd, аргументы
      не нашли -> cls = cls->superclass, повторяем шаг 4
5. дошли до конца (superclass == nil, выше NSObject)?
      -> динамическое разрешение и ПЕРЕСЫЛКА (шаги 7–9 ниже)
```

Картинка поиска для нашей тройки, если у `rex` зовём `speak`, а метод
определён только в `Animal`:

```text
[rex speak]
   |
   v  isa
 Dog ---- нет speak? --+
   |  superclass        \
   v                     (поиск идёт вверх)
 Animal -- ЕСТЬ speak! --> прыгаем на его IMP, выполняем
   |
   v (если бы не нашли — дальше)
 NSObject -- нет --> superclass == nil --> ПЕРЕСЫЛКА
```

> **Отличие от Си.** В Си `foo(rex, 5)` — это переход по **фиксированному
> адресу**: какой именно `foo` вызвать, решает компоновщик на этапе сборки,
> и в готовой программе там стоит конкретный адрес. В Objective-C
> `[rex foo:5]` — это `objc_msgSend(rex, @selector(foo:), 5)`: реальный
> адрес кода находится **во время выполнения**, проходом по дереву классов
> от `isa` получателя вверх по `superclass`. Один и тот же `[obj speak]`
> может выполнить разный код в зависимости от того, какой объект лежит в
> `obj` прямо сейчас. Этого Си не умеет в принципе.

Строка `objc_msgSend(rex, @selector(speak))` выше — это то, во что
компилятор превращает скобки; сама по себе в таком виде она не
соберётся. Можно ли вызвать `objc_msgSend` руками? Да, но осторожно: в
SDK она объявлена как `void objc_msgSend(void)`, и прямой вызов с
аргументами компилятор отвергает ошибкой `too many arguments to function
call, expected 0, have 2`. Звать её можно, только приведя к точной
сигнатуре метода.
Поэтому в обычном коде мы её **не** дёргаем напрямую — за нас это делают
квадратные скобки. А для интроспекции и динамики пользуемся
высокоуровневыми функциями runtime, к которым и переходим.

## Шаг 6. Живая интроспекция: дамп иерархии и методов

Раз класс — объект в памяти, спросим у него всё: имя, цепочку
суперклассов, список методов, список полей. Соберём маленький
«рентген» класса.

```objc
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface Vehicle : NSObject {
    int _wheels;            /* ivar базового класса */
}
- (void)move;
- (int)wheels;
@end

@implementation Vehicle
- (void)move  { NSLog(@"еду"); }
- (int)wheels { return _wheels; }
@end

@interface Car : Vehicle {
    NSString *_brand;       /* ivar потомка */
}
- (void)honk;
- (void)refuel:(int)liters;
@end

@implementation Car
- (void)honk          { NSLog(@"би-бип"); }
- (void)refuel:(int)l { NSLog(@"залил %d л", l); }
@end

static void dumpMethods(Class c) {
    unsigned int count = 0;
    Method *methods = class_copyMethodList(c, &count);
    NSLog(@"методы класса %s (%u шт.):", class_getName(c), count);
    for (unsigned int i = 0; i < count; i++) {
        SEL name = method_getName(methods[i]);
        NSLog(@"    - %s   (аргументов: %u)",
              sel_getName(name),
              method_getNumberOfArguments(methods[i]));
    }
    free(methods);          /* список выделен malloc — освобождаем сами */
}

static void dumpIvars(Class c) {
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList(c, &count);
    NSLog(@"поля класса %s (%u шт.):", class_getName(c), count);
    for (unsigned int i = 0; i < count; i++) {
        NSLog(@"    - %s : %s",
              ivar_getName(ivars[i]),
              ivar_getTypeEncoding(ivars[i]));
    }
    free(ivars);
}

static void dumpHierarchy(Class c) {
    NSLog(@"иерархия:");
    NSMutableString *line = [NSMutableString string];
    while (c) {
        [line appendString:[NSString stringWithUTF8String:class_getName(c)]];
        c = class_getSuperclass(c);
        if (c) [line appendString:@" -> "];
    }
    NSLog(@"    %@", line);
}

int main(void) {
    @autoreleasepool {
        Car *car = [[Car alloc] init];
        Class c = object_getClass(car);

        dumpHierarchy(c);
        dumpMethods(c);
        dumpIvars(c);
        dumpMethods([Vehicle class]);

        NSLog(@"Car отвечает на move (от родителя)? %@",
              class_respondsToSelector(c, @selector(move)) ? @"да" : @"нет");
        NSLog(@"Car отвечает на honk? %@",
              class_respondsToSelector(c, @selector(honk)) ? @"да" : @"нет");
        NSLog(@"Car отвечает на fly? %@",
              class_respondsToSelector(c, @selector(fly))  ? @"да" : @"нет");
    }
    return 0;
}
```

Новые функции runtime, по порядку:

- `class_copyMethodList(c, &count)` — возвращает **массив** методов,
  объявленных **именно в этом классе** (унаследованные не входят — они
  лежат в суперклассах). В `count` кладёт длину. Имя функции содержит
  `copy`: память под массив выделяется через `malloc`, и освободить её
  обязан ты сам через `free`. Это си-уровень, ARC сюда не дотягивается.
- `method_getName(m)` — селектор метода. `method_getNumberOfArguments(m)` —
  сколько у него аргументов, **считая** скрытые `self` и `_cmd`. Поэтому у
  метода без видимых параметров их два, а у `refuel:` — три.
- `class_copyIvarList(c, &count)` — массив полей (ivar) класса. Тоже
  требует `free`.
- `ivar_getName(iv)` — имя поля, `ivar_getTypeEncoding(iv)` — закодированный
  тип. Кодировка типов — это маленький «алфавит» runtime: `i` это `int`,
  `@` это объект, `@"NSString"` — объект конкретного класса. Тот же язык
  кодировки мы используем в `class_addMethod` (шаг 7).
- `class_respondsToSelector(c, sel)` — умеет ли **экземпляр** класса
  отвечать на сообщение, **с учётом наследования** (в отличие от
  `class_copyMethodList`, который смотрит только свой класс).
- `[NSString stringWithUTF8String:...]` — превращает си-строку
  (`const char *` от `class_getName`) в `NSString`, чтобы склеивать
  иерархию в одну читаемую строку.

Запускаем:

```text
иерархия:
    Car -> Vehicle -> NSObject
методы класса Car (3 шт.):
    - refuel:   (аргументов: 3)
    - honk   (аргументов: 2)
    - .cxx_destruct   (аргументов: 2)
поля класса Car (1 шт.):
    - _brand : @"NSString"
методы класса Vehicle (2 шт.):
    - wheels   (аргументов: 2)
    - move   (аргументов: 2)
Car отвечает на move (от родителя)? да
Car отвечает на honk? да
Car отвечает на fly? нет
```

Смотри, что мы вытащили из работающей программы:

- Полную цепочку наследования `Car -> Vehicle -> NSObject` — просто шагая
  по `superclass`.
- Список методов каждого класса по отдельности. Методы родителя `move` и
  `wheels` в списке `Car` не появились — они в `Vehicle`. Это прямое
  подтверждение того, что метод живёт ровно в том классе, где определён, а
  поиск при вызове идёт вверх.
- Загадочный `.cxx_destruct` в `Car`. Его добавил **ARC**: это
  автоматический «деструктор», который освобождает объектные поля (наш
  `_brand`) при уничтожении объекта. Ты его не писал — здесь это работа
  ARC, и runtime честно показывает его в списке. (Если у класса есть
  поля C++-типов, компилятор заводит этот метод и без ARC — чтобы вызвать
  их деструкторы; отсюда и `cxx` в имени.) Метка «по нашему эксперименту»:
  Apple не обещает имя `.cxx_destruct`, мы просто наблюдаем его в выводе.
- Поле `_brand` с кодировкой типа `@"NSString"`.
- `class_respondsToSelector` учёл наследование: `move` достался `Car` от
  `Vehicle` — «да»; `fly` не существует нигде — «нет».

> **Отличие от Си.** Это и есть та пропасть между языками. В Си нельзя во
> время выполнения спросить у типа список его функций или полей — типа в
> готовой программе уже нет, как нет и «списка функций структуры»: функции
> вообще не привязаны к структурам. В Objective-C класс — живой объект, и
> весь его «паспорт» — имя, родители, методы, поля — доступен прямо во
> время работы программы.

## Шаг 7. Динамическое разрешение метода

Пойдём ещё дальше. Метод можно не просто *прочитать*, но и *добавить*
классу прямо во время выполнения. Самый аккуратный момент для этого —
когда runtime ищет метод, не находит, и **спрашивает сам класс**: «может,
доопределишь?» Для методов экземпляра это вызов `+resolveInstanceMethod:`
(для методов класса есть парный `+resolveClassMethod:`).

Сделаем класс `Robot`, который не реализует метод `greet`, но в момент
первого обращения дорастит его себе через `class_addMethod`.

```objc
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* Обычная Си-функция. Её и подставим как реализацию метода.
   Первые два скрытых аргумента любой IMP — self и _cmd. */
static void dynamicGreet(id self, SEL _cmd) {
    NSLog(@"  привет от %@, селектор был :%s",
          [self class], sel_getName(_cmd));
}

@interface Robot : NSObject
@end

@implementation Robot

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    if (sel == @selector(greet)) {
        /* class_addMethod(класс, селектор, функция, кодировка-типов).
           "v@:" = void-результат(v), self(@), _cmd(:). */
        class_addMethod(self, sel, (IMP)dynamicGreet, "v@:");
        NSLog(@"  [resolve] добавили реализацию для %s", sel_getName(sel));
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

@end

int main(void) {
    @autoreleasepool {
        Robot *r = [[Robot alloc] init];

        NSLog(@"первый вызов greet:");
        [r performSelector:@selector(greet)];   /* запустит resolve */

        NSLog(@"второй вызов greet:");
        [r performSelector:@selector(greet)];   /* resolve уже НЕ нужен */
    }
    return 0;
}
```

Разбор по частям:

- `dynamicGreet` — обычная Си-функция, **не** метод. Но у неё та самая
  сигнатура `IMP`: первый параметр `id self`, второй `SEL _cmd`. Это и
  есть скрытые аргументы, которые каждому методу передаёт `objc_msgSend`.
  Внутри можно пользоваться `self`, как в обычном методе.
- `+resolveInstanceMethod:(SEL)sel` — метод **класса** из `NSObject`,
  который runtime зовёт, не найдя реализацию `sel` обычным поиском. Мы его
  переопределяем. Если узнаём селектор `greet`, добавляем реализацию и
  возвращаем `YES` — это сигнал runtime: «я доопределил, повтори поиск».
  Для всех остальных селекторов вызываем `super`, чтобы не сломать
  поведение по умолчанию.
- `class_addMethod(self, sel, (IMP)dynamicGreet, "v@:")` — главная
  функция. Внутри `+resolveInstanceMethod:` параметр `self` — это сам
  класс `Robot`. Мы добавляем ему метод: имя `sel`, код — наша функция,
  приведённая к `IMP`. Последний аргумент — **кодировка типов**: `"v@:"`
  читается как «возвращает `void` (`v`), принимает `self` — объект (`@`) и
  `_cmd` — селектор (`:`)». Та же кодировка, что мы видели в дампе полей.
- `[r performSelector:@selector(greet)]` — отправляем сообщение `greet`.
  Метода в классе нет, поэтому запустится `+resolveInstanceMethod:`. Мы
  пользуемся `performSelector:`, а не `[r greet]`, потому что метод `greet`
  нигде не объявлен — компилятор о нём не знает, а `performSelector:`
  отправляет сообщение по селектору без объявления.

Запускаем:

```text
первый вызов greet:
  [resolve] добавили реализацию для greet
  привет от Robot, селектор был :greet
второй вызов greet:
  привет от Robot, селектор был :greet
```

`[resolve]` напечаталось **ровно один раз** — при первом вызове. Дальше
метод уже встроен в класс, и второй вызов идёт напрямую, минуя
разрешение. Класс буквально вырос на один метод во время работы
программы.

> **Отличие от Си.** В Си набор функций фиксируется при компоновке: какие
> функции есть в программе, то и есть, новую во время выполнения «дорастить»
> структуре нельзя. Здесь же `class_addMethod` добавляет классу метод на
> ходу, и со следующего сообщения объекты уже умеют то, чего минуту назад
> не умели.

## Шаг 8. Пересылка сообщения: три шанса

Что, если объект так и не нашёл метод и не доопределил его в
`resolveInstanceMethod:`? Сообщение не пропадает сразу. У runtime есть
**три последовательных шанса** обработать «непонятное» сообщение, прежде
чем сдаться и уронить программу:

```text
[obj foo]  ->  поиск в классе и вверх по superclass  ->  НЕ НАЙДЕНО
                                |
       ШАНС 1: +resolveInstanceMethod:(foo)
               можно добавить метод на лету (class_addMethod)
                                | не разрешили
       ШАНС 2: -forwardingTargetForSelector:(foo)
               вернуть ДРУГОЙ объект, который умеет foo
               -> runtime повторяет отправку ему (быстро)
                                | вернули nil/self
       ШАНС 3: -methodSignatureForSelector:(foo)  +  -forwardInvocation:
               полный объект NSInvocation: можно изменить, залогировать,
               переслать нескольким адресатам, вернуть значение
                                | не обработали
       -> -doesNotRecognizeSelector:  ->  ИСКЛЮЧЕНИЕ, падение
```

Первый шанс мы уже разобрали. Самый практичный — **второй**:
`-forwardingTargetForSelector:`. Ты возвращаешь другой объект, и runtime
просто повторяет отправку уже ему — без копирования аргументов, дёшево.
На этом строят **прокси**: объект, который сам почти ничего не умеет, а
все сообщения переадресует «настоящему» работнику.

```objc
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface Worker : NSObject
- (NSString *)greet:(NSString *)name;
- (int)square:(int)x;
@end

@implementation Worker
- (NSString *)greet:(NSString *)name {
    return [NSString stringWithFormat:@"Worker приветствует %@", name];
}
- (int)square:(int)x { return x * x; }
@end

@interface Proxy : NSObject
- (instancetype)initWithTarget:(id)target;
@end

@implementation Proxy {
    id _target;     /* кому пересылаем */
}

- (instancetype)initWithTarget:(id)target {
    self = [super init];
    if (self) { _target = target; }
    return self;
}

- (id)forwardingTargetForSelector:(SEL)sel {
    NSLog(@"  [forward] %s -> %@", sel_getName(sel), [_target class]);
    if ([_target respondsToSelector:sel]) {
        return _target;
    }
    return [super forwardingTargetForSelector:sel];
}

@end

int main(void) {
    @autoreleasepool {
        Worker *worker = [[Worker alloc] init];

        /* Тип переменной — id, поэтому компилятор разрешает слать
           proxy любые объявленные селекторы. */
        id proxy = [[Proxy alloc] initWithTarget:worker];

        NSString *hi = [proxy greet:@"Серик"];
        NSLog(@"ответ: %@", hi);

        int sq = [proxy square:9];
        NSLog(@"9 в квадрате = %d", sq);

        NSLog(@"proxy сам умеет greet:? %@",
              [proxy respondsToSelector:@selector(greet:)] ? @"да" : @"нет");
    }
    return 0;
}
```

Ключевые места:

- `Proxy` наследует `NSObject` и **не реализует** ни `greet:`, ни
  `square:`. Внутри хранит `_target` — настоящего работника.
- `-forwardingTargetForSelector:(SEL)sel` — метод из `NSObject`. runtime
  зовёт его для каждого нераспознанного сообщения. Возвращаем `_target`,
  если тот умеет `sel`; иначе передаём дальше в `super` (там сообщение
  пойдёт на третий шанс и, скорее всего, упадёт).
- `id proxy = ...` — мы намеренно объявили переменную как `id`, а не
  `Proxy *`. Под `id` компилятор разрешает слать любые **объявленные где
  угодно** селекторы (`greet:`, `square:` объявлены в `Worker`) и не
  ругается, что `Proxy` их не знает. Это та самая динамика главы 5.
- `[proxy greet:@"Серик"]` возвращает `NSString`, `[proxy square:9]` —
  `int`. Пересылка сохраняет и аргументы, и тип возврата: для
  `forwardingTargetForSelector:` это бесплатно, ведь сообщение буквально
  повторяется другому получателю.

Запускаем:

```text
  [forward] greet: -> Worker
ответ: Worker приветствует Серик
  [forward] square: -> Worker
9 в квадрате = 81
proxy сам умеет greet:? нет
```

Снаружи `proxy` ведёт себя как `Worker`: ответил на `greet:` и `square:`.
А последняя строка честно говорит «`proxy` сам не умеет `greet:`» —
`respondsToSelector:` смотрит на реальные методы класса `Proxy`, а
пересылка работает уровнем ниже, уже после того, как обычный поиск
провалился.

Про **третий шанс** — `-forwardInvocation:` — достаточно знать идею. Если
переопределить пару `-methodSignatureForSelector:` (вернуть описание
сигнатуры метода) и `-forwardInvocation:(NSInvocation *)inv`, то runtime
упакует всё сообщение целиком в объект `NSInvocation`: получатель,
селектор, все аргументы. С ним можно делать что угодно — изменить
аргументы, переслать **нескольким** адресатам, записать в лог, отложить.
Это мощнее `forwardingTargetForSelector:`, но и дороже: построение
`NSInvocation` не бесплатно. Эскиз метода (фрагмент, не целая программа):

```objc
- (void)forwardInvocation:(NSInvocation *)inv {
    if ([_target respondsToSelector:[inv selector]]) {
        [inv invokeWithTarget:_target];   /* выполнить на другом объекте */
    } else {
        [super forwardInvocation:inv];
    }
}
```

## Шаг 9. doesNotRecognizeSelector: и падение

Если ни один из трёх шансов не сработал, runtime зовёт у объекта
`-doesNotRecognizeSelector:`, а тот бросает исключение
`NSInvalidArgumentException`. Это и есть знаменитое падение, которое рано
или поздно видит каждый. Спровоцируем его намеренно:

```objc
#import <Foundation/Foundation.h>

@interface Cat : NSObject
@end
@implementation Cat
@end

int main(void) {
    @autoreleasepool {
        Cat *c = [[Cat alloc] init];
        [c performSelector:@selector(fly)];   /* Cat не умеет fly */
    }
    return 0;
}
```

Запускаем и видим аварийное завершение:

```text
*** Terminating app due to uncaught exception 'NSInvalidArgumentException',
reason: '-[Cat fly]: unrecognized selector sent to instance 0x600003ad8070'
*** First throw call stack:
(
    0   CoreFoundation       __exceptionPreprocess + 241
    1   libobjc.A.dylib      objc_exception_throw + 62
    ...
)
libc++abi: terminating due to uncaught exception of type NSException
```

(Первые две строки в терминале — одна длинная строка; колонку адресов
в стеке мы убрали.)

Расшифруй сообщение — оно очень информативно:

- `-[Cat fly]` — минус говорит, что искали **метод экземпляра** `fly` у
  класса `Cat` (для метода класса был бы плюс: `+[Cat fly]`).
- `unrecognized selector sent to instance 0x...` — селектор не нашёлся и
  ни один шанс пересылки его не подобрал; в конце адрес самого объекта.
- `objc_exception_throw` в стеке — это runtime бросил исключение.

Встречая такое падение, читай первую строку: класс и селектор почти
всегда сразу показывают, кто кому послал что-то, чего тот не умеет.
Частая причина — опечатка в имени метода или вызов метода объекта не того
класса (например, послал `addObject:` строке).

## Шаг 10. Method swizzling: подмена реализации

Последний приём — самый острый инструмент. Мы умеем читать пары
(`SEL`, `IMP`) и добавлять новые. А ещё их можно **менять местами**:
`method_exchangeImplementations` обменивает реализации двух методов.
После обмена старое имя ведёт на чужой код, и наоборот. Это называют
**method swizzling**.

```objc
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface Greeter : NSObject
- (NSString *)hello;
@end

@implementation Greeter
- (NSString *)hello { return @"привет"; }
@end

@interface Greeter (Swizzle)
@end

@implementation Greeter (Swizzle)
- (NSString *)my_hello {
    NSString *original = [self my_hello];   /* после обмена: старый hello */
    return [NSString stringWithFormat:@"[лог] %@!", original];
}
@end

int main(void) {
    @autoreleasepool {
        Greeter *g = [[Greeter alloc] init];
        NSLog(@"до обмена:  %@", [g hello]);

        Method orig = class_getInstanceMethod([Greeter class],
                                              @selector(hello));
        Method swiz = class_getInstanceMethod([Greeter class],
                                              @selector(my_hello));
        method_exchangeImplementations(orig, swiz);

        NSLog(@"после обмена: %@", [g hello]);

        Greeter *other = [[Greeter alloc] init];
        NSLog(@"и для нового объекта: %@", [other hello]);
    }
    return 0;
}
```

Что здесь происходит:

- В категории `Greeter (Swizzle)` (категории — глава 11) мы добавляем
  метод `my_hello`. Внутри он зовёт... `[self my_hello]`. На вид это
  бесконечная рекурсия, но это не она: мы пишем код **до** обмена, а
  выполнится он **после**, когда имя `my_hello` уже будет указывать на
  исходный `hello`. То есть `[self my_hello]` в теле вызовет старый
  `hello`. Хитрый, но классический приём.
- `class_getInstanceMethod(cls, sel)` — возвращает `Method` (пару
  `SEL`+`IMP`) для селектора, **с учётом наследования**.
- `method_exchangeImplementations(orig, swiz)` — меняет `IMP` у двух
  методов местами. Теперь сообщение `hello` выполняет код, который мы
  написали как `my_hello`, а тот внутри зовёт настоящий старый `hello`.

Запускаем:

```text
до обмена:  привет
после обмена: [лог] привет!
и для нового объекта: [лог] привет!
```

Метод `hello` после обмена возвращает `[лог] привет!` — мы «обернули»
чужой метод, не трогая его исходник. И главное — изменение коснулось
**всех** экземпляров `Greeter`, включая созданный позже `other`. В этом и
сила, и опасность.

Чем swizzling опасен:

- Подмена глобальна: ты меняешь поведение класса для **всей** программы,
  включая код, который об этом не знает (в том числе системный).
- Порядок и момент подмены важны. Если два места засвиззлят один метод,
  результат зависит от того, кто успел первым, — ловить такие баги тяжело.
- Имя `my_hello` не должно случайно совпасть с чужим методом — иначе
  сломаешь и его. Поэтому swizzling-методам дают редкие префиксы.

Правило простое: swizzling — это инструмент для отладки, аналитики и
обхода чужих багов, а не для повседневной логики. В обычном коде ему не
место.

### Связь с KVO и тизер главы 20

Подменять можно не только реализации методов, но и сам `isa` объекта:
функция runtime `object_setClass(obj, cls)` переселяет объект в другой
класс. На этом Apple строит **KVO**
(Key-Value Observing, наблюдение за значением по ключу). Когда ты
начинаешь наблюдать за свойством объекта, Foundation на лету создаёт
**динамический подкласс** этого объекта, переопределяет в нём сеттеры (а
они шлют уведомления наблюдателям) и **подменяет `isa`** объекта на этот
новый подкласс. Объект продолжает выглядеть как прежний класс (`-class`
специально это маскирует), но его реальный `isa` теперь указывает на
сгенерированный подкласс (по нашему эксперименту для класса `Dog` он
называется `NSKVONotifying_Dog`). Это и есть «isa-swizzling».

Теперь, зная, что объект — это структура с полем `isa`, ты понимаешь, как
такое вообще возможно: достаточно переписать класс в первом поле объекта
(через `object_setClass`, а не руками — вспомни про упакованные биты), и
он начинает вести себя как другой класс. Подробно KVO разберём в главе 20 —
там этот фокус заиграет красками.

## Проверяем

Готовые файлы главы лежат в `code/`. Собираются и запускаются одинаково:

```text
clang -fobjc-arc -framework Foundation -Wall -Wextra -O2 \
      code/14-isa.m -o t && ./t
```

Список файлов и что они показывают:

- `code/14-isa.m` — объект знает свой класс (`object_getClass` vs
  `[obj class]`), общий `isa` у экземпляров.
- `code/14-metaclass.m` — класс это объект, цепочка `isa` до корневого
  метакласса, замыкание `isa` на себя.
- `code/14-introspect.m` — дамп иерархии, методов и полей через runtime.
- `code/14-resolve.m` — динамическое добавление метода в
  `+resolveInstanceMethod:`.
- `code/14-forwarding.m` — рабочий прокси на
  `-forwardingTargetForSelector:`.
- `code/14-swizzle.m` — обмен реализациями через
  `method_exchangeImplementations`.

Все шесть собираются **без предупреждений** под `-Wall -Wextra`. В
выводах главы префикс `NSLog` опущен: у тебя перед каждой строкой будут
дата, время, имя программы и числа в квадратных скобках, а адреса — свои.
Важна содержательная часть строк.

## Частые ошибки

- **Прямой вызов `objc_msgSend` без приведения типа.** Компилятор
  отвергает его ошибкой: в SDK `objc_msgSend` объявлена без параметров, и
  звать её надо, приведя к точному типу метода. В обычном коде её не
  трогают вовсе — пользуйся квадратными скобками или функциями runtime.
- **Забыл `free` после `class_copy...`.** Функции с `copy` в имени
  (`class_copyMethodList`, `class_copyIvarList`) выделяют память через
  `malloc`. ARC до неё не дотягивается — освобождай руками, иначе утечка.
- **Перепутал `isa` и `superclass`.** `isa` — «какого я вида» (объект ->
  класс -> метакласс). `superclass` — «от кого унаследован» (вверх по
  дереву). Разные оси, не смешивай.
- **Неверная кодировка типов в `class_addMethod`.** Если метод возвращает
  не `void` или принимает другие аргументы, строка кодировки должна это
  отражать (`"i@:"` — вернёт `int`; `"v@:i"` — примет ещё `int`). Ошибка
  тут даёт порчу памяти, а не понятную диагностику.
- **`respondsToSelector:` на прокси возвращает «нет».** Это нормально:
  прокси и правда не реализует метод, он его *пересылает*. Если нужно,
  чтобы прокси честно отвечал «да», переопредели и `respondsToSelector:`.
- **Swizzling в повседневной логике.** Глобальная подмена ради обычной
  фичи — источник трудноуловимых багов. Оставь её для отладки и обходных
  путей.
- **`[obj fly]` к объекту, который не умеет `fly`.** Получишь
  `unrecognized selector` и падение. Перед динамическим вызовом проверяй
  `respondsToSelector:` (глава 5).

## Упражнения

1. Добавь в `14-metaclass.m` класс `Puppy : Dog` и распечатай для него и
   класс, и метакласс. Убедись, что `isa` его метакласса по-прежнему ведёт
   к тому же корневому метаклассу.
2. Расширь дамп из `14-introspect.m`: для каждого метода печатай ещё и его
   закодированный тип возврата через `method_copyReturnType` (не забудь
   `free`).
3. В `14-resolve.m` добавь обработку второго селектора `bye` с собственной
   функцией-реализацией. Проверь, что `resolve` срабатывает по разу на
   каждый.
4. Преврати `Proxy` из `14-forwarding.m` в «логирующий прокси»: пусть он
   ещё и считает, сколько сообщений переслал, и печатает счётчик.
5. В `14-swizzle.m` сначала напиши классу `Greeter` собственный
   `-description`, а потом засвиззли его так, чтобы он возвращал текст в
   верхнем регистре. Проследи, что `NSLog(@"%@", obj)` печатает новый
   текст. Подумай, почему без своего `-description` обмен задел бы
   `description` самого `NSObject` — то есть всех объектов программы.
6. Поймай `unrecognized selector` в свой код: оберни рискованный вызов в
   `@try { ... } @catch (NSException *e) { ... }` и напечатай `e.reason`
   вместо падения. (Исключения — обзорно; в проде так не «лечат» баги.)

## Что мы получили

Мы добрались до самого низа объектной модели и увидели, что магии нет —
есть стройная механика. Объект — это структура, чьё первое поле `isa`
ведёт к классу. Класс — тоже объект, его `isa` ведёт к метаклассу, и вся
конструкция замыкается на корневом метаклассе `NSObject`. Сообщение
`[obj foo]` — это `objc_msgSend`, который ищет метод от `isa` получателя
вверх по `superclass`; не найдя — даёт три шанса пересылки и лишь потом
падает с «unrecognized selector». А поскольку классы живые, их можно
читать (интроспекция), дополнять (`class_addMethod`,
`resolveInstanceMethod:`), переадресовывать (`forwardingTargetForSelector:`)
и переписывать (swizzling) прямо во время выполнения.

Это и есть та динамика, которой Си лишён в принципе: там после компиляции
от типов не остаётся ничего, а вызовы прибиты к фиксированным адресам.
Понимание runtime — ключ ко всему, что дальше: к KVC/KVO (глава 20), к
тому, как Foundation устроен изнутри, и к отладке самых загадочных
падений.

Со следующей главы мы поднимаемся обратно на прикладной уровень и
осваиваем Foundation — строки, числа, коллекции, — но уже зная, что
именно крутится под капотом у каждого `[ ]`.

## Документация Apple

- Objective-C Runtime Programming Guide (Messaging, Dynamic Method
  Resolution, Message Forwarding, Type Encodings) —
  <https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Introduction/Introduction.html>
- Objective-C Runtime (справочник функций `object_getClass`,
  `class_getName`, `class_copyMethodList`, `class_addMethod`,
  `method_exchangeImplementations`, `sel_getName`) —
  <https://developer.apple.com/documentation/objectivec/objective-c-runtime>
- `NSObject` (`class`, `superclass`, `isKindOfClass:`,
  `respondsToSelector:`, `+resolveInstanceMethod:`,
  `-forwardingTargetForSelector:`, `-forwardInvocation:`,
  `-doesNotRecognizeSelector:`) —
  <https://developer.apple.com/documentation/objectivec/nsobject-swift.class>
- `NSProxy` (второй корневой класс, абстрактный суперкласс для прокси) —
  <https://developer.apple.com/documentation/foundation/nsproxy>
- `NSInvocation` (упакованное сообщение для `-forwardInvocation:`) —
  <https://developer.apple.com/documentation/foundation/nsinvocation>
