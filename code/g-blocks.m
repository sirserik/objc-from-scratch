// Как в Objective-C: блоки ^{ } (см. главу 12).
// Захват по умолчанию = КОПИЯ значения (как [=] в C++).
// Чтобы изменять захваченную переменную — пометь её __block
// (аналог захвата по ссылке + mutable в одном).
// Сборка:
//   clang -fobjc-arc -framework Foundation -Wall -Wextra -O2 \
//       g-blocks.m -o /tmp/t && /tmp/t
#import <Foundation/Foundation.h>

// Тип блока удобно спрятать за typedef (аналог std::function<int(int)>):
typedef int (^IntTransform)(int);

int main(void) {
    @autoreleasepool {
        int base = 10;

        // Обычный захват: блок берёт КОПИЮ base в момент создания.
        IntTransform addByCopy = ^(int x) { return base + x; };

        // __block: переменная общая, блок видит и меняет её.
        __block int counter = 0;
        void (^tick)(void) = ^{ counter++; };

        base = 100;
        NSLog(@"addByCopy(5) = %d", addByCopy(5));  // 15 (зафиксировал старое base)

        tick(); tick(); tick();
        NSLog(@"counter = %d", counter);            // 3

        // Блок как аргумент (аналог передачи лямбды в алгоритм):
        NSArray *nums = @[@1, @2, @3, @4];
        __block int sum = 0;
        [nums enumerateObjectsUsingBlock:^(NSNumber *n, NSUInteger idx,
                                           BOOL *stop) {
            (void)idx; (void)stop;
            sum += n.intValue;
        }];
        NSLog(@"sum = %d", sum);                     // 10
    }
    return 0;
}
