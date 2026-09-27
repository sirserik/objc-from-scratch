#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* Литерал @{ ключ : значение, ... } — неизменяемый NSDictionary. */
        NSDictionary *colors = @{
            @"яблоко" : @"красный",
            @"банан"  : @"жёлтый",
            @"слива"  : @"синий",
        };

        /* count — сколько пар ключ→значение. */
        NSLog(@"пар: %lu", (unsigned long)[colors count]);

        /* Доступ по ключу: метод и короткая запись через [] . */
        NSString *a = [colors objectForKey:@"яблоко"];
        NSString *b = colors[@"банан"];        /* субскрипт */
        NSLog(@"яблоко=%@ банан=%@", a, b);

        /* Нет такого ключа → nil (а не падение). */
        NSString *miss = colors[@"манго"];
        NSLog(@"манго=%@ (nil печатается как (null))", miss);

        /* allKeys / allValues — массивы ключей и значений. */
        NSLog(@"ключи: %@",
              [[colors allKeys] componentsJoinedByString:@", "]);

        /* --- NSMutableDictionary: изменяемый словарь --- */
        NSMutableDictionary *stock = [[NSMutableDictionary alloc] init];
        [stock setObject:@10 forKey:@"яблоко"];   /* метод */
        stock[@"банан"] = @5;                   /* субскрипт-присваивание */
        stock[@"слива"] = @3;
        NSLog(@"яблок на складе: %@", stock[@"яблоко"]);

        /* Тот же ключ ещё раз — значение заменяется, не добавляется. */
        stock[@"яблоко"] = @12;
        NSLog(@"после довоза яблок: %@", stock[@"яблоко"]);

        /* removeObjectForKey: — убрать пару. */
        [stock removeObjectForKey:@"слива"];
        NSLog(@"после списания слив пар: %lu", (unsigned long)[stock count]);

        /* --- Перебор словаря --- */
        /* for-in по словарю идёт ПО КЛЮЧАМ. */
        for (NSString *fruit in colors) {
            NSLog(@"%@ → %@", fruit, colors[fruit]);
        }

        /* enumerateKeysAndObjectsUsingBlock: даёт сразу ключ и значение. */
        [stock enumerateKeysAndObjectsUsingBlock:^(id key, id obj,
                                                   BOOL *stop) {
            NSLog(@"склад: %@ = %@ шт.", key, obj);
            (void)stop;
        }];
    }
    return 0;
}
