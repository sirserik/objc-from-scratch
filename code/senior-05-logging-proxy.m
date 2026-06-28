#import <Foundation/Foundation.h>

@interface Service : NSObject
- (NSInteger)compute:(NSInteger)x;
- (NSString *)name;
@end

@implementation Service
- (NSInteger)compute:(NSInteger)x { return x * x; }
- (NSString *)name { return @"Service"; }
@end

/* Логирующий прокси: считает и печатает каждую пересылку.
   forwardingTargetForSelector: — самый дешёвый шанс: сообщение просто
   повторяется другому получателю, без построения NSInvocation. */
@interface LoggingProxy : NSObject
- (instancetype)initWithTarget:(id)target;
@property (nonatomic, readonly) NSInteger forwardedCount;
@end

@implementation LoggingProxy {
    id _target;
}

- (instancetype)initWithTarget:(id)target {
    self = [super init];
    if (self) { _target = target; }
    return self;
}

- (id)forwardingTargetForSelector:(SEL)sel {
    if ([_target respondsToSelector:sel]) {
        _forwardedCount++;
        NSLog(@"  [proxy] переслано: %s (всего %ld)",
              sel_getName(sel), (long)_forwardedCount);
        return _target;
    }
    return [super forwardingTargetForSelector:sel];
}

@end

int main(void) {
    @autoreleasepool {
        Service *real = [Service new];
        id proxy = [[LoggingProxy alloc] initWithTarget:real];

        NSLog(@"name    = %@", [proxy name]);
        NSLog(@"compute = %ld", (long)[proxy compute:9]);
        NSLog(@"compute = %ld", (long)[proxy compute:4]);

        NSLog(@"итого переслано сообщений: %ld",
              (long)[(LoggingProxy *)proxy forwardedCount]);
    }
    return 0;
}
