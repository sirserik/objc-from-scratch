#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static char kCtx;   /* адрес служит уникальным контекстом подписки */

@interface Account : NSObject
@property (nonatomic) double balance;
@end

@implementation Account
@end

@interface Watcher : NSObject
@end

@implementation Watcher
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
    if (context == &kCtx) {
        NSLog(@"  [наблюдатель] %@: %@ -> %@", keyPath,
              change[NSKeyValueChangeOldKey],
              change[NSKeyValueChangeNewKey]);
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}
@end

int main(void) {
    @autoreleasepool {
        Account *acc = [[Account alloc] init];
        Watcher *w   = [[Watcher alloc] init];

        NSLog(@"до подписки:   -class=%@  настоящий isa=%s",
              [acc class], class_getName(object_getClass(acc)));

        [acc addObserver:w forKeyPath:@"balance"
                 options:NSKeyValueObservingOptionOld |
                         NSKeyValueObservingOptionNew
                 context:&kCtx];

        NSLog(@"после подписки: -class=%@  настоящий isa=%s",
              [acc class], class_getName(object_getClass(acc)));

        NSLog(@"меняем баланс через сеттер:");
        acc.balance = 100.0;
        acc.balance = 250.0;

        [acc removeObserver:w forKeyPath:@"balance" context:&kCtx];

        NSLog(@"после отписки:  настоящий isa=%s",
              class_getName(object_getClass(acc)));
    }
    return 0;
}
