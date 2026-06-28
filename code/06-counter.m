#import <Foundation/Foundation.h>

/* Объявление класса: что Counter умеет. */
@interface Counter : NSObject
{
    NSInteger _value;   /* ivar — внутреннее число счётчика */
}
- (void)increment;      /* метод экземпляра: увеличить на 1 */
- (void)decrement;      /* метод экземпляра: уменьшить на 1 */
- (NSInteger)value;     /* метод экземпляра: вернуть число */
- (void)report;         /* метод экземпляра: напечатать число */
+ (Counter *)counter;   /* метод класса: создать готовый счётчик */
@end

/* Реализация класса: как Counter это делает. */
@implementation Counter

- (void)increment {
    _value = _value + 1;
}

- (void)decrement {
    _value = _value - 1;
}

- (NSInteger)value {
    return _value;
}

- (void)report {
    NSLog(@"счётчик = %ld", (long)[self value]);
}

+ (Counter *)counter {
    return [[Counter alloc] init];
}

@end

int main(void) {
    @autoreleasepool {
        Counter *c = [[Counter alloc] init];
        [c report];            /* 0 */
        [c increment];
        [c increment];
        [c increment];
        [c report];            /* 3 */
        [c decrement];
        [c report];            /* 2 */

        Counter *c2 = [Counter counter];
        [c2 increment];
        [c2 report];           /* 1 */
    }
    return 0;
}
