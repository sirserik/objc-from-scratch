#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* __block делает переменную ОБЩЕЙ ячейкой:
           и внешний код, и блок видят и меняют одно и то же count. */
        __block int count = 0;

        void (^tick)(void) = ^{
            count++;   /* без __block это была бы ошибка компиляции */
        };

        tick();
        tick();
        tick();
        NSLog(@"блок сработал %d раза", count);

        /* Накопитель: блок собирает сумму в __block-переменную. */
        __block int sum = 0;
        NSArray *numbers = @[@10, @20, @30, @40];
        void (^add)(NSNumber *) = ^(NSNumber *n) {
            sum += n.intValue;
        };
        for (NSNumber *n in numbers) {
            add(n);
        }
        NSLog(@"сумма = %d", sum);
    }
    return 0;
}
