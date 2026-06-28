#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface Button : NSObject
- (void)tap;
@end

@implementation Button
- (void)tap { NSLog(@"  Button: обычное нажатие"); }
@end

/* Безопасная подмена: сначала пробуем class_addMethod — если метод orig
   достался по наследству, мы добавим его в наш класс, а не перепишем
   родителю. Если orig уже определён в самом классе — обмениваем. */
static void swizzle(Class cls, SEL orig, SEL swiz) {
    Method mOrig = class_getInstanceMethod(cls, orig);
    Method mSwiz = class_getInstanceMethod(cls, swiz);

    BOOL added = class_addMethod(cls, orig,
                                 method_getImplementation(mSwiz),
                                 method_getTypeEncoding(mSwiz));
    if (added) {
        class_replaceMethod(cls, swiz,
                            method_getImplementation(mOrig),
                            method_getTypeEncoding(mOrig));
    } else {
        method_exchangeImplementations(mOrig, mSwiz);
    }
}

@interface Button (Analytics)
@end

@implementation Button (Analytics)

/* +load выполняется один раз при загрузке образа и потокобезопасен.
   dispatch_once — пояс поверх подтяжек: страховка от повторной подмены. */
+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        swizzle(self, @selector(tap), @selector(analytics_tap));
    });
}

- (void)analytics_tap {
    NSLog(@"  [analytics] зафиксировали нажатие");
    /* После обмена этот вызов уходит на ОРИГИНАЛЬНЫЙ tap.
       Это не рекурсия: имя analytics_tap теперь ведёт на старый код tap. */
    [self analytics_tap];
}

@end

int main(void) {
    @autoreleasepool {
        Button *b = [[Button alloc] init];
        NSLog(@"нажимаем кнопку:");
        [b tap];
    }
    return 0;
}
