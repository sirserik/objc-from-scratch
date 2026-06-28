#import <Foundation/Foundation.h>

/* Для чисел та же история, что и для строк: содержимое сравнивает
   isEqualToNumber:, а == сравнивает указатели — и доверять ему нельзя.
   Коварство в том, что для МАЛЕНЬКИХ чисел == иногда «случайно» прав
   (рантайм хранит их прямо в указателе), а для других — врёт. */
int main(void) {
    @autoreleasepool {
        NSNumber *a = @42;
        NSNumber *b = @42;

        /* два разных объекта с одинаковым дробным значением */
        NSNumber *x = [NSNumber numberWithDouble:12345.6789];
        NSNumber *y = [NSNumber numberWithDouble:12345.6789];

        NSLog(@"@42 == @42                : %d", (a == b));
        NSLog(@"[@42 isEqualToNumber:@42] : %d", [a isEqualToNumber:b]);

        NSLog(@"x == y                    : %d", (x == y));
        NSLog(@"[x isEqualToNumber:y]     : %d", [x isEqualToNumber:y]);
    }
    return 0;
}
