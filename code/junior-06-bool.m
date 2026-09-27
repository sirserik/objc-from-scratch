#import <Foundation/Foundation.h>

/* BOOL — это да/нет: YES (1) и NO (0). Не сравнивай произвольное число
   с YES напрямую: проверяй сам факт «не ноль ли», то есть просто if (x). */
int main(void) {
    @autoreleasepool {
        NSLog(@"YES = %d, NO = %d", YES, NO);
        NSLog(@"sizeof(BOOL) = %zu байт", sizeof(BOOL));

        /* В массиве 3 элемента. Захотим «есть ли элементы» через BOOL: */
        NSArray *items = @[@"a", @"b", @"c"];
        BOOL hasItems = (items.count > 0);   /* ПРАВИЛЬНО: явное сравнение */
        NSLog(@"есть элементы: %d", hasItems);

        /* Опасный приём: затолкать count прямо в BOOL и сравнить с YES.
           count может оказаться кратным 256. На x86_64 (BOOL = signed
           char) младший байт даст 0; на arm64 (BOOL = bool) будет 1. */
        int weird = 256;
        BOOL fromInt = (BOOL)weird;
        NSLog(@"BOOL из числа 256 = %d", fromInt);
    }
    return 0;
}
