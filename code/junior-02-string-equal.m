#import <Foundation/Foundation.h>

/* == сравнивает АДРЕСА (один ли это объект), isEqualToString: — СОДЕРЖИМОЕ.
   Две разные строки с одинаковым текстом равны по содержимому, но это
   разные объекты в памяти. */
int main(void) {
    @autoreleasepool {
        NSString *a = @"hello";
        /* stringWithFormat: строит НОВЫЙ объект с тем же текстом
           (короткую строку runtime упакует прямо в указатель —
           tagged pointer, поэтому «адрес» b выглядит странно) */
        NSString *b = [NSString stringWithFormat:@"%@%@", @"hel", @"lo"];

        NSLog(@"a == b               : %d", (a == b));
        NSLog(@"[a isEqualToString:b]: %d", [a isEqualToString:b]);
        NSLog(@"адрес a = %p", (__bridge void *)a);
        NSLog(@"адрес b = %p", (__bridge void *)b);
    }
    return 0;
}
