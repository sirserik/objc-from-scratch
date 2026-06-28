#import <Foundation/Foundation.h>

@class Task;

@protocol TaskDelegate <NSObject>
@required
- (void)taskDidFinish:(Task *)task;        /* обязан реализовать каждый */
@optional
- (void)taskDidStart:(Task *)task;         /* по желанию */
- (void)task:(Task *)task didProgress:(int)percent;   /* по желанию */
@end

@interface Task : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, weak) id<TaskDelegate> delegate;
- (instancetype)initWithName:(NSString *)name;
- (void)run;
@end

@implementation Task
- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];
    }
    return self;
}
- (void)run {
    /* Опциональный метод — сначала спрашиваем, умеет ли делегат. */
    if ([self.delegate respondsToSelector:@selector(taskDidStart:)]) {
        [self.delegate taskDidStart:self];
    }
    for (int p = 50; p <= 100; p += 50) {
        if ([self.delegate respondsToSelector:@selector(task:didProgress:)]) {
            [self.delegate task:self didProgress:p];
        }
    }
    /* Обязательный метод — зовём напрямую, он гарантированно есть. */
    [self.delegate taskDidFinish:self];
}
@end

/* Минимальный делегат: только обязательный метод. */
@interface QuietWatcher : NSObject <TaskDelegate>
@end

@implementation QuietWatcher
- (void)taskDidFinish:(Task *)task {
    NSLog(@"[тихий] «%@» завершена", task.name);
}
@end

/* Полный делегат: обязательный + оба опциональных. */
@interface ChattyWatcher : NSObject <TaskDelegate>
@end

@implementation ChattyWatcher
- (void)taskDidStart:(Task *)task {
    NSLog(@"[болтливый] «%@» стартовала", task.name);
}
- (void)task:(Task *)task didProgress:(int)percent {
    NSLog(@"[болтливый] «%@»: %d%%", task.name, percent);
}
- (void)taskDidFinish:(Task *)task {
    NSLog(@"[болтливый] «%@» завершена", task.name);
}
@end

int main(void) {
    @autoreleasepool {
        QuietWatcher *quiet = [[QuietWatcher alloc] init];
        Task *t1 = [[Task alloc] initWithName:@"Резервная копия"];
        t1.delegate = quiet;
        NSLog(@"--- тихий наблюдатель (только required) ---");
        [t1 run];

        ChattyWatcher *chatty = [[ChattyWatcher alloc] init];
        Task *t2 = [[Task alloc] initWithName:@"Импорт данных"];
        t2.delegate = chatty;
        NSLog(@"--- болтливый наблюдатель (required + optional) ---");
        [t2 run];
    }
    return 0;
}
