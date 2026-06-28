#import <Foundation/Foundation.h>

#define N 100000

@interface Counter : NSObject
@property (atomic) NSInteger value;     /* atomic-свойство! */
@end

@implementation Counter
@end

int main(void) {
    @autoreleasepool {
        dispatch_queue_t bg =
            dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);

        /* atomic делает каждый ОТДЕЛЬНЫЙ get и set неделимым. Но
           value = value + 1 — это get, потом set: между ними другой
           поток успевает вклиниться. Инкременты теряются. */
        Counter *bad = [Counter new];
        dispatch_apply(2, bg, ^(size_t i) {
            (void)i;
            for (int k = 0; k < N; k++) {
                bad.value = bad.value + 1;
            }
        });
        NSLog(@"atomic-свойство: ожидали %d, получили %ld  (часть потеряна)",
              2 * N, (long)bad.value);

        /* Починка: всю операцию read-modify-write проводим на одной
           последовательной очереди — два потока физически не пересекутся. */
        __block NSInteger good = 0;
        dispatch_queue_t guard =
            dispatch_queue_create("counter.guard", DISPATCH_QUEUE_SERIAL);
        dispatch_apply(2, bg, ^(size_t i) {
            (void)i;
            for (int k = 0; k < N; k++) {
                dispatch_sync(guard, ^{ good++; });
            }
        });
        NSLog(@"serial-очередь:  ожидали %d, получили %ld",
              2 * N, (long)good);
    }
    return 0;
}
