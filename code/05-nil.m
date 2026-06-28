#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* nil — это "никакого объекта". */
        NSString *empty = nil;

        /* Сообщение к nil НЕ роняет программу. */
        NSUInteger len = [empty length];
        NSLog(@"длина nil-строки: %lu", (unsigned long)len);   /* 0 */

        NSString *up = [empty uppercaseString];
        NSLog(@"uppercase от nil: %@", up);                    /* (null) */

        BOOL b = [empty hasPrefix:@"При"];
        NSLog(@"hasPrefix у nil: %d", b);                      /* 0 = NO */

        /* id — переменная под любой объект. Тут в ней nil. */
        id thing = nil;
        NSLog(@"сообщение к id-nil: %@", [thing description]);

        /* Проверка на nil перед делом — обычный приём. */
        NSString *name = nil;
        if (name == nil) {
            NSLog(@"имя не задано");
        } else {
            NSLog(@"имя: %@", name);
        }
    }
    return 0;
}
