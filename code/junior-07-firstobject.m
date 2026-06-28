#import <Foundation/Foundation.h>

/* firstObject / lastObject на пустом массиве возвращают nil — безопасно.
   А objectAtIndex:0 на пустом массиве РОНЯЕТ программу (выход за границу).
   Поэтому крайние элементы берут через firstObject / lastObject. */
int main(void) {
    @autoreleasepool {
        NSArray *empty = @[];

        NSLog(@"firstObject пустого: %@", [empty firstObject]);   /* nil */
        NSLog(@"lastObject  пустого: %@", [empty lastObject]);    /* nil */
        /* [empty objectAtIndex:0]  — КРАШ, его мы НЕ вызываем */

        NSArray *nums = @[@10, @20, @30];
        NSLog(@"firstObject:     %@", [nums firstObject]);
        NSLog(@"objectAtIndex:0: %@", [nums objectAtIndex:0]);
        NSLog(@"lastObject:      %@", [nums lastObject]);
    }
    return 0;
}
