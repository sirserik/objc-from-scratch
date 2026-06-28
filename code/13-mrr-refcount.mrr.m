#import <Foundation/Foundation.h>

/* ВНИМАНИЕ: это код БЕЗ ARC.
   Собирается флагом -fno-objc-arc.
   Здесь мы САМИ зовём retain/release и САМИ пишем [super dealloc].
   Под ARC так писать нельзя — компилятор запретит. */

@interface Person : NSObject {
    NSString *_name;
}
- (instancetype)initWithName:(NSString *)name;
@end

@implementation Person

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];   /* copy даёт нам ВЛАДЕНИЕ строкой */
    }
    return self;
}

- (void)dealloc {
    NSLog(@"dealloc: %@ уничтожен", _name);
    [_name release];           /* отпускаем то, чем владели */
    [super dealloc];           /* под MRR обязательно и последней строкой */
}

@end

int main(void) {
    @autoreleasepool {
        /* alloc даёт владение: счётчик ссылок = 1. */
        Person *p = [[Person alloc] initWithName:@"Аружан"];
        NSLog(@"после alloc/init: retainCount = %lu",
              (unsigned long)[p retainCount]);

        /* retain: ещё +1. Счётчик = 2. */
        [p retain];
        NSLog(@"после retain:     retainCount = %lu",
              (unsigned long)[p retainCount]);

        /* release: -1. Счётчик = 1. Объект ещё жив. */
        [p release];
        NSLog(@"после release:    retainCount = %lu",
              (unsigned long)[p retainCount]);

        /* Последний release: -1. Счётчик = 0 → система шлёт dealloc. */
        NSLog(@"шлём последний release...");
        [p release];
        NSLog(@"объект больше не существует");
    }
    return 0;
}
