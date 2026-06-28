#import <Foundation/Foundation.h>

/* Демонстрация ЦИКЛА УДЕРЖАНИЯ (retain cycle).
   Родитель сильно держит ребёнка, ребёнок сильно держит родителя.
   Оба не умрут — утечка. dealloc НЕ сработает ни разу. */

@class Child;

@interface Parent : NSObject
@property (nonatomic, copy)   NSString *name;
@property (nonatomic, strong) Child *child;    /* сильная: владеет ребёнком */
@end

@interface Child : NSObject
@property (nonatomic, copy)   NSString *name;
@property (nonatomic, strong) Parent *parent;  /* сильная ← вот она, проблема */
@end

@implementation Parent
- (void)dealloc { NSLog(@"dealloc Parent (%@)", self.name); }
@end

@implementation Child
- (void)dealloc { NSLog(@"dealloc Child (%@)", self.name); }
@end

int main(void) {
    @autoreleasepool {
        Parent *mom = [Parent new];
        mom.name = @"Мама";
        Child *kid = [Child new];
        kid.name = @"Дочь";

        mom.child  = kid;    /* мама держит дочь  (+1 к счётчику kid) */
        kid.parent = mom;    /* дочь держит маму  (+1 к счётчику mom) — цикл */

        NSLog(@"выходим из блока — ждём два dealloc...");
    }   /* mom и kid выходят из видимости, но держат друг друга → счётчики != 0 */

    NSLog(@"блок закрыт. Видел dealloc выше? Нет. Это утечка памяти.");
    return 0;
}
