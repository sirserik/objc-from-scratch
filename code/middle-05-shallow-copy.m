#import <Foundation/Foundation.h>

/* Задача: поверхностная копия коллекции. copy/mutableCopy копируют
   только верхний контейнер; вложенные объекты остаются ОБЩИМИ.
   Меняем вложенный мутабельный объект — изменение видно в обеих
   коллекциях. */

int main(void) {
    @autoreleasepool {
        NSMutableArray *inner = [NSMutableArray arrayWithObjects:@"a", @"b", nil];
        NSArray *original = @[inner, @"hello"];

        /* mutableCopy делает НОВЫЙ массив, но кладёт в него ТЕ ЖЕ
           объекты (поверхностно). inner — один на обе коллекции. */
        NSMutableArray *shallow = [original mutableCopy];

        NSLog(@"разные контейнеры? %@",
              (original != shallow) ? @"да" : @"нет");
        NSLog(@"общий вложенный массив? %@",
              (original[0] == shallow[0]) ? @"да" : @"нет");

        /* меняем вложенный мутабельный массив через одну коллекцию */
        [inner addObject:@"c"];

        NSLog(@"original[0] = %@", original[0]);  /* a, b, c */
        NSLog(@"shallow[0]  = %@", shallow[0]);   /* a, b, c — то же! */

        /* глубокая копия: архивируем и разворачиваем */
        NSError *err = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:original
                                            requiringSecureCoding:NO
                                                            error:&err];
        NSArray *deep = [NSKeyedUnarchiver
            unarchivedObjectOfClasses:
                [NSSet setWithObjects:[NSArray class],
                                      [NSMutableArray class],
                                      [NSString class], nil]
                             fromData:data
                                error:&err];
        [inner addObject:@"d"];
        NSLog(@"после deep-копии inner += d:");
        NSLog(@"original[0] = %@", original[0]);  /* a, b, c, d */
        NSLog(@"deep[0]     = %@", deep[0]);       /* a, b, c — не задет */
    }
    return 0;
}
