#import <Foundation/Foundation.h>
#import <objc/runtime.h>   // objc_setAssociatedObject и компания

// Категория не может добавить хранимое свойство (ivar). Но с помощью
// runtime можно «привязать» к объекту дополнительный объект-значение.
// Механику runtime подробно разбираем в главе 14 — здесь только рецепт.

@interface NSString (Tag)
@property (nonatomic, copy) NSString *tag;   // мнимое «хранилище»
@end

@implementation NSString (Tag)

// Уникальный ключ. Адрес самой статической переменной никогда не
// повторится — этого достаточно, чтобы пометить наше значение.
static const void *kTagKey = &kTagKey;

- (void)setTag:(NSString *)tag {
    objc_setAssociatedObject(self, kTagKey, tag,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)tag {
    return objc_getAssociatedObject(self, kTagKey);
}

@end

int main(void) {
    @autoreleasepool {
        NSMutableString *note = [NSMutableString stringWithString:@"молоко"];
        NSLog(@"до:    note = \"%@\", tag = %@", note, note.tag);

        note.tag = @"покупки";   // вызывает наш setTag:
        NSLog(@"после: note = \"%@\", tag = %@", note, note.tag);
    }
    return 0;
}
