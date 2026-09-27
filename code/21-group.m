#import <Foundation/Foundation.h>

// Имитируем загрузку одного файла: пауза + результат.
static NSString *downloadFile(NSString *name) {
    [NSThread sleepForTimeInterval:0.3];
    return [NSString stringWithFormat:@"%@ готов", name];
}

int main(void) {
    @autoreleasepool {
        NSArray<NSString *> *names = @[ @"картинки", @"видео", @"музыка" ];

        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t bg =
            dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);

        // Потокобезопасный сбор результатов: пишем в массив на своей
        // последовательной очереди, чтобы не было гонки (см. 21-race.m).
        NSMutableArray<NSString *> *results = [NSMutableArray array];
        dispatch_queue_t guard =
            dispatch_queue_create("results.guard", DISPATCH_QUEUE_SERIAL);

        NSLog(@"запускаем параллельно загрузок: %lu",
              (unsigned long)names.count);

        for (NSString *name in names) {
            // group_async: задача «приписана» к группе.
            dispatch_group_async(group, bg, ^{
                NSString *done = downloadFile(name);
                dispatch_sync(guard, ^{ [results addObject:done]; });
            });
        }

        // Ждём, пока ВСЕ задачи группы завершатся (блокируем main).
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

        NSLog(@"все загрузки завершены, собрано результатов: %lu",
              (unsigned long)results.count);
        for (NSString *r in results) {
            NSLog(@"  - %@", r);
        }
    }
    return 0;
}
