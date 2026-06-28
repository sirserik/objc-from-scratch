#import <Foundation/Foundation.h>

@interface Database : NSObject
@property (nonatomic, copy) NSString *path;
+ (instancetype)shared;
@end

@implementation Database

+ (instancetype)shared {
    static Database *instance = nil;
    static dispatch_once_t onceToken;       /* обязан быть static */
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];     /* [self alloc] — работает и для наследников */
        instance.path = @"/var/db/main";
        NSLog(@"   >>> Database создан (видно один раз)");
    });
    return instance;
}

@end

int main(void) {
    @autoreleasepool {
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t bg =
            dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);

        /* 16 потоков одновременно лезут за синглтоном. */
        for (int i = 0; i < 16; i++) {
            dispatch_group_async(group, bg, ^{
                Database *d = [Database shared];
                (void)d;
            });
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

        Database *a = [Database shared];
        Database *b = [Database shared];
        NSLog(@"a == b ? %@", (a == b) ? @"да, один объект" : @"нет, ПЛОХО");
        NSLog(@"path: %@", a.path);
    }
    return 0;
}
