#import <Foundation/Foundation.h>
#import <objc/runtime.h>      /* object_getClass — заглянем под isa */

/* Контекст: уникальный адрес, по которому отличим именно нашу подписку
   от чужих (например, подписок суперкласса). Само значение неважно —
   важен его адрес. */
static char kBalanceContext;

/* --- наблюдаемый объект --- */
@interface Account : NSObject
@property (nonatomic) double balance;
/* Намеренно «нечестный» метод: пишет прямо в ivar, в обход сеттера. */
- (void)setBalanceSneaky:(double)value;
@end

@implementation Account
- (void)setBalanceSneaky:(double)value {
    _balance = value;          /* прямое присваивание полю — KVO это НЕ видит */
}
@end

/* --- наблюдатель --- */
@interface Watcher : NSObject
@end

@implementation Watcher
/* Этот метод runtime зовёт при каждом замеченном изменении. */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
    if (context == &kBalanceContext) {
        NSLog(@"  [наблюдатель] %@: %@ -> %@",
              keyPath,
              change[NSKeyValueChangeOldKey],
              change[NSKeyValueChangeNewKey]);
    } else {
        /* чужая подписка — отдаём суперклассу */
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}
@end

int main(void) {
    @autoreleasepool {
        Account *acc = [[Account alloc] init];
        Watcher *w   = [[Watcher alloc] init];

        NSLog(@"до подписки:  -class=%@  настоящий isa=%s",
              [acc class], class_getName(object_getClass(acc)));

        /* Подписываемся на ключ "balance". options говорит, что класть
           в словарь change: старое и новое значение. */
        [acc addObserver:w
              forKeyPath:@"balance"
                 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                 context:&kBalanceContext];

        NSLog(@"после подписки: -class=%@  настоящий isa=%s",
              [acc class], class_getName(object_getClass(acc)));

        NSLog(@"--- меняем через сеттер ---");
        acc.balance = 100.0;                         /* уведомление придёт */
        [acc setValue:@250.0 forKey:@"balance"];     /* и здесь тоже придёт */

        NSLog(@"--- меняем напрямую через ivar ---");
        [acc setBalanceSneaky:999.0];                /* тишина: KVO не заметит */

        NSLog(@"итоговый баланс = %.2f", acc.balance);

        /* ОБЯЗАТЕЛЬНО снять наблюдателя, пока оба объекта живы. */
        [acc removeObserver:w forKeyPath:@"balance" context:&kBalanceContext];
    }
    return 0;
}
