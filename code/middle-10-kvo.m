#import <Foundation/Foundation.h>

/* Задача: KVO — подписка, что приходит в observeValueForKeyPath:,
   почему прямое изменение ivar не уведомляет, и обязательный
   removeObserver. */

@interface Account : NSObject {
@public
    NSInteger _rawBalance;   /* публичный ivar для прямого доступа */
}
@property (nonatomic) NSInteger balance;
@end
@implementation Account
@end

@interface Watcher : NSObject
@end
@implementation Watcher
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    NSLog(@"изменилось '%@': %@ -> %@", keyPath,
          change[NSKeyValueChangeOldKey],
          change[NSKeyValueChangeNewKey]);
}
@end

int main(void) {
    @autoreleasepool {
        Account *acc = [[Account alloc] init];
        Watcher *w = [[Watcher alloc] init];

        [acc addObserver:w
              forKeyPath:@"balance"
                 options:(NSKeyValueObservingOptionOld |
                          NSKeyValueObservingOptionNew)
                 context:NULL];

        NSLog(@"--- через сеттер (KVC-совместимо) ---");
        acc.balance = 100;       /* уведомление придёт */
        acc.balance = 250;       /* и ещё одно */

        NSLog(@"--- прямое изменение ivar (в обход сеттера) ---");
        acc->_rawBalance = 999;  /* НЕ уведомляет: KVO не видит */
        NSLog(@"_rawBalance стал 999, но observe не вызвался");

        /* снять наблюдателя ОБЯЗАТЕЛЬНО до смерти объектов */
        [acc removeObserver:w forKeyPath:@"balance"];
        NSLog(@"наблюдатель снят");
    }
    return 0;
}
