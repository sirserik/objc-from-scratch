#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* Литерал @[...] — готовый неизменяемый NSArray. */
        NSArray *fruits = @[ @"яблоко", @"банан", @"вишня" ];

        /* count — сколько элементов. Возвращает NSUInteger. */
        NSLog(@"всего: %lu", (unsigned long)[fruits count]);

        /* Доступ по индексу: метод и короткая запись через [] . */
        NSString *first = [fruits objectAtIndex:0];
        NSString *second = fruits[1];          /* субскрипт */
        NSLog(@"первый=%@ второй=%@", first, second);

        /* firstObject / lastObject — без риска выйти за границу. */
        NSLog(@"перв=%@ посл=%@", [fruits firstObject], [fruits lastObject]);

        /* containsObject: — есть ли такой элемент (сравнение isEqual:). */
        BOOL hasBanana = [fruits containsObject:@"банан"];
        NSLog(@"банан внутри? %d", hasBanana);

        /* indexOfObject: — на каком месте; NSNotFound, если нет. */
        NSUInteger idx = [fruits indexOfObject:@"вишня"];
        NSLog(@"вишня на позиции %lu", (unsigned long)idx);
        NSUInteger miss = [fruits indexOfObject:@"манго"];
        NSLog(@"манго найдено? %d", miss != NSNotFound);

        /* componentsJoinedByString: — склеить в одну строку. */
        NSLog(@"список: %@", [fruits componentsJoinedByString:@", "]);

        /* --- NSMutableArray: тот же массив, но изменяемый --- */
        NSMutableArray *cart = [[NSMutableArray alloc] init];
        [cart addObject:@"хлеб"];              /* в конец */
        [cart addObject:@"молоко"];
        [cart insertObject:@"соль" atIndex:0]; /* в начало */
        [cart replaceObjectAtIndex:1 withObject:@"батон"];
        [cart removeObject:@"молоко"];         /* по значению */
        NSLog(@"корзина: %@", [cart componentsJoinedByString:@", "]);
        [cart removeObjectAtIndex:0];          /* по индексу */
        NSLog(@"после удаления[0]: %@",
              [cart componentsJoinedByString:@", "]);

        /* arrayWithCapacity: — подсказка о размере (не предел). */
        NSMutableArray *big = [NSMutableArray arrayWithCapacity:100];
        [big addObject:@"x"];
        NSLog(@"в big элементов: %lu", (unsigned long)[big count]);

        /* --- Перебор --- */
        /* Быстрый перебор for-in: по значениям, без индекса. */
        for (NSString *f in fruits) {
            NSLog(@"for-in: %@", f);
        }

        /* enumerateObjectsUsingBlock: даёт и индекс, и stop. */
        [fruits enumerateObjectsUsingBlock:^(id obj, NSUInteger i,
                                             BOOL *stop) {
            NSLog(@"блок [%lu] = %@", (unsigned long)i, obj);
            if (i == 1) {
                *stop = YES;   /* прерываем перебор досрочно */
            }
        }];

        /* Обратный перебор: опция NSEnumerationReverse. */
        [fruits enumerateObjectsWithOptions:NSEnumerationReverse
                                 usingBlock:^(id obj, NSUInteger i,
                                              BOOL *stop) {
            NSLog(@"обратно [%lu] = %@", (unsigned long)i, obj);
            (void)stop;
        }];
    }
    return 0;
}
