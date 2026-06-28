#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* Упаковка примитива в объект — три способа. */
        NSNumber *a = @42;          /* литерал-число */
        NSNumber *pi = @3.14;       /* литерал-дробь */
        NSNumber *yes = @YES;       /* литерал-BOOL  */
        NSNumber *letter = @'A';    /* литерал-char  */

        /* @(...) упаковывает результат любого выражения. */
        int x = 7, y = 5;
        NSNumber *sum = @(x + y);

        /* Фабричные методы — то же самое словами. */
        NSNumber *big = [NSNumber numberWithDouble:2.5];

        /* Печатаем сами объекты: %@ спрашивает у NSNumber описание. */
        NSLog(@"a=%@ pi=%@ yes=%@ letter=%@", a, pi, yes, letter);
        NSLog(@"sum=%@ big=%@", sum, big);

        /* Распаковка — достаём примитив обратно. */
        int ai = [a intValue];
        double pid = [pi doubleValue];
        BOOL yb = [yes boolValue];
        NSLog(@"распаковка: ai=%d pid=%.2f yb=%d", ai, pid, yb);

        /* Зачем это нужно: положить число в массив (он хранит объекты). */
        NSArray *nums = @[ @10, @20, @(x * y) ];
        NSLog(@"массив чисел: %@", nums);

        /* Достаём из массива объект и распаковываем в примитив. */
        NSNumber *third = nums[2];
        NSLog(@"третий как int: %d", [third intValue]);
    }
    return 0;
}
