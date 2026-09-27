#import <Foundation/Foundation.h>

/* Задача: что делает @autoreleasepool и зачем он в длинном цикле.
   Объект своего ARC-класса ARC часто передаёт из рук в руки мимо пула —
   увидеть на нём «живёт до слива» не выйдет. Чтобы честно показать сам
   пул, кладём объект в пул явно (CFAutorelease): тогда в живых его
   держит ТОЛЬКО пул, и он умирает ровно на сливе пула. */

@interface Temp : NSObject
@property (nonatomic) int n;
@end

@implementation Temp
- (void)dealloc { NSLog(@"  dealloc Temp(%d)", self.n); }
@end

/* Кладём НОВЫЙ Temp в текущий пул, не оставляя на него сильной ссылки.
   CFBridgingRetain отдаёт объект из-под ARC (+1, «ручное» владение),
   CFAutorelease назначает ему release на сливе пула. */
static void leaveInPool(int n) {
    Temp *t = [[Temp alloc] init];
    t.n = n;
    CFAutorelease(CFBridgingRetain(t));
}

int main(void) {
    @autoreleasepool {
        NSLog(@"=== объект живёт ровно до слива пула ===");
        @autoreleasepool {
            leaveInPool(1);
            NSLog(@"внутри пула: Temp(1) ещё жив (dealloc не было)");
        }   /* пул сливается здесь — Temp(1) получает release и умирает */
        NSLog(@"после слива: Temp(1) уже мёртв (dealloc был выше)");

        NSLog(@"=== тяжёлый цикл: пул на каждой итерации ===");
        for (int i = 0; i < 3; i++) {
            @autoreleasepool {
                leaveInPool(100 + i);
                NSLog(@"итерация %d: объект создан", i);
            }   /* временные ЭТОЙ итерации освобождаются сразу */
        }
        NSLog(@"цикл закончен — пул не дал памяти расти");
    }
    return 0;
}
