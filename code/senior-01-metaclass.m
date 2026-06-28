#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface Tool : NSObject
+ (void)build;          /* метод КЛАССА (+) */
- (void)use;            /* метод ЭКЗЕМПЛЯРА (-) */
@end

@implementation Tool
+ (void)build { NSLog(@"строю Tool"); }
- (void)use   { NSLog(@"использую Tool"); }
@end

/* Есть ли метод в таблице ИМЕННО этого класса (без наследования)? */
static BOOL hasMethodHere(Class c, SEL sel) {
    unsigned int n = 0;
    Method *list = class_copyMethodList(c, &n);
    BOOL found = NO;
    for (unsigned int i = 0; i < n; i++) {
        if (method_getName(list[i]) == sel) { found = YES; break; }
    }
    free(list);
    return found;
}

int main(void) {
    @autoreleasepool {
        Class cls  = [Tool class];               /* класс Tool          */
        Class meta = object_getClass(cls);       /* isa класса -> метакласс */

        NSLog(@"isa класса Tool указывает на: %s (метакласс? %@)",
              class_getName(meta),
              class_isMetaClass(meta) ? @"да" : @"нет");

        NSLog(@"-use   в классе Tool?     %@",
              hasMethodHere(cls,  @selector(use))   ? @"да" : @"нет");
        NSLog(@"-use   в метаклассе Tool? %@",
              hasMethodHere(meta, @selector(use))   ? @"да" : @"нет");
        NSLog(@"+build в классе Tool?     %@",
              hasMethodHere(cls,  @selector(build)) ? @"да" : @"нет");
        NSLog(@"+build в метаклассе Tool? %@",
              hasMethodHere(meta, @selector(build)) ? @"да" : @"нет");

        Tool *t = [[Tool alloc] init];
        NSLog(@"цепочка isa:");
        NSLog(@"  объект t        isa -> %s", class_getName(object_getClass(t)));
        NSLog(@"  класс Tool      isa -> %s", class_getName(object_getClass(cls)));
        NSLog(@"  метакласс Tool  isa -> %s", class_getName(object_getClass(meta)));
    }
    return 0;
}
