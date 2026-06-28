#import <Foundation/Foundation.h>

@interface Settings : NSObject
@property (nonatomic, copy) NSString *theme;
+ (instancetype)shared;
@end

@implementation Settings

+ (instancetype)shared {
    static Settings *instance = nil;
    static dispatch_once_t onceToken;
    // Блок выполнится РОВНО ОДИН раз за всё время работы программы,
    // даже если shared зовут из десятка потоков одновременно.
    dispatch_once(&onceToken, ^{
        instance = [[Settings alloc] init];
        instance.theme = @"тёмная";
        NSLog(@"   >>> Settings создан (это видно один раз)");
    });
    return instance;
}

@end

int main(void) {
    @autoreleasepool {
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t bg =
            dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);

        // Зовём shared из 8 параллельных задач сразу.
        for (int i = 0; i < 8; i++) {
            dispatch_group_async(group, bg, ^{
                Settings *s = [Settings shared];
                (void)s;   // нам важен лишь факт обращения
            });
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

        Settings *a = [Settings shared];
        Settings *b = [Settings shared];
        NSLog(@"a == b ? %@", (a == b) ? @"да, один объект" : @"нет");
        NSLog(@"тема: %@", a.theme);
    }
    return 0;
}
