#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* Латиница: байт = code unit = человеческий символ. */
        NSString *en = @"cafe";
        NSLog(@"'cafe'  length = %lu", (unsigned long)[en length]);

        /* Кириллица: length считает буквы, strlen считал байты. */
        NSString *ru = @"Привет";
        NSLog(@"'Привет' length = %lu, UTF-8 байт = %lu",
              (unsigned long)[ru length],
              (unsigned long)strlen([ru UTF8String]));

        /* Эмодзи вне базовой плоскости = ДВА UTF-16 code units. */
        NSString *emoji = @"🍎";
        NSLog(@"'🍎'    length = %lu (а человек видит 1 символ)",
              (unsigned long)[emoji length]);

        /* Флаг = пара символов: length = 4, человек видит 1. */
        NSString *flag = @"🇰🇿";
        NSLog(@"'🇰🇿'    length = %lu (а человек видит 1 флаг)",
              (unsigned long)[flag length]);

        /* Правильный подсчёт «человеческих» символов. */
        NSString *mix = @"a🍎🇰🇿b";
        NSLog(@"'a🍎🇰🇿b' length = %lu",
              (unsigned long)[mix length]);

        __block NSUInteger humanCount = 0;
        [mix enumerateSubstringsInRange:NSMakeRange(0, [mix length])
                                options:NSStringEnumerationByComposedCharacterSequences
                             usingBlock:^(NSString *sub,
                                          NSRange subRange,
                                          NSRange enclosing,
                                          BOOL *stop) {
            (void)subRange;
            (void)enclosing;
            (void)stop;
            humanCount++;
            NSLog(@"  символ #%lu = %@",
                  (unsigned long)humanCount, sub);
        }];
        NSLog(@"человеческих символов: %lu",
              (unsigned long)humanCount);
    }
    return 0;
}
