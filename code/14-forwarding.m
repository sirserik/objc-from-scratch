#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* Пересылка сообщений. Proxy не умеет ни одного из этих методов,
   но через -forwardingTargetForSelector: подменяет получателя:
   все непонятные сообщения уходят живому Worker. Снаружи кажется,
   будто Proxy сам всё умеет. */

@interface Worker : NSObject
- (NSString *)greet:(NSString *)name;
- (int)square:(int)x;
@end

@implementation Worker
- (NSString *)greet:(NSString *)name {
    return [NSString stringWithFormat:@"Worker приветствует %@", name];
}
- (int)square:(int)x { return x * x; }
@end

/* Proxy не наследует Worker и не реализует его методы. */
@interface Proxy : NSObject
- (instancetype)initWithTarget:(id)target;
@end

@implementation Proxy {
    id _target;     /* кому пересылаем */
}

- (instancetype)initWithTarget:(id)target {
    self = [super init];
    if (self) { _target = target; }
    return self;
}

/* Второй шанс пересылки: вернуть объект, который УМЕЕТ это сообщение.
   runtime повторит отправку уже ему — быстро и без копирования аргументов. */
- (id)forwardingTargetForSelector:(SEL)sel {
    NSLog(@"  [forward] %s -> %@", sel_getName(sel), [_target class]);
    if ([_target respondsToSelector:sel]) {
        return _target;
    }
    return [super forwardingTargetForSelector:sel];
}

@end

int main(void) {
    @autoreleasepool {
        Worker *worker = [[Worker alloc] init];

        /* Тип переменной — id, поэтому компилятор разрешает слать
           proxy любые объявленные селекторы. */
        id proxy = [[Proxy alloc] initWithTarget:worker];

        NSString *hi = [proxy greet:@"Серик"];
        NSLog(@"ответ: %@", hi);

        int sq = [proxy square:9];
        NSLog(@"9 в квадрате = %d", sq);

        /* respondsToSelector: у самого proxy скажет «нет» — он и правда
           не реализует greet:. Пересылка работает на более низком уровне. */
        NSLog(@"proxy сам умеет greet:? %@",
              [proxy respondsToSelector:@selector(greet:)] ? @"да" : @"нет");
    }
    return 0;
}
