#import <Foundation/Foundation.h>

// Категория: добавляем методы к УЖЕ существующему классу NSString,
// не наследуя его и не имея его исходников.

@interface NSString (MyUtils)
- (NSString *)reversedString;   // строка задом наперёд
- (BOOL)isPalindrome;           // читается одинаково в обе стороны?
@end

@implementation NSString (MyUtils)

- (NSString *)reversedString {
    NSUInteger length = self.length;
    NSMutableString *result =
        [NSMutableString stringWithCapacity:length];
    // Идём с конца к началу и доклеиваем по одному символу.
    for (NSUInteger i = length; i > 0; i--) {
        unichar c = [self characterAtIndex:i - 1];
        [result appendFormat:@"%C", c];
    }
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
    }
    return 0;
}
