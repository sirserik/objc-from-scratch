#import <Foundation/Foundation.h>

/* Задача: что выведет weak-ссылка после смерти объекта, и чем опасен
   unsafe_unretained. weak сам становится nil; unsafe_unretained
   остаётся висячим указателем (тут мы его НЕ разыменовываем после
   смерти — иначе крах; показываем только безопасную половину). */

@interface Ticket : NSObject
@property (nonatomic, copy) NSString *code;
@end

@implementation Ticket
- (void)dealloc { NSLog(@"dealloc Ticket (%@)", self.code); }
@end

int main(void) {
    @autoreleasepool {
        __weak Ticket *weakRef = nil;
        @autoreleasepool {
            Ticket *t = [[Ticket alloc] init];
            t.code = @"A-17";
            weakRef = t;        /* слабо смотрим на живой объект */
            NSLog(@"объект жив:  weakRef.code = %@", weakRef.code);
        }   /* t умирает здесь */
        /* weak сам обнулился в nil — НЕ висячий указатель */
        NSLog(@"объект мёртв: weakRef = %@", weakRef);        /* (null) */
        NSLog(@"сообщение к nil безопасно: длина = %lu",
              (unsigned long)weakRef.code.length);            /* 0 */
    }
    return 0;
}
