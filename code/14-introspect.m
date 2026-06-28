#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* Живая интроспекция: спрашиваем у класса в рантайме его имя,
   суперклассы, список методов экземпляра и список ivar'ов.
   В Си так нельзя — там тип исчезает после компиляции. */

@interface Vehicle : NSObject {
    int _wheels;            /* ivar базового класса */
}
- (void)move;
- (int)wheels;
@end

@implementation Vehicle
- (void)move  { NSLog(@"еду"); }
- (int)wheels { return _wheels; }
@end

@interface Car : Vehicle {
    NSString *_brand;       /* ivar потомка */
}
- (void)honk;
- (void)refuel:(int)liters;
@end

@implementation Car
- (void)honk            { NSLog(@"би-бип"); }
- (void)refuel:(int)l   { NSLog(@"залил %d л", l); }
@end

/* Печатаем все методы экземпляра, объявленные ИМЕННО в этом классе
   (унаследованные не входят — они лежат в суперклассах). */
static void dumpMethods(Class c) {
    unsigned int count = 0;
    Method *methods = class_copyMethodList(c, &count);
    NSLog(@"методы класса %s (%u шт.):", class_getName(c), count);
    for (unsigned int i = 0; i < count; i++) {
        SEL name = method_getName(methods[i]);
        NSLog(@"    - %s   (аргументов: %u)",
              sel_getName(name),
              method_getNumberOfArguments(methods[i]));
    }
    free(methods);          /* список выделен malloc — освобождаем сами */
}

/* Печатаем ivar'ы, объявленные в этом классе. */
static void dumpIvars(Class c) {
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList(c, &count);
    NSLog(@"поля класса %s (%u шт.):", class_getName(c), count);
    for (unsigned int i = 0; i < count; i++) {
        NSLog(@"    - %s : %s",
              ivar_getName(ivars[i]),
              ivar_getTypeEncoding(ivars[i]));
    }
    free(ivars);
}

/* Поднимаемся по цепочке суперклассов до самого корня. */
static void dumpHierarchy(Class c) {
    NSLog(@"иерархия:");
    NSMutableString *line = [NSMutableString string];
    while (c) {
        [line appendString:[NSString stringWithUTF8String:class_getName(c)]];
        c = class_getSuperclass(c);
        if (c) [line appendString:@" -> "];
    }
    NSLog(@"    %@", line);
}

int main(void) {
    @autoreleasepool {
        Car *car = [[Car alloc] init];
        Class c = object_getClass(car);

        dumpHierarchy(c);
        dumpMethods(c);
        dumpIvars(c);

        /* А методы родителя — в самом родителе. */
        dumpMethods([Vehicle class]);

        /* class_respondsToSelector: учитывает наследование. */
        NSLog(@"Car отвечает на move (от родителя)? %@",
              class_respondsToSelector(c, @selector(move)) ? @"да" : @"нет");
        NSLog(@"Car отвечает на honk? %@",
              class_respondsToSelector(c, @selector(honk)) ? @"да" : @"нет");
        NSLog(@"Car отвечает на fly? %@",
              class_respondsToSelector(c, @selector(fly))  ? @"да" : @"нет");
    }
    return 0;
}
