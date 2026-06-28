#import <Foundation/Foundation.h>

/* typedef для типа блока: даём длинному типу короткое имя.
   Greeter — блок, который принимает NSString * и ничего не возвращает. */
typedef void (^Greeter)(NSString *);

int main(void) {
    @autoreleasepool {
        /* Локальная переменная окружения. */
        int factor = 3;

        /* Блок ЗАХВАТЫВАЕТ factor — копирует его текущее значение (3). */
        int (^multiply)(int) = ^(int x) {
            return x * factor;
        };

        NSLog(@"3 * 5 = %d", multiply(5));

        /* Меняем factor ПОСЛЕ создания блока. */
        factor = 100;
        /* Блок всё равно помнит старое значение 3 — он снял копию. */
        NSLog(@"factor теперь %d, но блок помнит 3 * 5 = %d",
              factor, multiply(5));

        /* typedef в деле: переменная типа Greeter. */
        NSString *prefix = @"Привет";
        Greeter greet = ^(NSString *name) {
            /* prefix захвачен из окружения. */
            NSLog(@"%@, %@!", prefix, name);
        };
        greet(@"Мир");
        greet(@"Серик");
    }
    return 0;
}
