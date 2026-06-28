#import <Foundation/Foundation.h>

/* Тот же Counter, но с собственным init.
   Минимальный init: подробно разберём в главе 7. */
@interface Counter : NSObject
{
    NSInteger _value;
}
- (instancetype)init;
- (void)increment;
- (NSInteger)value;
@end

@implementation Counter

- (instancetype)init {
    self = [super init];   /* спросили базовый класс — детали в главе 7 */
    if (self) {
        _value = 100;      /* наше стартовое значение */
    }
    return self;
}

- (void)increment {
    _value = _value + 1;
}

- (NSInteger)value {
    return _value;
}

@end

int main(void) {
    @autoreleasepool {
        Counter *c = [[Counter alloc] init];
        NSLog(@"старт = %ld", (long)[c value]);   /* 100 */
        [c increment];
        NSLog(@"после ++ = %ld", (long)[c value]); /* 101 */
    }
    return 0;
}
