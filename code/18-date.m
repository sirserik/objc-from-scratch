#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* «Сейчас» — момент, в который запустили программу. */
        NSDate *now = [NSDate date];
        NSLog(@"сейчас: %@", now);

        /* Сколько секунд прошло с 1 января 1970 года (эпоха Unix). */
        NSLog(@"с 1970: %.0f секунд", [now timeIntervalSince1970]);

        /* Момент через час и через сутки от «сейчас». */
        NSDate *inHour = [now dateByAddingTimeInterval:3600];
        NSDate *inDay  = [now dateByAddingTimeInterval:24 * 3600];
        NSLog(@"через час: %@", inHour);
        NSLog(@"через сутки: %@", inDay);

        /* Сколько секунд между «сейчас» и «через час». */
        NSTimeInterval gap = [inHour timeIntervalSinceDate:now];
        NSLog(@"разница: %.0f секунд", gap);

        /* Сравнение дат. */
        if ([now compare:inDay] == NSOrderedAscending) {
            NSLog(@"now раньше, чем inDay");
        }
        NSDate *earlier = [now earlierDate:inDay];
        NSLog(@"раньше из двух: %@", earlier);

        /* Дата ↔ строка через NSDateFormatter. */
        NSDateFormatter *f = [[NSDateFormatter alloc] init];
        f.locale = [NSLocale localeWithLocaleIdentifier:@"ru_RU"];
        f.dateFormat = @"dd.MM.yyyy HH:mm";
        NSString *text = [f stringFromDate:now];
        NSLog(@"отформатировано: %@", text);

        /* Обратно: строка → дата. */
        NSDate *parsed = [f dateFromString:@"31.12.2025 23:59"];
        NSLog(@"разобрано из строки: %@", parsed);
    }
    return 0;
}
