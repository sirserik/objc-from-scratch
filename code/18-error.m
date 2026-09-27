#import <Foundation/Foundation.h>

/* Своя ошибка: домен + код + человекочитаемое описание. */
static NSString *const DeadlineErrorDomain = @"com.objcbook.deadline";

/* Считает целые дни до даты. Если дата уже прошла — это ошибка,
   о которой мы сообщаем через NSError по указателю. */
static BOOL daysUntil(NSDate *target, NSInteger *outDays, NSError **error) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];

    if ([target compare:now] == NSOrderedAscending) {
        if (error) {                       /* вызвавшему ошибка нужна? */
            NSDictionary *info = @{
                NSLocalizedDescriptionKey: @"Дедлайн уже в прошлом."
            };
            *error = [NSError errorWithDomain:DeadlineErrorDomain
                                         code:1
                                     userInfo:info];
        }
        return NO;                         /* провал: NO + заполнили error */
    }

    NSDateComponents *diff = [cal components:NSCalendarUnitDay
                                    fromDate:now toDate:target options:0];
    if (outDays) { *outDays = diff.day; }
    return YES;                            /* успех: YES, error не трогаем */
}

int main(void) {
    @autoreleasepool {
        /* 1. Дата в прошлом → ждём ошибку. */
        NSDate *past = [NSDate dateWithTimeIntervalSinceNow:-3600];
        NSError *err = nil;
        NSInteger days = 0;
        if (daysUntil(past, &days, &err)) {
            NSLog(@"дней до дедлайна: %ld", (long)days);
        } else {
            NSLog(@"ошибка: %@", err.localizedDescription);
            NSLog(@"  домен: %@, код: %ld", err.domain, (long)err.code);
        }

        /* 2. Будущая дата → ждём число дней. */
        NSDate *future =
            [NSDate dateWithTimeIntervalSinceNow:5 * 24 * 3600];
        NSError *err2 = nil;
        if (daysUntil(future, &days, &err2)) {
            NSLog(@"дней до будущего дедлайна: %ld", (long)days);
        }

        /* 3. Чтение несуществующего файла. */
        NSError *readErr = nil;
        NSString *text =
            [NSString stringWithContentsOfFile:@"/tmp/нет-такого.txt"
                                      encoding:NSUTF8StringEncoding
                                         error:&readErr];
        if (text == nil) {
            NSLog(@"чтение не удалось: %@", readErr.localizedDescription);
            NSLog(@"  домен: %@, код: %ld",
                  readErr.domain, (long)readErr.code);
        } else {
            NSLog(@"прочитали: %@", text);
        }
    }
    return 0;
}
