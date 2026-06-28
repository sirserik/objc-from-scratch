// Как в Objective-C: КАТЕГОРИЯ дописывает метод прямо в ЧУЖОЙ класс —
// даже в системный NSString. После этого метод доступен у ЛЮБОЙ строки,
// как родной. В C++ так нельзя: только свободная функция или наследник.
// Сборка:
//   clang -fobjc-arc -framework Foundation -Wall -Wextra -O2 \
//       g-category.m -o /tmp/t && /tmp/t
#import <Foundation/Foundation.h>

// Добавляем метод -shout прямо в NSString. Своего подкласса не заводим.
@interface NSString (Shout)
- (NSString *)shout;
@end

@implementation NSString (Shout)
- (NSString *)shout {
    return [[self uppercaseString] stringByAppendingString:@"!"];
}
@end

int main(void) {
    @autoreleasepool {
        // Литерал @"..." — обычный NSString, и он уже умеет наш метод:
        NSLog(@"%@", [@"привет" shout]);          // ПРИВЕТ!

        // Работает и для строки, пришедшей из недр Foundation:
        NSString *path = NSTemporaryDirectory();
        NSLog(@"%@", [[path lastPathComponent] shout]);

        // Метод виден всем строкам в программе — это не подкласс,
        // а правка самого NSString во время загрузки образа.
        NSArray *words = @[@"a", @"bb", @"ccc"];
        for (NSString *w in words) {
            NSLog(@"%@", [w shout]);
        }
    }
    return 0;
}
