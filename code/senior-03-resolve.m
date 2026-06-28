#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static int g_resolveCalls = 0;

/* Реализации-функции. Скрытые аргументы любой IMP — self и _cmd. */
static id shoutImpl(id self, SEL _cmd) {
    return [NSString stringWithFormat:@"%@ кричит! (селектор был %s)",
            [self class], sel_getName(_cmd)];
}
static id twiceImpl(id self, SEL _cmd, id num) {
    (void)self; (void)_cmd;
    return @([num intValue] * 2);
}

@interface Ghost : NSObject
@end

/* Объявляем «динамические» методы. Реализаций в коде нет — их выдаст
   resolveInstanceMethod: при первом обращении. Объявление нужно лишь
   затем, чтобы компилятор знал сигнатуры и пропустил [g shout]/[g twice:]. */
@interface Ghost (Dynamic)
- (NSString *)shout;
- (NSNumber *)twice:(NSNumber *)n;
@end

@implementation Ghost

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    g_resolveCalls++;
    if (sel == @selector(shout)) {
        /* "@@:"  -> вернёт объект(@), принимает self(@) и _cmd(:) */
        class_addMethod(self, sel, (IMP)shoutImpl, "@@:");
        NSLog(@"  [resolve] доопределили %s", sel_getName(sel));
        return YES;
    }
    if (sel == @selector(twice:)) {
        /* "@@:@" -> вернёт объект, принимает self, _cmd и ещё объект */
        class_addMethod(self, sel, (IMP)twiceImpl, "@@:@");
        NSLog(@"  [resolve] доопределили %s", sel_getName(sel));
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

@end

int main(void) {
    @autoreleasepool {
        Ghost *g = [[Ghost alloc] init];

        NSLog(@"первый вызов shout:");
        NSLog(@"  %@", [g shout]);
        NSLog(@"второй вызов shout (resolve уже не нужен):");
        NSLog(@"  %@", [g shout]);

        NSLog(@"вызов twice:21 ->");
        NSLog(@"  %@", [g twice:@21]);

        NSLog(@"resolveInstanceMethod: позвался %d раз(а)", g_resolveCalls);
    }
    return 0;
}
