#import <Foundation/Foundation.h>

/* Потокобезопасный кэш по схеме «много читателей — один писатель».
   Чтения идут параллельно (dispatch_sync на concurrent-очереди),
   запись — эксклюзивно через барьер (dispatch_barrier_async): GCD
   дождётся всех текущих чтений, выполнит запись в одиночку и продолжит. */
@interface SafeCache : NSObject
- (id)objectForKey:(NSString *)key;
- (void)setObject:(id)obj forKey:(NSString *)key;
- (NSUInteger)count;
@end

@implementation SafeCache {
    NSMutableDictionary *_store;
    dispatch_queue_t _queue;            /* СВОЯ concurrent-очередь */
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _store = [NSMutableDictionary dictionary];
        _queue = dispatch_queue_create("cache.queue",
                                       DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (id)objectForKey:(NSString *)key {
    __block id obj = nil;
    dispatch_sync(_queue, ^{ obj = _store[key]; });     /* читатель */
    return obj;
}

- (void)setObject:(id)obj forKey:(NSString *)key {
    dispatch_barrier_async(_queue, ^{ _store[key] = obj; });  /* писатель */
}

- (NSUInteger)count {
    __block NSUInteger c = 0;
    dispatch_sync(_queue, ^{ c = _store.count; });
    return c;
}

@end

int main(void) {
    @autoreleasepool {
        SafeCache *cache = [SafeCache new];
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t bg =
            dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);

        /* 100 параллельных писателей. setObject: только ставит барьер в
           очередь и сразу возвращается — потоки не блокируются. */
        for (int i = 0; i < 100; i++) {
            dispatch_group_async(group, bg, ^{
                NSString *key = [NSString stringWithFormat:@"k%d", i];
                [cache setObject:@(i * i) forKey:key];
            });
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

        /* Теперь 50 параллельных читателей — они идут одновременно,
           барьер их не сдерживает (барьер только для записи). */
        dispatch_group_t reads = dispatch_group_create();
        for (int i = 0; i < 50; i++) {
            dispatch_group_async(reads, bg, ^{
                (void)[cache objectForKey:@"k7"];
            });
        }
        dispatch_group_wait(reads, DISPATCH_TIME_FOREVER);

        /* count читает через dispatch_sync на той же очереди: все барьеры,
           поставленные раньше, к этому моменту отработают -> ровно 100. */
        NSLog(@"в кэше %lu элементов (ожидали 100)",
              (unsigned long)cache.count);
        NSLog(@"k7  = %@ (ожидали 49)",  [cache objectForKey:@"k7"]);
        NSLog(@"k12 = %@ (ожидали 144)", [cache objectForKey:@"k12"]);
    }
    return 0;
}
