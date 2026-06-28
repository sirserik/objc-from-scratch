#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* Множество из массива: дубликаты схлопываются автоматически. */
        NSArray *raw = @[ @"кофе", @"чай", @"кофе", @"сок", @"чай" ];
        NSSet *drinks = [NSSet setWithArray:raw];
        NSLog(@"в массиве %lu, в множестве %lu (дубли убраны)",
              (unsigned long)[raw count], (unsigned long)[drinks count]);

        /* containsObject: — быстрая проверка членства. */
        NSLog(@"есть чай? %d", [drinks containsObject:@"чай"]);
        NSLog(@"есть морс? %d", [drinks containsObject:@"морс"]);

        /* Перебор — порядок не определён (множество неупорядочено). */
        for (NSString *d in drinks) {
            NSLog(@"напиток: %@", d);
        }

        /* --- Операции над множествами --- */
        NSMutableSet *cafeA = [NSMutableSet setWithArray:@[ @"кофе",
                                                            @"чай",
                                                            @"какао" ]];
        NSSet *cafeB = [NSSet setWithArray:@[ @"чай", @"сок", @"какао" ]];

        /* Пересечение: оставить только общие. */
        NSMutableSet *common = [cafeA mutableCopy];
        [common intersectSet:cafeB];
        NSLog(@"общие: %@", [[common allObjects]
                             componentsJoinedByString:@", "]);

        /* Объединение: добавить всё из второго. */
        NSMutableSet *all = [cafeA mutableCopy];
        [all unionSet:cafeB];
        NSLog(@"вместе: %@", [[all allObjects]
                              componentsJoinedByString:@", "]);

        /* Разность: убрать из A то, что есть в B. */
        NSMutableSet *only = [cafeA mutableCopy];
        [only minusSet:cafeB];
        NSLog(@"только в A: %@", [[only allObjects]
                                 componentsJoinedByString:@", "]);

        /* addObject: дубликат молча игнорируется. */
        [cafeA addObject:@"чай"];
        NSLog(@"после повторного добавления чая: %lu",
              (unsigned long)[cafeA count]);

        /* --- NSOrderedSet: уникальность + порядок --- */
        NSOrderedSet *menu = [NSOrderedSet orderedSetWithArray:
                              @[ @"суп", @"салат", @"суп", @"чай" ]];
        NSLog(@"меню по порядку: %@",
              [[menu array] componentsJoinedByString:@", "]);
        NSLog(@"первый в меню: %@", [menu firstObject]);
    }
    return 0;
}
