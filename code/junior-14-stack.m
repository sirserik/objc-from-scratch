#import <Foundation/Foundation.h>

/* Стек (LIFO) поверх NSMutableArray: кладём и снимаем с одного конца.
   Внутреннее хранилище _items спрятано — снаружи виден только интерфейс
   push/pop/peek/isEmpty/count. */
@interface Stack : NSObject
- (void)push:(id)object;
- (id)pop;
- (id)peek;
- (BOOL)isEmpty;
- (NSUInteger)count;
@end

@implementation Stack {
    NSMutableArray *_items;   /* приватное хранилище */
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _items = [NSMutableArray array];
    }
    return self;
}

- (void)push:(id)object {
    [_items addObject:object];          /* кладём в конец */
}

- (id)pop {
    if (_items.count == 0) return nil;  /* защита от выхода за границу */
    id top = [_items lastObject];
    [_items removeLastObject];          /* снимаем с конца */
    return top;
}

- (id)peek {
    return [_items lastObject];         /* на пустом вернёт nil — ок */
}

- (BOOL)isEmpty {
    return _items.count == 0;
}

- (NSUInteger)count {
    return _items.count;
}

@end

int main(void) {
    @autoreleasepool {
        Stack *s = [[Stack alloc] init];
        NSLog(@"пустой в начале: %d", [s isEmpty]);

        [s push:@"a"];
        [s push:@"b"];
        [s push:@"c"];
        NSLog(@"после трёх push, count = %lu", (unsigned long)[s count]);
        NSLog(@"peek (не снимая): %@", [s peek]);

        NSLog(@"pop: %@", [s pop]);
        NSLog(@"pop: %@", [s pop]);
        NSLog(@"после двух pop, count = %lu", (unsigned long)[s count]);
        NSLog(@"pop: %@", [s pop]);
        NSLog(@"pop пустого: %@", [s pop]);   /* nil, без краша */
        NSLog(@"пустой в конце: %d", [s isEmpty]);
    }
    return 0;
}
