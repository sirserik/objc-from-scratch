#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* Показываем главный факт runtime: объект — это структура, у которой
   первое поле isa указывает на класс. Спрашиваем у объекта его класс
   двумя способами и убеждаемся, что это один и тот же указатель. */

@interface Dog : NSObject
@end

@implementation Dog
@end

int main(void) {
    @autoreleasepool {
        Dog *rex = [[Dog alloc] init];

        /* Способ 1: высокоуровневое сообщение -class. */
        Class c1 = [rex class];

        /* Способ 2: runtime читает поле isa напрямую. */
        Class c2 = object_getClass(rex);

        NSLog(@"[rex class]          = %s", class_getName(c1));
        NSLog(@"object_getClass(rex) = %s", class_getName(c2));
        NSLog(@"это один и тот же класс? %@",
              (c1 == c2) ? @"да" : @"нет");

        /* Класс — это адрес в памяти. Печатаем его как указатель. */
        NSLog(@"адрес класса Dog     = %p", (__bridge void *)c1);

        /* У класса можно спросить его суперкласс — тоже Class. */
        Class super = class_getSuperclass(c1);
        NSLog(@"суперкласс Dog       = %s", class_getName(super));

        /* Два разных объекта одного класса делят ОДИН указатель isa. */
        Dog *barsik = [[Dog alloc] init];
        NSLog(@"isa у rex и barsik совпадает? %@",
              (object_getClass(rex) == object_getClass(barsik))
              ? @"да" : @"нет");
    }
    return 0;
}
