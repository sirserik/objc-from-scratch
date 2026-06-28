#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* 1. Литерал — самый частый способ. */
        NSString *hello = @"Привет";
        NSLog(@"литерал:        %@", hello);

        /* 2. stringWithFormat: — собрать строку из кусков. */
        NSString *name = @"Серик";
        int age = 40;
        NSString *line = [NSString stringWithFormat:@"%@, тебе %d",
                                                    name, age];
        NSLog(@"формат:         %@", line);

        /* 3. initWithFormat: — то же, но через alloc/init. */
        NSString *line2 = [[NSString alloc] initWithFormat:@"%@!", name];
        NSLog(@"alloc/init:     %@", line2);

        /* 4. Из си-строки (char *) в NSString. */
        const char *c = "raw C string";
        NSString *fromC = [NSString stringWithUTF8String:c];
        NSLog(@"из C-строки:    %@", fromC);

        /* 5. Обратно: из NSString в си-строку (const char *). */
        const char *back = [fromC UTF8String];
        NSLog(@"в C-строку:     %s (это уже char*)", back);

        /* 6. length — длина в UTF-16 code units. */
        NSLog(@"length 'Привет': %lu", (unsigned long)[hello length]);

        /* 7. Строка -> число. */
        NSString *priceText = @"199.90";
        NSString *countText = @"7 штук";
        NSLog(@"doubleValue:    %.2f", [priceText doubleValue]);
        NSLog(@"intValue:       %d", [countText intValue]);

        /* 8. Число -> строка снова через формат. */
        double total = [priceText doubleValue] * [countText intValue];
        NSString *totalText = [NSString stringWithFormat:@"%.2f тенге",
                                                         total];
        NSLog(@"итог строкой:   %@", totalText);
    }
    return 0;
}
