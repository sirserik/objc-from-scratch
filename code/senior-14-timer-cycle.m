#import <Foundation/Foundation.h>

@interface Ticker : NSObject
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, copy) NSString *name;
- (void)startBad;
- (void)startGood;
@end

@implementation Ticker

/* ПЛОХО: scheduledTimer... СИЛЬНО удерживает target (=self).
   Цепочка: run loop -> timer -> self -> timer. self не умрёт никогда,
   даже когда все «внешние» ссылки на него исчезли. */
- (void)startBad {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                  target:self
                                                selector:@selector(tick:)
                                                userInfo:nil
                                                 repeats:YES];
}

/* ХОРОШО: блочный таймер + __weak. Таймер держит блок, блок ссылается на
   self СЛАБО. Когда self уходит — weakSelf становится nil, и блок сам
   гасит осиротевший таймер. Цикла нет. */
- (void)startGood {
    __weak typeof(self) weakSelf = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                 repeats:YES
                                                   block:^(NSTimer *t) {
        Ticker *strong = weakSelf;
        if (!strong) { [t invalidate]; return; }
        [strong tick:t];
    }];
}

- (void)tick:(NSTimer *)t { (void)t; }   /* тикаем тихо */

- (void)dealloc {
    NSLog(@"  dealloc: Ticker «%@» освобождён", self.name);
}

@end

static void runLoop(NSTimeInterval seconds) {
    [[NSRunLoop currentRunLoop]
        runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
}

int main(void) {
    @autoreleasepool {
        NSLog(@"--- ПЛОХО: target/selector-таймер ---");
        @autoreleasepool {
            Ticker *bad = [[Ticker alloc] init];
            bad.name = @"bad";
            [bad startBad];
            runLoop(0.2);
        }   /* bad вышел из области, но НЕ освобождён: цикл с таймером */
        NSLog(@"  (dealloc для «bad» НЕ вызван — утечка через таймер)");

        NSLog(@"--- ХОРОШО: блочный таймер + weak ---");
        @autoreleasepool {
            Ticker *good = [[Ticker alloc] init];
            good.name = @"good";
            [good startGood];
            runLoop(0.2);
        }   /* good освобождается здесь — цикла нет */
        runLoop(0.2);   /* осиротевший таймер срабатывает и сам гасится */
        NSLog(@"  (dealloc для «good» вызван выше — цикл разорван)");
    }
    return 0;
}
