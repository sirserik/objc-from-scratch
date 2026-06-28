#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* Method swizzling: меняем местами реализации двух методов прямо
   в рантайме через method_exchangeImplementations. После обмена
   старое имя ведёт на новый код, и наоборот. Это мощно и ОПАСНО —
   подменяешь поведение для ВСЕХ экземпляров класса разом. */

@interface Greeter : NSObject
- (NSString *)hello;
@end

@implementation Greeter
- (NSString *)hello { return @"привет"; }
@end

/* Наш «подменный» метод. Внутри он зовёт my_hello — но ПОСЛЕ обмена
   имён это уже не рекурсия: my_hello будет указывать на исходный hello. */
@interface Greeter (Swizzle)
@end

@implementation Greeter (Swizzle)
- (NSString *)my_hello {
    NSString *original = [self my_hello];        /* зовём старый hello */
    return [NSString stringWithFormat:@"[лог] %@!", original];
}
@end

int main(void) {
    @autoreleasepool {
        Greeter *g = [[Greeter alloc] init];
        NSLog(@"до обмена:  %@", [g hello]);

        /* Берём оба Method и меняем их IMP местами. */
        Method orig = class_getInstanceMethod([Greeter class],
                                              @selector(hello));
        Method swiz = class_getInstanceMethod([Greeter class],
                                              @selector(my_hello));
        method_exchangeImplementations(orig, swiz);

        /* Теперь hello выполняет код my_hello. Изменилось для ВСЕХ. */
        NSLog(@"после обмена: %@", [g hello]);

        Greeter *other = [[Greeter alloc] init];
        NSLog(@"и для нового объекта: %@", [other hello]);
    }
    return 0;
}
