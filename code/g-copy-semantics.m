// Как в Objective-C: NSMutableArray — ОБЪЕКТ в куче.
// Присваивание копирует только УКАЗАТЕЛЬ. Оба имени смотрят
// на один и тот же объект — правка через одно видна через другое.
// Сборка:
//   clang -fobjc-arc -framework Foundation -Wall -Wextra -O2 \
//       g-copy-semantics.m -o /tmp/t && /tmp/t
#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        NSMutableArray *a = [NSMutableArray arrayWithObjects:
                             @"apple", @"banana", nil];
        NSMutableArray *b = a;        // копируется УКАЗАТЕЛЬ, не элементы

        [b addObject:@"cherry"];      // меняем «b» — но это тот же объект
        b[0] = @"APPLE";

        NSLog(@"a.count = %lu, a[0] = %@",
              (unsigned long)a.count, a[0]);   // 3, APPLE — изменился!
        NSLog(@"b.count = %lu, b[0] = %@",
              (unsigned long)b.count, b[0]);   // 3, APPLE

        NSLog(@"a == b (один объект)? %@", (a == b) ? @"да" : @"нет");

        // Нужна независимая копия — просим её явно:
        NSMutableArray *c = [a mutableCopy];
        [c addObject:@"date"];
        NSLog(@"после mutableCopy: a.count = %lu, c.count = %lu",
              (unsigned long)a.count, (unsigned long)c.count);  // 3 и 4
    }
    return 0;
}
