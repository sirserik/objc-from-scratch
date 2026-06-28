#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* Класс — это тоже объект. Значит, у него тоже есть isa.
   isa класса указывает на МЕТАКЛАСС. В метаклассе хранятся
   методы класса (+). Здесь мы проходим по всей цепочке isa
   и убеждаемся в классической картине указателей. */

@interface Animal : NSObject
@end
@implementation Animal
@end

@interface Dog : Animal
@end
@implementation Dog
@end

static void describe(Class c) {
    NSString *kind = class_isMetaClass(c) ? @"метакласс" : @"класс    ";
    Class super = class_getSuperclass(c);
    NSLog(@"%@ %-18s  isa=%p  super=%s",
          kind,
          class_getName(c),
          (__bridge void *)object_getClass(c),
          super ? class_getName(super) : "(none)");
}

int main(void) {
    @autoreleasepool {
        Dog *rex = [[Dog alloc] init];

        /* isa объекта — это его КЛАСС. */
        Class dogClass = object_getClass(rex);          /* Dog        */

        /* isa КЛАССА — это его МЕТАКЛАСС. */
        Class dogMeta  = object_getClass(dogClass);     /* Dog (meta) */

        NSLog(@"--- классы ---");
        describe(dogClass);
        describe([Animal class]);
        describe([NSObject class]);

        NSLog(@"--- метаклассы ---");
        describe(dogMeta);
        describe(object_getClass([Animal class]));
        describe(object_getClass([NSObject class]));

        /* Корневой метакласс (NSObject meta) ссылается isa сам на себя. */
        Class rootMeta = object_getClass([NSObject class]);
        NSLog(@"--- замыкание ---");
        NSLog(@"isa корневого метакласса == он сам? %@",
              (object_getClass(rootMeta) == rootMeta) ? @"да" : @"нет");
        NSLog(@"superclass корневого метакласса = %s",
              class_getName(class_getSuperclass(rootMeta)));

        /* class_isMetaClass отличает класс от метакласса. */
        NSLog(@"Dog       — метакласс? %@",
              class_isMetaClass(dogClass) ? @"да" : @"нет");
        NSLog(@"Dog(meta) — метакласс? %@",
              class_isMetaClass(dogMeta)  ? @"да" : @"нет");
    }
    return 0;
}
