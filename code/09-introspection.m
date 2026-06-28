#import <Foundation/Foundation.h>

@interface Animal : NSObject
- (NSString *)speak;
@end

@implementation Animal
- (NSString *)speak { return @"..."; }
@end

@interface Dog : Animal
- (void)fetch;
@end

@implementation Dog
- (NSString *)speak { return @"Гав!"; }
- (void)fetch { NSLog(@"   %@: принёс мячик", [self class]); }
@end

int main(void) {
    @autoreleasepool {
        /* Тип переменной — Animal*, но фактический объект — Dog. */
        Animal *a = [[Dog alloc] init];

        /* Спрашиваем у объекта его класс и суперкласс. */
        NSLog(@"[a class]      = %@", [a class]);       /* Dog    */
        NSLog(@"[a superclass] = %@", [a superclass]);  /* Animal */

        /* isKindOfClass: — объект ЭТОГО класса ИЛИ его потомок? */
        NSLog(@"kind of Dog?      %@",
              [a isKindOfClass:[Dog class]]      ? @"да" : @"нет");
        NSLog(@"kind of Animal?   %@",
              [a isKindOfClass:[Animal class]]   ? @"да" : @"нет");
        NSLog(@"kind of NSObject? %@",
              [a isKindOfClass:[NSObject class]] ? @"да" : @"нет");

        /* isMemberOfClass: — РОВНО этот класс, без учёта потомков. */
        NSLog(@"member of Dog?    %@",
              [a isMemberOfClass:[Dog class]]    ? @"да" : @"нет");
        NSLog(@"member of Animal? %@",
              [a isMemberOfClass:[Animal class]] ? @"да" : @"нет");

        /* respondsToSelector: — объект ответит на это сообщение? */
        NSLog(@"умеет fetch?     %@",
              [a respondsToSelector:@selector(fetch)]     ? @"да" : @"нет");
        NSLog(@"умеет addObject? %@",
              [a respondsToSelector:@selector(addObject:)] ? @"да" : @"нет");

        /* Тип переменной — Animal*, fetch в нём не объявлен.
           Сначала убеждаемся, что объект умеет fetch, потом зовём,
           приведя указатель к Dog*, чтобы компилятор не ругался. */
        if ([a respondsToSelector:@selector(fetch)]) {
            [(Dog *)a fetch];
        }
    }
    return 0;
}
