#import <Foundation/Foundation.h>

#define ITERATIONS 1000000

int main(void) {
    @autoreleasepool {
        dispatch_queue_t concurrent =
            dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);

        // --- Версия с гонкой: два потока бьются за одну переменную ---
        __block long bad = 0;
        dispatch_apply(2, concurrent, ^(size_t i) {
            (void)i;
            for (int k = 0; k < ITERATIONS; k++) {
                bad++;          // НЕ атомарно: чтение, +1, запись
            }
        });
        NSLog(@"гонка:   ожидали %d, получили %ld",
              ITERATIONS * 2, bad);

        // --- Починка через последовательную очередь ---
        __block long good = 0;
        dispatch_queue_t guard =
            dispatch_queue_create("counter.guard", DISPATCH_QUEUE_SERIAL);
        dispatch_apply(2, concurrent, ^(size_t i) {
            (void)i;
            for (int k = 0; k < ITERATIONS; k++) {
                dispatch_sync(guard, ^{ good++; });
            }
        });
        NSLog(@"очередь: ожидали %d, получили %ld",
              ITERATIONS * 2, good);

        // --- Починка через @synchronized ---
        __block long locked = 0;
        NSObject *lock = [NSObject new];
        dispatch_apply(2, concurrent, ^(size_t i) {
            (void)i;
            for (int k = 0; k < ITERATIONS; k++) {
                @synchronized (lock) { locked++; }
            }
        });
        NSLog(@"@synchronized: ожидали %d, получили %ld",
              ITERATIONS * 2, locked);
    }
    return 0;
}
