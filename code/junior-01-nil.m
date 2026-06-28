#import <Foundation/Foundation.h>

/* Сообщение к nil безопасно. Результат — «нулевой» для типа возврата:
   0 для чисел, nil для объектов, NO для BOOL. Программа не падает. */
int main(void) {
    @autoreleasepool {
        NSString *s = nil;

        NSUInteger len = [s length];            /* число  -> 0   */
        NSString  *up  = [s uppercaseString];   /* объект -> nil */
        BOOL       has = [s hasPrefix:@"a"];     /* BOOL   -> NO  */

        NSLog(@"[nil length]           = %lu", (unsigned long)len);
        NSLog(@"[nil uppercaseString]  = %@",  up);
        NSLog(@"[nil hasPrefix:@\"a\"]   = %d",  has);
    }
    return 0;
}
