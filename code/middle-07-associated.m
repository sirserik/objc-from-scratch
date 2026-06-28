#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* Задача: категория не может добавить ivar. Нужно «прицепить» данные к
   чужому объекту — используем associated objects (objc_setAssociatedObject /
   objc_getAssociatedObject). */

static const char kTagKey;     /* адрес переменной = уникальный ключ */

@interface NSString (Tag)
@property (nonatomic, copy) NSString *tag;   /* нет места под ivar! */
@end

@implementation NSString (Tag)
- (void)setTag:(NSString *)tag {
    objc_setAssociatedObject(self, &kTagKey, tag,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)tag {
    return objc_getAssociatedObject(self, &kTagKey);
}
@end

int main(void) {
    @autoreleasepool {
        NSString *s = [NSString stringWithFormat:@"%@", @"заказ"];
        NSLog(@"до: tag = %@", s.tag);    /* (null) */
        s.tag = @"важный";
        NSLog(@"после: tag = %@", s.tag); /* важный */
    }
    return 0;
}
