#import <Foundation/Foundation.h>

/* Своя ошибка: домен + код + человекочитаемое описание. */
static NSString *const DeadlineErrorDomain = @"com.objcbook.deadline";

/* Считает целые дни до даты. Если дата уже прошла — это ошибка,
   о которой мы сообщаем через NSError по указателю. */
static BOOL daysUntil(NSDate *target, NSInteger *outDays, NSError **error) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];

    if ([target compare:now] == NSOrderedAscending) {
        if (error) {
            NSDictionary *info = @{
                NSLocalizedDescriptionKey: @"Дедлайн уже в прошлом."
            };
            *error = [NSError errorWithDomain:DeadlineErrorDomain
                                         code:1
                                     userInfo:info];
        }
        return NO;            /* провал: вернули NO + заполнили error */
    }

    NSDateComponents *diff = [cal components:NSCalendarUnitDay
                                    fromDate:now
                                      toDate:target
                                     options:0];
    if (outDays) {
        *outDays = diff.day;
    }
    return YES;              /* успех: вернули YES, error не трогали */
}

int main(void) {
    @autoreleasepool {
        /* 1. Потребляем СВОЮ ошибку. Дата в прошлом → ждём провал. */
        NSDate *past = [NSDate dateWithTimeIntervalSinceNow:-3600];
        NSError *err = nil;
        NSInteger days = 0;
        if (daysUntil(past, &days, &err)) {
            NSLog(@"до дедлайна %ld дней", (long)days);
        } else {
            NSLog(@"ошибка: %@", err.localizedDescription);
            NSLog(@"  домен: %@, код: %ld",
                  err.domain, (long)err.code);
        }

        /* Будущая дата → успех. */
        NSDate *future = [NSDate dateWithTimeIntervalSinceNow:5 * 24 * 3600];
        NSError *err2 = nil;
        if (daysUntil(future, &days, &err2)) {
            NSLog(@"до будущего дедлайна %ld дней", (long)days);
        }

        /* 2. Потребляем ЧУЖУЮ ошибку: читаем заведомо несуществующий файл. */
        NSError *readErr = nil;
        NSString *text = [NSString stringWithContentsOfFile:@"/tmp/нет-такого.txt"
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
