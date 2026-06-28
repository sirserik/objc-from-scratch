#import <Foundation/Foundation.h>

// «Скачиваем» данные: имитируем долгую работу паузой.
static NSString *downloadReport(void) {
    [NSThread sleepForTimeInterval:0.5];   // как будто ждём сеть
    return @"отчёт за июнь: 1000 строк";
}

int main(void) {
    @autoreleasepool {
        NSLog(@"1. старт на главной очереди");

        // Глобальная фоновая очередь — туда кладём долгую работу.
        dispatch_queue_t bg =
            dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);

        dispatch_async(bg, ^{
            // Этот блок выполняется НЕ на главном потоке.
            NSString *report = downloadReport();
            NSLog(@"2. загрузка закончена в фоне");

            // Результат возвращаем на главную очередь.
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"3. показываем результат: %@", report);
                exit(0);          // явно завершаем программу
            });
        });

        NSLog(@"4. главная очередь свободна, ждём событий");

        // Запускаем обработку главной очереди. Без этого блоки,
        // отправленные в dispatch_get_main_queue(), не выполнятся.
        dispatch_main();
    }
    return 0;   // сюда мы не дойдём: программу закроет exit(0)
}
