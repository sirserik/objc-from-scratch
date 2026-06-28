#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* id — переменная под любой объект. Кладём строку. */
        id obj = @"я строка";

        /* isKindOfClass: — объект этого класса (или потомка)? */
        if ([obj isKindOfClass:[NSString class]]) {
            NSLog(@"obj — это NSString");
        }

        if ([obj isKindOfClass:[NSArray class]]) {
            NSLog(@"obj — это NSArray");
        } else {
            NSLog(@"obj — НЕ NSArray");
        }

        /* respondsToSelector: — объект ответит на это сообщение? */
        /* @selector(...) превращает имя метода в значение-селектор. */
        if ([obj respondsToSelector:@selector(uppercaseString)]) {
            NSLog(@"строка умеет uppercaseString → %@", [obj uppercaseString]);
        }

        if ([obj respondsToSelector:@selector(addObject:)]) {
            NSLog(@"строка умеет addObject:");
        } else {
            NSLog(@"строка НЕ умеет addObject:");
        }
    }
    return 0;
}
