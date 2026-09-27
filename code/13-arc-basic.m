#import <Foundation/Foundation.h>

/* Тот же человек, но под ARC.
   Ни retain, ни release, ни [super dealloc]: компилятор всё расставит сам. */

@interface Person : NSObject
@property (nonatomic, copy) NSString *name;
- (instancetype)initWithName:(NSString *)name;
@end

@implementation Person

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"dealloc: %@ уничтожен", _name);
}

@end

int main(void) {
    @autoreleasepool {
        /* Сильная ссылка p: ARC удерживает объект, счётчик = 1. */
        Person *p = [[Person alloc] initWithName:@"Аружан"];
        NSLog(@"объект жив: %@", p.name);

        /* Вторая сильная ссылка на тот же объект: счётчик = 2. */
        Person *q = p;
        NSLog(@"q указывает на того же человека: %@", q.name);

        /* Обнуляем p: счётчик = 1. Объект ещё держит q — dealloc НЕ будет. */
        p = nil;
        NSLog(@"p = nil, но q ещё держит объект — dealloc не было");

        /* Обнуляем q: счётчик = 0 → ARC шлёт dealloc прямо здесь. */
        q = nil;
        NSLog(@"q = nil — объект уже уничтожен (dealloc выше)");
    }
    return 0;
}
