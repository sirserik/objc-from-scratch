#import <Foundation/Foundation.h>

@protocol Listener <NSObject>
- (void)event:(NSString *)name;
@end

@interface Speaker : NSObject <Listener>
@property (nonatomic, copy) NSString *label;
@end

@implementation Speaker
- (void)event:(NSString *)name {
    NSLog(@"  %@ услышал событие: %@", self.label, name);
}
@end

/* Прокси, который рассылает ЛЮБОЕ сообщение всем адресатам сразу.
   Это умеет только третий шанс пересылки — forwardInvocation:,
   потому что forwardingTargetForSelector: вернул бы лишь ОДНОГО. */
@interface Broadcaster : NSObject
- (instancetype)initWithTargets:(NSArray *)targets;
@end

@implementation Broadcaster {
    NSArray *_targets;
}

- (instancetype)initWithTargets:(NSArray *)targets {
    self = [super init];
    if (self) { _targets = [targets copy]; }
    return self;
}

/* runtime спрашивает сигнатуру, чтобы построить NSInvocation. Берём её
   у первого адресата, который знает этот селектор. */
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    NSMethodSignature *sig = [super methodSignatureForSelector:sel];
    if (sig) return sig;
    for (id t in _targets) {
        sig = [t methodSignatureForSelector:sel];
        if (sig) return sig;
    }
    return nil;
}

- (void)forwardInvocation:(NSInvocation *)inv {
    BOOL handled = NO;
    for (id t in _targets) {
        if ([t respondsToSelector:inv.selector]) {
            [inv invokeWithTarget:t];   /* выполнить на каждом адресате */
            handled = YES;
        }
    }
    if (!handled) {
        [super forwardInvocation:inv];  /* никто не знает -> штатное падение */
    }
}

@end

int main(void) {
    @autoreleasepool {
        Speaker *a = [Speaker new]; a.label = @"Анна";
        Speaker *b = [Speaker new]; b.label = @"Борис";
        Speaker *c = [Speaker new]; c.label = @"Вера";

        /* Тип id<Listener>: компилятор разрешает слать event:,
           хотя сам Broadcaster его не реализует. */
        id<Listener> group =
            (id)[[Broadcaster alloc] initWithTargets:@[a, b, c]];

        NSLog(@"шлём ОДНО сообщение прокси:");
        [group event:@"пожарная тревога"];
    }
    return 0;
}
