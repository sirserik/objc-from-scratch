#import <Foundation/Foundation.h>

/* Задача: что выведет блок — захват по значению vs __block.
   Обычный захват снимает КОПИЮ значения в момент создания блока.
   __block превращает переменную в общую ячейку: блок видит изменения. */

int main(void) {
    @autoreleasepool {
        /* 1. Обычный захват — копия на момент создания. */
        int x = 10;
        void (^plain)(void) = ^{
            NSLog(@"plain видит x = %d", x);  /* всегда 10 */
        };
        x = 99;                 /* меняем ПОСЛЕ создания блока */
        plain();                /* напечатает 10, не 99 */

        /* 2. __block — общая ячейка, блок видит свежее значение. */
        __block int y = 10;
        void (^shared)(void) = ^{
            NSLog(@"shared видит y = %d", y);
        };
        y = 99;                 /* меняем ПОСЛЕ создания блока */
        shared();               /* напечатает 99 */

        /* 3. Классическая ловушка: создаём блоки в цикле.
           Без __block каждый блок захватил СВОЮ копию i на момент
           создания. */
        NSMutableArray<void (^)(void)> *blocks = [NSMutableArray array];
        for (int i = 0; i < 3; i++) {
            [blocks addObject:^{ NSLog(@"блок помнит i = %d", i); }];
        }
        for (void (^blk)(void) in blocks) { blk(); }  /* 0, 1, 2 */
    }
    return 0;
}
