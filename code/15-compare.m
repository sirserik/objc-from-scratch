#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* Две РАЗНЫЕ строки с одинаковым текстом. */
        NSString *a = @"яблоко";
        NSString *b = [NSString stringWithFormat:@"%@", @"яблоко"];

        /* == сравнивает адреса, а не буквы. */
        NSLog(@"a == b:                %@", (a == b) ? @"YES" : @"NO");
        /* isEqualToString: сравнивает содержимое. */
        NSLog(@"isEqualToString:       %@",
              [a isEqualToString:b] ? @"YES" : @"NO");

        /* compare: даёт порядок: ordered ascending/same/descending. */
        NSComparisonResult r = [@"apple" compare:@"banana"];
        NSLog(@"compare apple/banana:  %ld (-1 = первый раньше)",
              (long)r);

        /* Регистр игнорируем через caseInsensitiveCompare:. */
        NSComparisonResult ci =
            [@"Apple" caseInsensitiveCompare:@"apple"];
        NSLog(@"caseInsensitive:       %ld (0 = равны)", (long)ci);

        /* Префикс / суффикс / вхождение. */
        NSString *file = @"report-2026.pdf";
        NSLog(@"hasPrefix report-:     %@",
              [file hasPrefix:@"report-"] ? @"YES" : @"NO");
        NSLog(@"hasSuffix .pdf:        %@",
              [file hasSuffix:@".pdf"] ? @"YES" : @"NO");
        NSLog(@"containsString 2026:   %@",
              [file containsString:@"2026"] ? @"YES" : @"NO");

        /* Поиск: rangeOfString: возвращает NSRange. */
        NSRange range = [file rangeOfString:@"-"];
        if (range.location == NSNotFound) {
            NSLog(@"дефис не найден");
        } else {
            NSLog(@"дефис на позиции:      %lu",
                  (unsigned long)range.location);
        }

        /* Подстроки. */
        NSString *namePart = [file substringToIndex:range.location];
        NSString *tailPart = [file substringFromIndex:range.location + 1];
        NSLog(@"substringToIndex:      %@", namePart);
        NSLog(@"substringFromIndex:    %@", tailPart);

        /* Регистр. */
        NSLog(@"uppercaseString:       %@", [@"привет" uppercaseString]);
        NSLog(@"lowercaseString:       %@", [@"ПРИВЕТ" lowercaseString]);
        NSLog(@"capitalizedString:     %@",
              [@"мир добра" capitalizedString]);

        /* Обрезка пробелов по краям. */
        NSString *messy = @"   hello world   ";
        NSCharacterSet *ws =
            [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *clean = [messy stringByTrimmingCharactersInSet:ws];
        NSLog(@"trim:                  '%@'", clean);
    }
    return 0;
}
