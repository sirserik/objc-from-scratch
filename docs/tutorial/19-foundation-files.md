# Глава 19. Foundation: файлы и сериализация

В главе 18 ты держал данные в `NSData` — сыром мешке байтов — и в
коллекциях. Но как только программа закрылась, всё это исчезло: жило
только в памяти. Чтобы данные пережили запуск, их надо положить **на
диск**, в файл, а потом прочитать обратно.

В чистом Си файл — это поток байтов: открыл `fopen`, накидал байтов
`fwrite`, закрыл `fclose`, а формат придумай и разбери сам. Foundation
поднимает планку: он умеет сохранять **целые объекты и коллекции** одним
вызовом — в plist, в JSON, в архив. Ты говоришь «запиши этот массив
словарей в файл» — и он сам решает, как разложить его по байтам, и сам
соберёт обратно.

Разберём четыре слоя работы с диском: управление файлами
(`NSFileManager`), чтение/запись строк и данных, сериализацию коллекций
(plist и JSON) и архивацию своих объектов (`NSSecureCoding`). В конце
построим список задач, сохраним его в JSON-файл и поднимем назад, а потом
научим свой класс `Task` сохранять самого себя.

## Что мы сделаем

- Найдём временную папку и поработаем в ней через `NSFileManager`:
  создадим папку, файлы, спросим существование и атрибуты, уберём за
  собой.
- Запишем строку в файл и прочитаем обратно; то же самое с сырыми
  байтами `NSData`. Разберёмся, зачем `atomically:`.
- Сохраним массив словарей в **property list** и в **JSON**, прочитаем
  назад, поймаем битый JSON ошибкой, а не крахом.
- Сделаем класс `Task`, поддерживающий `NSSecureCoding`, заархивируем
  его в `NSData` и в файл и распакуем обратно.

Все примеры пишут только во временную директорию и сами удаляют за собой
файлы — после них на диске ничего не остаётся.

> **Отличие от Си.** В Си работа с файлом — это `FILE *f = fopen(...)`,
> затем `fread`/`fwrite` байтами и `fclose`. Ты сам придумываешь формат:
> где число, где строка, где конец записи. Foundation идёт выше: один
> вызов `writeToFile:` или `dataWithJSONObject:` — и целая коллекция
> объектов ложится на диск в готовом формате, а обратный вызов поднимает
> её как живые объекты. Байтами вручную ворочать почти не приходится.

## NSFileManager: работа с файлами и папками

`NSFileManager` — класс, через который мы спрашиваем файловую систему:
существует ли файл, создай папку, удали, перечисли содержимое, дай
атрибуты. Сам по себе он не хранит файлы — это посредник между твоим
кодом и диском.

Берут его почти всегда так:

```objc
NSFileManager *fm = [NSFileManager defaultManager];
```

`defaultManager` — **общий экземпляр** (shared instance): один на всю
программу, создавать свой обычно незачем. Это знакомый по Foundation
приём — как `[NSNotificationCenter defaultCenter]`.

### Куда вообще можно писать

Приложению для iPhone или из Mac App Store нельзя писать куда попало:
оно живёт в песочнице, и система разрешает только определённые папки.
Наша консольная программа песочницы не имеет, но хорошая привычка одна
на всех — спрашивать нужную папку у системы. Две, которые нужны чаще
всего:

```objc
NSString *tmp = NSTemporaryDirectory();
```

`NSTemporaryDirectory()` — это **функция** (не метод!), возвращает путь к
временной папке текущего пользователя (у приложения в песочнице — своей
для этого приложения). Туда можно свободно писать черновики; система
вправе их подчистить, когда захочет, поэтому ничего ценного там не храни. Для учебных
примеров это идеальное место: намусорил — не страшно.

Для данных, которые должны жить долго, есть папка **Documents**:

```objc
NSArray<NSString *> *dirs = NSSearchPathForDirectoriesInDomains(
    NSDocumentDirectory, NSUserDomainMask, YES);
NSString *docs = dirs.firstObject;
```

`NSSearchPathForDirectoriesInDomains` — функция, которая ищет системные
папки. Первый аргумент — *какую* (`NSDocumentDirectory` — Documents),
второй — *где* (`NSUserDomainMask` — в домашней папке пользователя),
третий — раскрывать ли `~` в полный путь (`YES`). Возвращает массив
путей; берём первый.

Современный способ — через URL и сам `NSFileManager`:

```objc
NSURL *docsURL = [fm URLForDirectory:NSDocumentDirectory
                           inDomain:NSUserDomainMask
                  appropriateForURL:nil
                             create:YES
                              error:NULL];
```

`URLForDirectory:...` возвращает `NSURL` вместо строки-пути и при
`create:YES` создаёт папку, если её нет. В реальных приложениях
предпочитают именно URL-вариант, но для примеров нам хватит временной
папки и строк-путей.

> **Отличие от Си.** В Си ты просто пишешь `fopen("/tmp/file.txt", "w")`
> — любой путь, какой указал, и за права отвечаешь ты сам. На iOS и в
> Mac App Store приложение живёт в **песочнице** (sandbox): чужие папки
> для него закрыты, а «правильные» (`Documents`, `tmp`) надо
> спросить у системы этими функциями, а не хардкодить путь.

### Собираем путь из кусочков

Склеивать пути вручную через `/` — плохая привычка: легко получить
двойной слэш или потерять разделитель. У `NSString` для этого есть
методы работы с путями:

```objc
NSString *dir  = [tmp stringByAppendingPathComponent:@"objc-fm-demo"];
NSString *file = [dir stringByAppendingPathComponent:@"a.txt"];
```

`stringByAppendingPathComponent:` приклеивает компонент пути, сам ставя
ровно один разделитель. Обратные методы: `lastPathComponent` (имя файла
из пути), `pathExtension` (расширение), `stringByDeletingLastPathComponent`
(папка-родитель).

### Создаём папку

```objc
NSError *err = nil;
BOOL ok = [fm createDirectoryAtPath:dir
        withIntermediateDirectories:YES
                         attributes:nil
                              error:&err];
```

- `createDirectoryAtPath:` — путь создаваемой папки.
- `withIntermediateDirectories:YES` — создать заодно все недостающие
  промежуточные папки. С `NO` метод упадёт, если родителя нет.
- `attributes:nil` — права/атрибуты по умолчанию.
- `error:&err` — знакомый по главе 18 приём: метод вернёт
  `BOOL`, а при `NO` положит причину в `err`. Проверяем именно
  возвращённый `BOOL`, а на `err` смотрим только когда он `NO`.

### Существование, файл или папка

```objc
BOOL there = [fm fileExistsAtPath:file];

BOOL isDir = NO;
[fm fileExistsAtPath:dir isDirectory:&isDir];
```

`fileExistsAtPath:` отвечает `YES`/`NO` — есть ли что-то по пути. Версия
`fileExistsAtPath:isDirectory:` заодно через указатель `&isDir` скажет,
папка это (`YES`) или обычный файл (`NO`).

### Список содержимого папки

```objc
NSArray<NSString *> *items =
    [fm contentsOfDirectoryAtPath:dir error:NULL];
```

Возвращает массив **имён** (не полных путей!) внутри папки, без `.` и
`..`. Порядок не гарантирован — если нужен предсказуемый, сортируй сам
(`sortedArrayUsingSelector:@selector(compare:)`).

### Атрибуты файла

```objc
NSDictionary<NSFileAttributeKey, id> *attrs =
    [fm attributesOfItemAtPath:file error:NULL];
unsigned long long size = [attrs[NSFileSize] unsignedLongLongValue];
NSDate *mtime = attrs[NSFileModificationDate];
```

`attributesOfItemAtPath:error:` возвращает словарь, где по ключам-
константам лежат сведения о файле: `NSFileSize` (размер в байтах,
завёрнут в `NSNumber`), `NSFileModificationDate` (дата изменения,
`NSDate`), `NSFileType`, `NSFilePosixPermissions` и другие.

### Удаление

```objc
[fm removeItemAtPath:dir error:&err];
```

Удаляет файл или **папку целиком вместе с содержимым**. Возвращает
`BOOL`. После него можно проверить `fileExistsAtPath:` — вернёт `NO`.

Соберём всё это в один пример. Он создаёт во временной папке свою
подпапку, кладёт три файла, перечисляет их, смотрит атрибуты и убирает за
собой.

Полный файл — `code/19-filemanager.m`. Реальный вывод (пути и время —
свои):

```text
временная папка: /var/folders/km/.../T/
наша папка:     /var/folders/km/.../T/objc-fm-demo
a.txt на месте? 1
z.txt на месте? 0
наш путь — папка? 1
в папке: a.txt, b.txt, note.md
a.txt: размер=15 байт, изменён=2026-06-28 07:40:12 +0000
папку удалили
папка ещё есть? 0
```

`1` и `0` — это `BOOL` в формате `%d` (`YES`=1, `NO`=0). Видно, что после
`removeItemAtPath:` папки больше нет.

## Чтение и запись строк и данных

Самый частый случай — сохранить строку текста и прочитать её обратно. У
`NSString` это один метод в каждую сторону.

### Записать строку

```objc
NSString *text = @"Первая строка\nВторая строка\n";
NSError *err = nil;
BOOL ok = [text writeToFile:path
                 atomically:YES
                   encoding:NSUTF8StringEncoding
                      error:&err];
```

- `writeToFile:` — путь файла.
- `atomically:YES` — **писать атомарно**. Метод сначала пишет во
  временный файл рядом, и только когда всё легло — одним движением
  переименовывает его поверх целевого. Если на середине записи программу
  убьют или сядет батарея, старый файл останется целым, а не превратится
  в полузаписанный огрызок. Цена — нужно временно вдвое больше места.
  Для важных данных всегда `YES`.
- `encoding:NSUTF8StringEncoding` — **как переводить символы в байты**.
  UTF-8 — стандарт, бери его по умолчанию. Кодировка при чтении должна
  совпасть, иначе кириллица превратится в кашу.
- `error:&err` — причина, если вернулся `NO`.

> **Отличие от Си.** В Си запись строки — это `fputs(text, f)` или
> `fwrite`, и понятия «кодировка» у тебя нет: пишутся ровно те байты, что
> лежат в `char *`. Что это было — UTF-8, latin-1 или мусор — Си не
> знает и не проверит. `NSString` всегда хранит *символы*, а при записи
> ты явно говоришь, в какие байты их перевести. Поэтому кириллица,
> эмодзи и иероглифы сохраняются корректно и предсказуемо.

### Прочитать строку

```objc
NSString *back = [NSString stringWithContentsOfFile:path
                                           encoding:NSUTF8StringEncoding
                                              error:&err];
```

Читает весь файл и собирает из байтов `NSString`. При сбое (нет файла,
не та кодировка) вернёт `nil` и заполнит `err`. Проверяй именно на
`nil`, а не на `err`.

### Сырые байты: NSData

Когда содержимое не текст (картинка, архив, что угодно), работаем с
`NSData` — мешком байтов из главы 18:

```objc
NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
[data writeToFile:binPath atomically:YES];

NSData *raw = [NSData dataWithContentsOfFile:binPath];
NSString *fromData = [[NSString alloc] initWithData:raw
                                           encoding:NSUTF8StringEncoding];
```

- `dataUsingEncoding:` — строка → байты.
- `writeToFile:atomically:` у `NSData` — то же атомарное сохранение, но
  кодировка не нужна (байты и так байты).
- `dataWithContentsOfFile:` — прочитать файл в `NSData`.
- `initWithData:encoding:` — собрать строку из байтов обратно.

Пример `code/19-readwrite.m` пишет строку и в текстовый файл, и в
бинарный, читает обоими способами и сверяет. Вывод:

```text
строку записали в objc-rw.txt
прочитали символов: 43
совпало с исходным? 1
первая строка файла: Первая строка
в строке 78 байт (длиннее символов из-за кириллицы)
прочитали 78 байт, байты совпали? 1
из байтов восстановили первую строку: Первая строка
временные файлы удалены
```

Обрати внимание: **43 символа, но 78 байт**. Кириллическая буква в UTF-8
занимает два байта, а перевод строки и латиница — по одному. Вот почему
`length` строки и `length` её `NSData` — разные числа (об этом была речь
в главе 15).

## Property list: сохраняем коллекции

Часто на диск нужно положить не одну строку, а целую структуру: массив,
словарь, вложенные коллекции. Для этого у Apple есть формат **property
list** (сокращённо **plist**) — текстовый (XML) или бинарный файл, в
котором живут именно коллекции и простые значения.

Самое удобное: `NSArray` и `NSDictionary` умеют писать себя в plist
**одним вызовом**.

```objc
NSArray<NSDictionary *> *tasks = @[
    @{ @"title": @"Купить кофе", @"done": @YES, @"priority": @1 },
    @{ @"title": @"Написать главу", @"done": @NO, @"priority": @3 },
];

NSURL *url = [NSURL fileURLWithPath:path];
NSError *err = nil;
BOOL ok = [tasks writeToURL:url error:&err];
```

`writeToURL:error:` сериализует массив в plist и пишет в файл. Обратно:

```objc
NSArray *back = [NSArray arrayWithContentsOfURL:url error:&err];
```

`fileURLWithPath:` превращает строку-путь в файловый `NSURL` — именно его
ждут современные методы `writeToURL:` / `arrayWithContentsOfURL:`.
(Старые `writeToFile:atomically:` и `arrayWithContentsOfFile:` тоже
существуют, но без `error:`, поэтому новые предпочтительнее.)

**Главное ограничение plist:** внутри могут лежать только
**plist-совместимые типы**. Их ровно шесть: `NSString`, `NSNumber`,
`NSDate`, `NSData`, `NSArray`, `NSDictionary` (ключи словаря — только
строки). Сунешь туда свой класс `Task` или `NSNull` — запись провалится:
`writeToURL:error:` вернёт `NO` и положит причину в `err`.
Для своих объектов нужна архивация (следующий раздел).

Под капотом всем этим заведует класс **`NSPropertyListSerialization`** —
низкоуровневый мотор, который превращает коллекцию в `NSData` нужного
формата и обратно:

```objc
NSData *plistData = [NSPropertyListSerialization
    dataWithPropertyList:tasks
                  format:NSPropertyListXMLFormat_v1_0
                 options:0
                   error:&err];

NSArray *obj = [NSPropertyListSerialization
    propertyListWithData:plistData
                 options:NSPropertyListImmutable
                  format:NULL
                   error:&err];
```

`dataWithPropertyList:format:options:error:` даёт байты (можно выбрать
XML- или бинарный формат), `propertyListWithData:...` разбирает их
обратно. Методы `writeToURL:` у коллекций — просто удобная обёртка над
ним. Знать этот класс полезно, когда нужен контроль над форматом или
сериализация в память, а не в файл.

## JSON: NSJSONSerialization

JSON — самый ходовой формат обмена данными между программами и серверами.
Foundation работает с ним через класс **`NSJSONSerialization`**: два
метода, туда и обратно.

### Объект → JSON

```objc
NSData *json = [NSJSONSerialization
                   dataWithJSONObject:tasks
                              options:NSJSONWritingPrettyPrinted
                                error:&err];
```

`dataWithJSONObject:options:error:` берёт коллекцию и возвращает `NSData`
с её JSON-представлением. `options`:

- `0` — компактный JSON в одну строку;
- `NSJSONWritingPrettyPrinted` — с отступами, удобно читать глазами;
- `NSJSONWritingSortedKeys` — ключи по алфавиту (стабильный вывод).

**Что можно превращать в JSON.** Корень — `NSArray` или `NSDictionary`.
Значения — `NSString`, `NSNumber` (числа и `@YES`/`@NO` → `true`/`false`),
вложенные массивы/словари и `NSNull` (станет `null`). Ключи словаря —
только строки. `NSDate`, `NSData` или свой класс напрямую не лезут — их
сначала надо привести к строке/числу.

Осторожно: здесь `NSJSONSerialization` ведёт себя не так, как при чтении.
Неподходящий объект внутри коллекции — это не `nil` с ошибкой, а
**исключение** `NSInvalidArgumentException` («Invalid type in JSON
write»), и программа падает. Если не уверен в данных, спроси заранее:
`[NSJSONSerialization isValidJSONObject:tasks]` вернёт `YES` или `NO`.

### JSON → объект

```objc
NSData *raw = [NSData dataWithContentsOfFile:path];
NSArray *parsed = [NSJSONSerialization JSONObjectWithData:raw
                                                  options:0
                                                    error:&err];
```

`JSONObjectWithData:options:error:` разбирает байты JSON в коллекцию.
Что в JSON было объектом `{}` — станет `NSDictionary`, массивом `[]` —
`NSArray`, и так далее. `options:0` — обычный режим (получаем
неизменяемые коллекции). Если нужно потом менять результат, передай
`NSJSONReadingMutableContainers`.

### Ошибки — через возврат, не через краш

Это ключевое отличие от ручного разбора. Дай методу битый JSON — он не
уронит программу, а вернёт `nil` и положит причину в `err`:

```objc
NSData *broken = [@"{ это не json }"
                     dataUsingEncoding:NSUTF8StringEncoding];
id bad = [NSJSONSerialization JSONObjectWithData:broken
                                         options:0
                                           error:&err];
// bad == nil, err.code == 3840 (ошибка разбора)
```

Всегда проверяй результат на `nil` перед тем, как им пользоваться:
данные из сети или из чужого файла ломаются регулярно.

> **Отличие от Си.** В Си «разобрать JSON» означает либо писать парсер
> руками (символ за символом), либо тащить стороннюю библиотеку — а потом
> следить, чтобы битый ввод не привёл к выходу за границы массива и краху.
> `NSJSONSerialization` встроен, разбирает любой корректный JSON одним
> вызовом, а на некорректном аккуратно возвращает `nil` с описанием
> ошибки. Никакой ручной работы с байтами и никаких сегфолтов.

## Строим с нуля: список задач в JSON-файл

Соберём всё вместе. Задача: есть список дел — **массив словарей**.
Сохраним его в JSON-файл во временной папке, прочитаем обратно и поработаем
с прочитанными данными.

### Шаг 1. Данные

```objc
NSArray<NSDictionary *> *tasks = @[
    @{ @"title": @"Купить кофе",    @"done": @YES, @"priority": @1 },
    @{ @"title": @"Написать главу", @"done": @NO,  @"priority": @3 },
    @{ @"title": @"Прогуляться",    @"done": @NO,  @"priority": @2 },
];
```

Каждая задача — словарь с тремя ключами. Все значения JSON-совместимы:
строка, булево `@YES`/`@NO` (это `NSNumber`), число. Корень — массив.

### Шаг 2. В файл и обратно

```objc
NSData *json = [NSJSONSerialization
                   dataWithJSONObject:tasks
                              options:NSJSONWritingPrettyPrinted
                                error:&err];
[json writeToFile:jsonPath atomically:YES];

NSData *raw = [NSData dataWithContentsOfFile:jsonPath];
NSArray *parsed = [NSJSONSerialization JSONObjectWithData:raw
                                                  options:0
                                                    error:&err];
```

Превратили массив в байты, записали, прочитали байты назад, разобрали в
массив. Четыре вызова — и данные совершили круг через диск.

### Шаг 3. Работаем с прочитанным

`parsed` — обычный `NSArray` словарей, с ним работают приёмы из главы 17.
Отберём невыполненные и отсортируем по приоритету:

```objc
NSArray *open = [parsed filteredArrayUsingPredicate:
    [NSPredicate predicateWithFormat:@"done == NO"]];
NSArray *sorted = [open sortedArrayUsingDescriptors:@[
    [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:NO] ]];
```

Полный файл — `code/19-json.m` (там же показан plist и ловля битого
JSON). Вывод:

```text
plist: прочитали задач: 3, первая: Купить кофе
JSON-файл: 269 байт
содержимое файла:
[
  {
    "done" : true,
    "priority" : 1,
    "title" : "Купить кофе"
  },
  {
    "done" : false,
    "priority" : 3,
    "title" : "Написать главу"
  },
  {
    "done" : false,
    "priority" : 2,
    "title" : "Прогуляться"
  }
]
невыполненные задачи по приоритету:
  [3] Написать главу
  [2] Прогуляться
битый JSON -> nil (код ошибки 3840)
временные файлы удалены
```

`@YES`/`@NO` стали `true`/`false`, кириллица сохранилась, а битый JSON
честно вернул `nil`. Список задач пережил запись на диск и чтение обратно.

## Архивация объектов: NSSecureCoding

JSON и plist хороши для коллекций простых значений. Но как сохранить
**свой объект** — экземпляр класса `Task` со всеми его полями? Превращать
его руками в словарь и обратно утомительно и легко ошибиться. Foundation
предлагает **архивацию**: объект сам описывает, как себя записать и как
восстановиться.

Механизм построен на протоколе **`NSCoding`** (его строгий потомок —
**`NSSecureCoding`**) и архиваторе **`NSKeyedArchiver`**.

### Учим класс кодировать себя

Чтобы объект можно было заархивировать, его класс принимает протокол
`NSSecureCoding` и реализует два метода: «запиши себя» и «восстанови
себя».

```objc
@interface Task : NSObject <NSSecureCoding>
@property (nonatomic, copy)   NSString *title;
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, assign) BOOL done;
@end
```

```objc
+ (BOOL)supportsSecureCoding { return YES; }

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeInteger:self.priority forKey:@"priority"];
    [coder encodeBool:self.done forKey:@"done"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _title = [coder decodeObjectOfClass:[NSString class] forKey:@"title"];
        _priority = [coder decodeIntegerForKey:@"priority"];
        _done = [coder decodeBoolForKey:@"done"];
    }
    return self;
}
```

Разберём по частям.

- **`+ (BOOL)supportsSecureCoding { return YES; }`** — обязательное
  согласие класса на «безопасное» разархивирование. Без него
  `NSKeyedUnarchiver` откажется работать в безопасном режиме.
- **`encodeWithCoder:`** — здесь объект записывает каждое поле под
  собственным **ключом** (строкой). `encodeObject:forKey:` — для
  объектов, `encodeInteger:forKey:` — для целых, `encodeBool:forKey:` —
  для булевых. Есть и `encodeDouble:`, `encodeInt:` и другие под разные
  типы.
- **`initWithCoder:`** — обратный метод: достаёт поля по тем же ключам.
  `decodeIntegerForKey:` и `decodeBoolForKey:` возвращают значение
  напрямую. А для объекта используется **`decodeObjectOfClass:forKey:`**
  — и вот тут проявляется «безопасность» `NSSecureCoding`: ты заранее
  объявляешь, *какого класса* объект ожидаешь (`NSString`). Если в архиве
  под этим ключом окажется что-то другое (например, подменённый
  злонамеренный объект), декодирование провалится, а не создаст что
  попало.

> **Отличие от Си.** В Си нет понятия «объект сам себя сохраняет». Чтобы
> положить структуру на диск, ты вручную пишешь каждое её поле: `fwrite`
> числа, `fwrite` длины строки, `fwrite` байтов строки — и так же
> вручную читаешь обратно в строгом порядке. Один сдвиг или забытое поле
> — и весь файл рассыпается. Здесь объект сам перечисляет поля по
> **именованным ключам**: порядок не важен, новое поле добавил — старые
> архивы всё ещё читаются (просто новый ключ вернёт `nil`/0).

### Архивируем и восстанавливаем

Когда класс умеет кодироваться, превратить объект в байты — один вызов:

```objc
NSError *err = nil;
NSData *data = [NSKeyedArchiver archivedDataWithRootObject:task
                                    requiringSecureCoding:YES
                                                    error:&err];
```

`archivedDataWithRootObject:requiringSecureCoding:error:` берёт объект
(корень графа) и возвращает `NSData` — готовый архив. `requiringSecureCoding:YES`
требует, чтобы класс поддерживал `NSSecureCoding` (наш поддерживает).
Эти байты можно писать в файл как любой `NSData`:

```objc
[data writeToFile:path atomically:YES];
```

Обратно:

```objc
NSData *raw = [NSData dataWithContentsOfFile:path];
Task *back = [NSKeyedUnarchiver unarchivedObjectOfClass:[Task class]
                                               fromData:raw
                                                  error:&err];
```

`unarchivedObjectOfClass:fromData:error:` поднимает объект из байтов. Ты
снова указываешь **ожидаемый класс корня** (`[Task class]`) — та же
защита. Если архив повреждён или класс не тот, вернётся `nil` и
заполнится `err`.

### Защита в действии

Попробуем распаковать наш архив `Task` как `NSDate` — заведомо не тот
класс:

```objc
Task *wrong = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSDate class]
                                                fromData:raw
                                                   error:&err];
// wrong == nil, err != nil — аккуратная ошибка, не краш
```

Полный пример — `code/19-archive.m`. Вывод:

```text
исходный: <Task 'Заархивировать объект' p5 готово>
архив занял 284 байт
восстановили: <Task 'Заархивировать объект' p5 готово>
title совпал? 1
распаковка как NSDate -> nil (есть ошибка? 1)
архивный файл удалён
```

Объект совершил круг: `Task` → `NSData` → файл → `NSData` → `Task`, и все
три поля вернулись на место. А попытка прочитать его «не тем классом»
аккуратно дала `nil` с ошибкой.

## Какой формат когда

- **Строка/байты** (`writeToFile:`/`NSData`) — простой текст, лог,
  готовый файл. Никакой структуры.
- **Property list** — коллекции из встроенных типов, настройки, мелкие
  структуры. Только plist-совместимые типы, родной формат Apple.
- **JSON** — обмен с сетью и другими программами. Коллекции простых
  значений, читается всем миром.
- **Архив (`NSKeyedArchiver`)** — свои объекты со своими полями, графы
  объектов со связями. Формат «для своих»: читается в основном кодом на
  Apple-платформах.

## Проверяем

Все четыре файла собираются и запускаются так (имя меняй):

```text
clang -fobjc-arc -framework Foundation -Wall -Wextra -O2 \
    code/19-filemanager.m -o /tmp/t && /tmp/t
```

Файлы главы:

- `code/19-filemanager.m` — папки, файлы, атрибуты, удаление.
- `code/19-readwrite.m` — строки и `NSData` в файл и обратно.
- `code/19-json.m` — plist и JSON, список задач через диск.
- `code/19-archive.m` — класс `Task` с `NSSecureCoding`, архивация.

Каждый собирается без предупреждений, пишет только во временную папку и
сам удаляет за собой файлы. Дата, время и пути в выводе будут свои.

## Частые ошибки

- **Не та кодировка при чтении.** Записал в `NSUTF8StringEncoding`, читаешь
  в другой — кириллица превратится в мусор или чтение вернёт `nil`. Пиши
  и читай в одной кодировке, по умолчанию UTF-8.
- **Не проверил результат.** `stringWithContentsOfFile:`,
  `JSONObjectWithData:`, `unarchivedObjectOfClass:` возвращают `nil` при
  сбое. Используешь результат без проверки — поедешь дальше с `nil` и
  получишь пустоту или странности. Проверяй возврат, потом смотри `err`.
- **Несовместимый тип в plist/JSON.** Положил в массив свой объект,
  `NSDate` (для JSON) или `NSNull` (для plist) — сериализация провалится.
  Plist вернёт `NO`/`nil` с ошибкой, а `dataWithJSONObject:` бросит
  исключение и уронит программу — проверяй `isValidJSONObject:`. В
  plist/JSON идут только разрешённые типы; свои объекты — через архивацию.
- **Забыл `supportsSecureCoding` или `decodeObjectOfClass:`.** Без
  `+supportsSecureCoding` → `YES` архивация с `requiringSecureCoding:YES`
  не удастся: вернётся `nil` и ошибка «Class 'Task' does not adopt it».
  А если в `initWithCoder:` для объекта взять старый
  `decodeObjectForKey:` вместо `decodeObjectOfClass:forKey:`, безопасный
  распаковщик не узнает, какой класс ты ждёшь по этому ключу, и сверит
  значение только со списком классов корня. По нашим экспериментам строку
  он ещё пропустит, а `NSDate` или массив — уже нет: вся распаковка
  вернёт `nil` с ошибкой «value for key … was of unexpected class».
- **Пишешь не во временную/Documents папку.** В приложении с песочницей
  запись в произвольный путь провалится (`writeToFile:` вернёт `NO`, а
  если не проверять возврат, ты этого и не заметишь).
  Спрашивай папку у системы: `NSTemporaryDirectory()` или
  `NSSearchPathForDirectoriesInDomains`.
- **`atomically:NO` для важных данных.** Прервётся запись — получишь
  полуфайл. Для всего, что жалко потерять, ставь `YES`.

## Упражнения

1. Допиши `code/19-filemanager.m`: после создания файлов посчитай их
   суммарный размер, пройдя `contentsOfDirectoryAtPath:` и складывая
   `NSFileSize` каждого.
2. Сохрани словарь «город → население» (`@{ @"Алматы": @2000000, ... }`)
   в plist через `writeToURL:error:`, прочитай назад
   `dictionaryWithContentsOfURL:error:` и выведи только города-миллионники.
3. Возьми список задач из `19-json.m`, добавь каждой ключ `@"tags"` с
   массивом строк. Убедись, что JSON по-прежнему пишется и читается
   (вложенные массивы JSON разрешены).
4. Попробуй разобрать JSON из файла, которого нет
   (`dataWithContentsOfFile:` вернёт `nil`). Поймай ситуацию до вызова
   `JSONObjectWithData:` (с `nil` вместо данных он бросит исключение) и
   выведи понятное сообщение, не уронив программу.
5. Добавь классу `Task` поле `NSDate *createdAt`. Закодируй его
   `encodeObject:forKey:`, раскодируй `decodeObjectOfClass:[NSDate class]
   forKey:`. Проверь, что дата переживает архивацию.
6. Сделай массив из трёх `Task` и заархивируй его целиком одним вызовом
   `archivedDataWithRootObject:`. При распаковке используй
   `unarchivedObjectOfClasses:` с набором `[NSArray class]` и
   `[Task class]`. Подумай, почему классов теперь два.

## Что мы получили

Теперь твои данные умеют переживать запуск программы. Ты управляешь
файлами и папками через `NSFileManager`, пишешь и читаешь строки и
`NSData` одним вызовом, сохраняешь целые коллекции в **plist** и **JSON**
и поднимаешь их назад, а свои объекты учишь сохранять себя через
**`NSSecureCoding`** и `NSKeyedArchiver`. И ты увидел общий принцип
Foundation: ошибки приходят через возврат `nil`/`NO` и `NSError`, а не
через краш, — поэтому битый файл или чужой JSON программу не роняют.

В отличие от си-шного `fopen`/`fwrite`, где ты ворочал байтами и сам
изобретал формат, здесь весь объект или коллекция ложатся на диск и
встают обратно готовыми вызовами. Дальше, в главе 20, разберём KVC и KVO
— как читать и менять свойства объекта по имени и как подписываться на их
изменения; механика `valueForKey:`, мелькавшая в главе 17 (и неявно работавшая
здесь в `NSPredicate` и `NSSortDescriptor`), развернётся в полную силу.

## Документация Apple

- `NSFileManager` —
  developer.apple.com/documentation/foundation/filemanager
- `NSString` (запись/чтение файла) —
  developer.apple.com/documentation/foundation/nsstring
- `NSData` — developer.apple.com/documentation/foundation/nsdata
- `NSJSONSerialization` —
  developer.apple.com/documentation/foundation/jsonserialization
- `NSPropertyListSerialization` —
  developer.apple.com/documentation/foundation/propertylistserialization
- `NSKeyedArchiver` —
  developer.apple.com/documentation/foundation/nskeyedarchiver
- `NSKeyedUnarchiver` —
  developer.apple.com/documentation/foundation/nskeyedunarchiver
- `NSSecureCoding` —
  developer.apple.com/documentation/foundation/nssecurecoding
- `NSCoding` — developer.apple.com/documentation/foundation/nscoding
- Archives and Serializations Programming Guide (архив Apple) —
  developer.apple.com/library/archive/documentation/Cocoa/Conceptual/
  Archiving/Archiving.html (plist, архивы и кодирование объектов одним
  обзором).
