#import <Foundation/Foundation.h>

/* Глава 19. Сериализация коллекций: property list и JSON.
 * Строим список задач (массив словарей), сохраняем в файл и читаем назад. */

int main(void) {
    @autoreleasepool {
        NSString *dir = NSTemporaryDirectory();
        NSFileManager *fm = [NSFileManager defaultManager];

        /* Наши данные: массив словарей. Все значения — plist/JSON-совместимые
         * типы: NSString, NSNumber, NSArray, NSDictionary. */
        NSArray<NSDictionary *> *tasks = @[
            @{ @"title": @"Купить кофе", @"done": @YES,  @"priority": @1 },
            @{ @"title": @"Написать главу", @"done": @NO, @"priority": @3 },
            @{ @"title": @"Прогуляться", @"done": @NO,  @"priority": @2 },
        ];

        /* ---------- property list ---------- */
        NSURL *plistURL =
            [NSURL fileURLWithPath:
                [dir stringByAppendingPathComponent:@"tasks.plist"]];

        NSError *err = nil;
        /* Коллекция сама пишет себя в plist. requiringSecureCoding для plist
         * не нужен — формат фиксирован. */
        BOOL ok = [tasks writeToURL:plistURL error:&err];
        if (!ok) {
            NSLog(@"plist не записан: %@", err.localizedDescription);
            return 1;
        }
        NSArray *fromPlist = [NSArray arrayWithContentsOfURL:plistURL
                                                       error:&err];
        NSLog(@"plist: прочитали задач: %lu, первая: %@",
              (unsigned long)fromPlist.count,
              fromPlist.firstObject[@"title"]);

        /* ---------- JSON ---------- */
        NSString *jsonPath =
            [dir stringByAppendingPathComponent:@"tasks.json"];

        /* 1. Объект -> JSON-байты. Pretty-печать ради читаемости файла. */
        NSData *json = [NSJSONSerialization dataWithJSONObject:tasks
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&err];
        if (!json) {
            NSLog(@"в JSON не превратилось: %@", err.localizedDescription);
            return 1;
        }
        [json writeToFile:jsonPath atomically:YES];
        NSLog(@"JSON-файл: %lu байт", (unsigned long)json.length);

        /* Посмотрим, как он выглядит текстом. */
        NSString *asText = [[NSString alloc] initWithData:json
                                                 encoding:NSUTF8StringEncoding];
        NSLog(@"содержимое файла:\n%@", asText);

        /* 2. JSON-байты -> объект. Читаем файл и разбираем. */
        NSData *raw = [NSData dataWithContentsOfFile:jsonPath];
        NSArray *parsed = [NSJSONSerialization JSONObjectWithData:raw
                                                          options:0
                                                            error:&err];
        if (!parsed) {
            NSLog(@"JSON не разобрался: %@", err.localizedDescription);
            return 1;
        }

        /* Пройдёмся по разобранным задачам. */
        NSLog(@"невыполненные задачи по приоритету:");
        NSArray *open = [parsed filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"done == NO"]];
        NSArray *sorted = [open sortedArrayUsingDescriptors:@[
            [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:NO] ]];
        for (NSDictionary *t in sorted) {
            NSLog(@"  [%@] %@", t[@"priority"], t[@"title"]);
        }

        /* 3. Битый JSON ловится ошибкой, а не крахом. */
        NSData *broken = [@"{ это не json }"
                            dataUsingEncoding:NSUTF8StringEncoding];
        id bad = [NSJSONSerialization JSONObjectWithData:broken
                                                 options:0
                                                   error:&err];
        NSLog(@"битый JSON -> %@ (код ошибки %ld)",
              bad ? @"объект" : @"nil", (long)err.code);

        /* Убираем за собой. */
        [fm removeItemAtPath:jsonPath error:NULL];
        [fm removeItemAtURL:plistURL error:NULL];
        NSLog(@"временные файлы удалены");
    }
    return 0;
}
