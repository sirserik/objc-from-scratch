#import <Foundation/Foundation.h>

/* Коллекции хранят только объекты. Голый int — не объект, его сначала
   надо «упаковать» в NSNumber: литералом @42 или @(выражение). */
int main(void) {
    @autoreleasepool {
        NSMutableArray *a = [NSMutableArray array];

        /* [a addObject:42];  // НЕ компилируется: 42 — не объект */
        [a addObject:@42];          /* упаковали число литералом */
        [a addObject:@(10 + 5)];    /* @(выражение) тоже работает */

        NSNumber *n = a[0];
        NSLog(@"храним объект:   %@", n);
        NSLog(@"распаковали int: %d", [n intValue]);
        NSLog(@"второй элемент:  %@", a[1]);

        /* распаковка разными типами */
        NSNumber *pi = @3.14;
        NSLog(@"double обратно:  %.2f", [pi doubleValue]);
    }
    return 0;
}
