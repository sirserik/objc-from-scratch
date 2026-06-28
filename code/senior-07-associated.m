#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* Представь, что View — чужой класс из фреймворка: исходник недоступен,
   ivar в него не добавить. Категория тоже не умеет хранить поля. Но
   runtime умеет «привязать» значение к объекту — associated object. */
@interface View : NSObject
@property (nonatomic, copy) NSString *title;
@end

@implementation View
@end

@interface View (Badge)
@property (nonatomic, strong) NSNumber *badgeCount;   /* мнимое хранилище */
@end

@implementation View (Badge)

/* Ключ — адрес статической переменной: уникален во всей программе. */
static const void *kBadgeKey = &kBadgeKey;

- (void)setBadgeCount:(NSNumber *)badgeCount {
    objc_setAssociatedObject(self, kBadgeKey, badgeCount,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)badgeCount {
    return objc_getAssociatedObject(self, kBadgeKey);
}

@end

int main(void) {
    @autoreleasepool {
        View *a = [View new]; a.title = @"Почта";
        View *b = [View new]; b.title = @"Чаты";

        NSLog(@"до:  %@ badge=%@, %@ badge=%@",
              a.title, a.badgeCount, b.title, b.badgeCount);

        a.badgeCount = @7;            /* зовёт наш setBadgeCount: */
        b.badgeCount = @0;

        NSLog(@"после: %@ badge=%@, %@ badge=%@",
              a.title, a.badgeCount, b.title, b.badgeCount);
        NSLog(@"у каждого объекта своё значение? %@",
              ![a.badgeCount isEqual:b.badgeCount] ? @"да" : @"нет");
    }
    return 0;
}
