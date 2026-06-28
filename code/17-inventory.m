#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* Журнал продаж за день: имена товаров, с повторами. */
        NSArray *sales = @[ @"кофе", @"чай", @"кофе", @"кофе",
                            @"сок", @"чай", @"кофе" ];
        NSLog(@"всего продаж: %lu", (unsigned long)[sales count]);

        /* Шаг 1. Подсчёт: имя товара → сколько раз продан. */
        NSMutableDictionary *counts = [NSMutableDictionary dictionary];
        for (NSString *item in sales) {
            NSNumber *prev = counts[item];        /* nil, если впервые */
            NSInteger n = prev ? [prev integerValue] : 0;
            counts[item] = @(n + 1);
        }
        for (NSString *item in counts) {
            NSLog(@"  %@: %@ шт.", item, counts[item]);
        }

        /* Шаг 2. Уникальные товары — это просто ключи словаря. */
        NSSet *unique = [NSSet setWithArray:[counts allKeys]];
        NSLog(@"разных товаров: %lu", (unsigned long)[unique count]);

        /* Шаг 3. Категории проданного — множество без повторов. */
        NSDictionary *category = @{
            @"кофе" : @"горячее",
            @"чай"  : @"горячее",
            @"сок"  : @"холодное",
        };
        NSMutableSet *soldCats = [NSMutableSet set];
        for (NSString *item in unique) {
            [soldCats addObject:category[item]];
        }
        NSLog(@"категории: %@",
              [[soldCats allObjects] componentsJoinedByString:@", "]);

        /* Шаг 4. Рейтинг: ключи, отсортированные по убыванию продаж. */
        NSArray *top = [[counts allKeys] sortedArrayUsingComparator:
            ^NSComparisonResult(id a, id b) {
                return [counts[b] compare:counts[a]];  /* по убыванию */
            }];
        NSLog(@"--- рейтинг ---");
        for (NSString *item in top) {
            NSLog(@"  %@ — %@", item, counts[item]);
        }

        /* Шаг 5. Убрать «однодневок» (продано < 2). Менять словарь
           прямо в for-in нельзя — сначала собираем ключи, потом
           удаляем отдельным проходом. */
        NSMutableArray *toRemove = [NSMutableArray array];
        for (NSString *item in counts) {
            if ([counts[item] integerValue] < 2) {
                [toRemove addObject:item];
            }
        }
        for (NSString *item in toRemove) {
            [counts removeObjectForKey:item];
        }
        NSLog(@"осталось ходовых: %@",
              [[counts allKeys] componentsJoinedByString:@", "]);
    }
    return 0;
}
