#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDate *now = [NSDate date];

        /* Разложить дату на компоненты. */
        NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth |
                               NSCalendarUnitDay | NSCalendarUnitHour |
                               NSCalendarUnitMinute;
        NSDateComponents *c = [cal components:units fromDate:now];
        NSLog(@"сегодня: %ld-%02ld-%02ld %02ld:%02ld",
              (long)c.year, (long)c.month, (long)c.day,
              (long)c.hour, (long)c.minute);

        /* Собрать дату из компонентов: 1 января 2027, 09:00. */
        NSDateComponents *deadlineParts = [[NSDateComponents alloc] init];
        deadlineParts.year = 2027;
        deadlineParts.month = 1;
        deadlineParts.day = 1;
        deadlineParts.hour = 9;
        NSDate *deadline = [cal dateFromComponents:deadlineParts];
        NSLog(@"дедлайн: %@", deadline);

        /* Разница в днях между двумя датами — по календарю. */
        NSDateComponents *diff = [cal components:NSCalendarUnitDay
                                        fromDate:now
                                          toDate:deadline
                                         options:0];
        NSLog(@"до дедлайна дней: %ld", (long)diff.day);

        /* Прибавить один день правильно — через календарь, не +86400. */
        NSDateComponents *oneDay = [[NSDateComponents alloc] init];
        oneDay.day = 1;
        NSDate *tomorrow = [cal dateByAddingComponents:oneDay
                                                toDate:now
                                               options:0];
        NSLog(@"завтра в это же время: %@", tomorrow);
    }
    return 0;
}
