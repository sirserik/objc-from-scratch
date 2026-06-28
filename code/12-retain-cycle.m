#import <Foundation/Foundation.h>

/* Объект хранит блок в своём свойстве. Если этот блок захватит self
   сильно — объект держит блок, блок держит объект: цикл удержания. */
@interface Worker : NSObject
@property (nonatomic, copy) void (^job)(void);
@property (nonatomic, copy) NSString *name;
- (void)setupBad;
- (void)setupGood;
@end

@implementation Worker

/* ПЛОХО: блок захватывает self напрямую (через self.name).
   self держит job, job держит self → оба не освобождаются.
   clang СПЕЦИАЛЬНО предупреждает об этом (-Warc-retain-cycles);
   здесь мы глушим предупреждение, чтобы показать сам эффект. */
- (void)setupBad {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    self.job = ^{
        NSLog(@"работаю как %@", self.name);
    };
#pragma clang diagnostic pop
}

/* ХОРОШО: слабая ссылка на self разрывает цикл.
   Детали __weak и ARC — в главе 13. */
- (void)setupGood {
    __weak typeof(self) weakSelf = self;
    self.job = ^{
        NSLog(@"работаю как %@", weakSelf.name);
    };
}

- (void)dealloc {
    NSLog(@"dealloc: Worker %@ уничтожен", self.name);
}

@end

int main(void) {
    @autoreleasepool {
        NSLog(@"--- цикл удержания (setupBad) ---");
        @autoreleasepool {
            Worker *w = [[Worker alloc] init];
            w.name = @"bad";
            [w setupBad];
        }   /* w выходит из области, но dealloc НЕ сработает: цикл */
        NSLog(@"(dealloc для bad так и не вызвался)");

        NSLog(@"--- починка (setupGood) ---");
        @autoreleasepool {
            Worker *w = [[Worker alloc] init];
            w.name = @"good";
            [w setupGood];
        }   /* здесь dealloc сработает — цикла нет */
        NSLog(@"(объект good освобождён выше)");
    }
    return 0;
}
