#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        NSString *s = @"привет, objective-c";

        /* Сообщение без аргументов: length. */
        NSUInteger len = [s length];
        NSLog(@"длина: %lu", (unsigned long)len);

        /* Сообщение без аргументов, возвращает новую строку. */
        NSString *big = [s uppercaseString];
        NSLog(@"в верхнем регистре: %@", big);

        /* Сообщение с одним аргументом: hasPrefix:. Вернёт BOOL. */
        BOOL starts = [s hasPrefix:@"при"];
        NSLog(@"начинается с \"при\": %d", starts);

        /* Вложенные сообщения: сначала uppercaseString, потом length. */
        NSUInteger n = [[s uppercaseString] length];
        NSLog(@"длина верхнего: %lu", (unsigned long)n);

        /* Сообщение с аргументом-объектом: stringByAppendingString:. */
        NSString *full = [s stringByAppendingString:@"!"];
        NSLog(@"с восклицанием: %@", full);

        /* Сравнение строк: isEqualToString: (НЕ ==). */
        BOOL same = [s isEqualToString:@"привет, objective-c"];
        NSLog(@"строки равны: %d", same);
    }
    return 0;
}
