#import <Foundation/Foundation.h>

/* alloc выделяет память и обнуляет поля. init приводит объект в рабочее
   состояние — например задаёт значения по умолчанию. Если init забыть,
   объект останется «сырым»: поля нулевые, настройка не выполнена. */
@interface Box : NSObject
@property (nonatomic) NSInteger value;
@end

@implementation Box
- (instancetype)init {
    self = [super init];
    if (self) {
        _value = 100;   /* значение по умолчанию задаёт именно init */
    }
    return self;
}
@end

int main(void) {
    @autoreleasepool {
        Box *raw = [Box alloc];          /* только память, init НЕ звали */
        Box *ok  = [[Box alloc] init];   /* память + настройка           */

        NSLog(@"после alloc:        value = %ld", (long)raw.value);
        NSLog(@"после alloc + init: value = %ld", (long)ok.value);
    }
    return 0;
}
