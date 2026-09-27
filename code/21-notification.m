#import <Foundation/Foundation.h>

// Имя уведомления вынесем в константу, чтобы не опечататься.
static NSString *const TickNotification = @"TickNotification";

// Подписчик: получает уведомления и реагирует.
@interface Display : NSObject
@property (nonatomic) NSInteger seen;
@end

@implementation Display

- (instancetype)init {
    self = [super init];
    if (self) {
        // Подписываемся: при уведомлении TickNotification зови onTick:.
        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(onTick:)
                   name:TickNotification
                 object:nil];
    }
    return self;
}

- (void)onTick:(NSNotification *)note {
    self.seen += 1;
    NSNumber *count = note.userInfo[@"count"];
    NSLog(@"   Display получил тик #%@ (всего видел %ld)",
          count, (long)self.seen);
}

- (void)dealloc {
    // С macOS 10.11/iOS 9 центр сам забывает умерших подписчиков,
    // но явная отписка — хорошая привычка (см. разбор ниже).
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"   Display освобождён, отписался");
}

@end

// Источник тиков: таймер бьёт каждые 0.2 c и шлёт уведомление.
@interface Clock : NSObject
@property (nonatomic) NSInteger tick;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation Clock

- (void)start {
    self.timer =
        [NSTimer scheduledTimerWithTimeInterval:0.2
                                         target:self
                                       selector:@selector(fire:)
                                       userInfo:nil
                                        repeats:YES];
}

- (void)fire:(NSTimer *)timer {
    self.tick += 1;
    NSLog(@"Clock: тик %ld, рассылаю уведомление", (long)self.tick);
    [[NSNotificationCenter defaultCenter]
        postNotificationName:TickNotification
                      object:self
                    userInfo:@{ @"count": @(self.tick) }];
    if (self.tick >= 3) {
        [timer invalidate];   // снимаем таймер с run loop
    }
}

@end

int main(void) {
    @autoreleasepool {
        Display *display = [[Display alloc] init];
        Clock *clock = [[Clock alloc] init];
        [clock start];

        NSLog(@"крутим run loop 1 секунду...");
        // Без работающего run loop таймер НЕ сработает ни разу.
        [[NSRunLoop currentRunLoop]
            runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];

        NSLog(@"готово: Display видел тиков: %ld", (long)display.seen);
    }
    return 0;
}
