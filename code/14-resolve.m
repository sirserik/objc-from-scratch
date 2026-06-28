#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* Динамическое разрешение метода: класс НЕ реализует greet,
   но при первом обращении runtime спрашивает класс
   +resolveInstanceMethod:, и тот «дорощивает» реализацию
   прямо во время выполнения через class_addMethod.
   resolve срабатывает ровно один раз — дальше метод уже в классе. */

/* Это обычная Си-функция. Её мы и подставим как реализацию метода.
   У каждого метода первые два скрытых аргумента — self и _cmd. */
static void dynamicGreet(id self, SEL _cmd) {
    NSLog(@"  привет от %@, селектор был :%s",
          [self class], sel_getName(_cmd));
}

@interface Robot : NSObject
@end

@implementation Robot

/* Runtime зовёт этот метод класса, когда не нашёл реализацию sel.
   Возвращаем YES, если сами добавили метод и просим повторить поиск. */
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    if (sel == @selector(greet)) {
        /* class_addMethod(класс, селектор, функция, кодировка-типов).
           "v@:" = void-результат, self(@), _cmd(:). */
        class_addMethod(self, sel, (IMP)dynamicGreet, "v@:");
        NSLog(@"  [resolve] добавили реализацию для %s", sel_getName(sel));
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

@end

int main(void) {
    @autoreleasepool {
        Robot *r = [[Robot alloc] init];

        NSLog(@"первый вызов greet:");
        [r performSelector:@selector(greet)];   /* запустит resolve */

        NSLog(@"второй вызов greet:");
        [r performSelector:@selector(greet)];   /* resolve уже НЕ нужен */
    }
    return 0;
}
