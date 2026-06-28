#import <Foundation/Foundation.h>

/* «Тяжёлый» объект: дорого создавать. Хотим отложить создание до первого
   реального обращения. */
@interface Heavy : NSObject
- (NSString *)report;
@end

@implementation Heavy
- (instancetype)init {
    self = [super init];
    if (self) NSLog(@"  Heavy: дорогой объект СОЗДАН");
    return self;
}
- (NSString *)report { return @"тяжёлый отчёт готов"; }
@end

/* Ленивый прокси. Наследуем NSProxy — отдельный тонкий корень, у него
   нет лишнего поведения NSObject, только пересылка. Создаём Heavy лишь
   когда придёт первое сообщение. */
@interface LazyProxy : NSProxy
@end

@implementation LazyProxy {
    Heavy *_real;
}

- (Heavy *)real {
    if (!_real) {
        _real = [[Heavy alloc] init];   /* создаём при первом обращении */
    }
    return _real;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [Heavy instanceMethodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)inv {
    [inv invokeWithTarget:[self real]];
}

@end

int main(void) {
    @autoreleasepool {
        NSLog(@"создаём прокси (Heavy ещё НЕ создан):");
        Heavy *obj = (Heavy *)[LazyProxy alloc];   /* NSProxy: только alloc */
        NSLog(@"прокси готов, Heavy всё ещё не создан");

        NSLog(@"первое реальное обращение -> report:");
        NSLog(@"  ответ: %@", [obj report]);
    }
    return 0;
}
