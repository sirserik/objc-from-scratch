#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface Calc : NSObject
- (int)addTo:(int)x;
@end

@implementation Calc
- (int)addTo:(int)x { return x + 100; }
@end

int main(void) {
    @autoreleasepool {
        Calc *c = [[Calc alloc] init];
        SEL sel = @selector(addTo:);

        NSLog(@"SEL как строка: %s", sel_getName(sel));

        /* Method = пара (SEL, IMP) + кодировка типов. */
        Method m = class_getInstanceMethod([Calc class], sel);
        NSLog(@"Method найден: %@", m ? @"да" : @"нет");
        NSLog(@"кодировка типов метода: %s", method_getTypeEncoding(m));
        NSLog(@"число аргументов (с учётом self и _cmd): %u",
              method_getNumberOfArguments(m));

        /* IMP — указатель на си-функцию-реализацию. */
        IMP impFromMethod = method_getImplementation(m);
        IMP impFromClass  = class_getMethodImplementation([Calc class], sel);
        NSLog(@"IMP из Method и из класса совпали? %@",
              (impFromMethod == impFromClass) ? @"да" : @"нет");

        /* Три пути вызова — результат один и тот же. */
        int viaMessage = [c addTo:5];                       /* обычная отправка */

        /* IMP зовём, приведя к точной сигнатуре (self, _cmd, аргументы). */
        int (*impFn)(id, SEL, int) = (int (*)(id, SEL, int))impFromMethod;
        int viaImp = impFn(c, sel, 5);

        /* objc_msgSend тоже приводим к точной сигнатуре метода. */
        int (*send)(id, SEL, int) = (int (*)(id, SEL, int))(void *)objc_msgSend;
        int viaSend = send(c, sel, 5);

        NSLog(@"[c addTo:5]        = %d", viaMessage);
        NSLog(@"через IMP          = %d", viaImp);
        NSLog(@"через objc_msgSend = %d", viaSend);
    }
    return 0;
}
