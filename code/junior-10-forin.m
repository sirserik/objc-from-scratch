#import <Foundation/Foundation.h>

/* Быстрый перебор for-in проходит коллекцию слева направо. Менять
   коллекцию ПРЯМО во время перебора нельзя — это краш. Правильный приём:
   собрать кандидатов на удаление в отдельный массив, потом удалить. */
int main(void) {
    @autoreleasepool {
        NSArray *fruits = @[@"яблоко", @"банан", @"вишня"];
        for (NSString *f in fruits) {
            NSLog(@"фрукт: %@ (длина %lu)", f, (unsigned long)f.length);
        }

        NSMutableArray *nums = [@[@1, @2, @3, @4, @5] mutableCopy];
        NSMutableArray *toRemove = [NSMutableArray array];
        for (NSNumber *x in nums) {           /* только ЧИТАЕМ nums */
            if (x.intValue % 2 == 0) {
                [toRemove addObject:x];        /* копим, не трогая nums */
            }
        }
        [nums removeObjectsInArray:toRemove];  /* удаляем ПОСЛЕ перебора */
        NSLog(@"без чётных: %@", nums);
    }
    return 0;
}
