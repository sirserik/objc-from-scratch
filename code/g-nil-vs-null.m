// Как в Objective-C: сообщение к nil безопасно (см. главу 5).
// Никакой проверки перед каждым сообщением не нужно — runtime
// сам видит nil-получателя и возвращает нулевой результат.
// Сборка:
//   clang -fobjc-arc -framework Foundation -Wall -Wextra -O2 \
//       g-nil-vs-null.m -o /tmp/t && /tmp/t
#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        NSString *s = nil;   // объекта нет

        // Ни одно из этих сообщений не уронит программу:
        NSUInteger len = [s length];           // -> 0
        NSString  *up  = [s uppercaseString];  // -> nil
        BOOL       has = [s hasPrefix:@"При"];  // -> NO

        NSLog(@"length        = %lu", (unsigned long)len);
        NSLog(@"uppercaseStr  = %@", up);       // (null)
        NSLog(@"hasPrefix     = %d", has);      // 0

        NSString *real = @"hello";
        NSLog(@"real length   = %lu", (unsigned long)[real length]);
        NSLog(@"real upper     = %@", [real uppercaseString]);
    }
    return 0;
}
