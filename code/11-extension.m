#import <Foundation/Foundation.h>

// Публичный интерфейс: счётчик показывает значение, но менять его
// снаружи нельзя — свойство только для чтения (readonly).
@interface Counter : NSObject
@property (nonatomic, readonly) NSInteger value;
- (void)increment;
- (void)reset;
@end

// Расширение класса (class extension) — анонимная категория ().
// Живёт в .m: её видит только код этого файла, стоящий ниже.
// Другие файлы подключают лишь публичный @interface. Здесь:
//  1) переобъявляем value как readwrite — внутри можно писать;
//  2) добавляем приватное свойство step (шаг счётчика);
//  3) объявляем приватный метод-помощник.
@interface Counter ()
@property (nonatomic, readwrite) NSInteger value;
@property (nonatomic) NSInteger step;
- (void)logChange;
@end

@implementation Counter

- (instancetype)init {
    self = [super init];
    if (self) {
        _value = 0;
        _step = 1;   // приватное состояние, наружу не торчит
    }
    return self;
}

- (void)increment {
    self.value += self.step;   // пишем в «readonly» свойство изнутри
    [self logChange];
}

- (void)reset {
    self.value = 0;
    [self logChange];
}

- (void)logChange {           // приватный метод
    NSLog(@"  значение теперь: %ld", (long)self.value);
}

@end

int main(void) {
    @autoreleasepool {
        Counter *c = [[Counter alloc] init];
        NSLog(@"старт, value = %ld", (long)c.value);
        [c increment];
        [c increment];
        [c increment];
        NSLog(@"читаем снаружи: value = %ld", (long)c.value);
        [c reset];
        // В файле, который видит только публичный @interface, строка
        // ниже не скомпилируется: error: assignment to readonly property.
        // Здесь main стоит ниже расширения и видит readwrite-версию.
        // c.value = 100;
    }
    return 0;
}
