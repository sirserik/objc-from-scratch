#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* Разбиение строки на массив по разделителю. */
        NSString *csv = @"яблоко,банан,груша";
        NSArray<NSString *> *parts =
            [csv componentsSeparatedByString:@","];
        NSLog(@"частей после split:    %lu",
              (unsigned long)[parts count]);
        NSLog(@"вторая часть:          %@", parts[1]);

        /* Склейка массива обратно в строку. */
        NSString *joined = [parts componentsJoinedByString:@" | "];
        NSLog(@"joined:                %@", joined);

        /* Immutable-склейка: каждый вызов рождает НОВУЮ строку. */
        NSString *base = @"Лог";
        NSString *one = [base stringByAppendingString:@": старт"];
        NSString *two = [one stringByAppendingFormat:@" (код %d)", 200];
        NSLog(@"appendString:          %@", one);
        NSLog(@"appendFormat:          %@", two);
        NSLog(@"base не изменилась:    %@", base);

        /* NSMutableString: меняем ОДИН объект на месте. */
        NSMutableString *log = [NSMutableString stringWithString:@"["];
        [log appendString:@"GET"];
        [log appendFormat:@" /users?page=%d", 2];
        [log appendString:@"]"];
        NSLog(@"mutable собрали:       %@", log);

        /* Замена всех вхождений: метод возвращает их количество. */
        NSUInteger n = [log replaceOccurrencesOfString:@"users"
                                            withString:@"clients"
                                               options:0
                                                 range:NSMakeRange(0,
                                                            [log length])];
        NSLog(@"замен сделано:         %lu", (unsigned long)n);
        NSLog(@"после замены:          %@", log);

        /* Вставка в середину по индексу. */
        [log insertString:@"HTTP " atIndex:1];
        NSLog(@"после вставки:         %@", log);
    }
    return 0;
}
