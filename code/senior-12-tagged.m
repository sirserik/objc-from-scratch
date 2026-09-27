#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* volatile заставляет создать NSNumber В РАНТАЙМЕ, а не сложить
           литерал в константу на этапе компиляции. Так мы видим именно
           tagged pointer, а не дедупликацию констант компилятором. */

        /* Маленькое число влезает в биты самого указателя (tagged pointer):
           отдельного объекта в куче нет. Два одинаковых маленьких числа
           дают ОДИН и тот же указатель -> == случайно срабатывает. */
        volatile NSInteger small = 5;
        NSNumber *a = [NSNumber numberWithInteger:(NSInteger)small];
        NSNumber *b = [NSNumber numberWithInteger:(NSInteger)small];
        NSLog(@"маленькое 5:  a == b (указатели)? %@   класс=%@",
              (a == b) ? @"да" : @"нет", [a class]);
        NSLog(@"   a=%p  b=%p  (свой в каждом запуске)",
              (__bridge void *)a, (__bridge void *)b);

        /* Большое число в указатель не влезает -> настоящий объект в куче.
           Два таких равны по значению, но НЕ по указателю. */
        volatile NSInteger big = 1234567890123456789LL;
        NSNumber *c = [NSNumber numberWithInteger:(NSInteger)big];
        NSNumber *d = [NSNumber numberWithInteger:(NSInteger)big];
        NSLog(@"большое число: c == d (указатели)? %@   класс=%@",
              (c == d) ? @"да" : @"нет", [c class]);
        NSLog(@"   c=%p  d=%p  (обычные адреса в куче)",
              (__bridge void *)c, (__bridge void *)d);

        /* Вывод: == для NSNumber — лотерея, зависит от значения и сборки.
           Сравнивать ТОЛЬКО через isEqual:. */
        NSLog(@"isEqual: всегда верно: маленькие %@, большие %@",
              [a isEqual:b]       ? @"равны" : @"нет",
              [c isEqual:d]       ? @"равны" : @"нет");
    }
    return 0;
}
