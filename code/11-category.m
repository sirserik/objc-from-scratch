#import <Foundation/Foundation.h>

// Категория: добавляем методы к УЖЕ существующему классу NSString,
// не наследуя его и не имея его исходников.
//
// Здесь две версии разворота строки:
//   naiveReversedString — по одному unichar с конца. Ломает эмодзи.
//   reversedString      — по «человеческим» символам. Работает всегда.

@interface NSString (MyUtils)
- (NSString *)naiveReversedString;   // первая попытка, с изъяном
- (NSString *)reversedString;        // строка задом наперёд
- (BOOL)isPalindrome;                // читается одинаково в обе стороны?
@end

@implementation NSString (MyUtils)

- (NSString *)naiveReversedString {
    NSUInteger length = self.length;
    NSMutableString *result =
        [NSMutableString stringWithCapacity:length];
    // Идём с конца к началу и доклеиваем по одному unichar.
    for (NSUInteger i = length; i > 0; i--) {
        unichar c = [self characterAtIndex:i - 1];
        [result appendFormat:@"%C", c];
    }
    return [result copy];
}

- (NSString *)reversedString {
    NSMutableString *result =
        [NSMutableString stringWithCapacity:self.length];
    // Перебираем СОСТАВНЫЕ символы: эмодзи с модификатором, «е»+умляут
    // и прочие многокодовые последовательности идут одним куском.
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length)
        options:NSStringEnumerationByComposedCharacterSequences
        usingBlock:^(NSString *piece, NSRange substringRange,
                     NSRange enclosingRange, BOOL *stop) {
        (void)substringRange; (void)enclosingRange; (void)stop;
        [result insertString:piece atIndex:0];   // каждый кусок — в начало
    }];
    return [result copy];
}

- (BOOL)isPalindrome {
    return [self isEqualToString:[self reversedString]];
}

@end

int main(void) {
    @autoreleasepool {
        NSString *word = @"кефир";
        NSLog(@"%@ наоборот: %@", word, [word reversedString]);

        NSString *a = @"шалаш";
        NSString *b = @"кефир";
        NSLog(@"%@ — палиндром? %@", a,
              a.isPalindrome ? @"да" : @"нет");
        NSLog(@"%@ — палиндром? %@", b,
              b.isPalindrome ? @"да" : @"нет");

        // Метод работает и на строковом литерале, и на результате
        // других методов Foundation — это всё тот же NSString.
        NSString *upper = [@"abcba" uppercaseString];
        NSLog(@"%@ — палиндром? %@", upper,
              upper.isPalindrome ? @"да" : @"нет");

        // А теперь строка с эмодзи — на ней наивная версия рассыпается.
        NSString *withEmoji = @"привет 👋 мир";
        NSString *broken = [withEmoji naiveReversedString];
        NSData *utf8 = [broken dataUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"наивный разворот переводится в UTF-8: %@",
              utf8 ? @"да" : @"нет — строка битая");
        NSLog(@"наивно:    %@", broken);
        NSLog(@"аккуратно: %@", [withEmoji reversedString]);
    }
    return 0;
}
