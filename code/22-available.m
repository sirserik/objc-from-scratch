/* Foundation подключён обычным заголовком — чтобы файл собирался
   тем же флагом, что и вся книга. Модульный вариант @import Foundation;
   разобран в тексте главы (ему нужен флаг -fmodules). */
#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* Проверка версии ОС в рантайме.
           Звёздочка * — «для всех прочих платформ минимум любой». */
        if (@available(macOS 12.0, iOS 15.0, *)) {
            NSLog(@"ОС достаточно свежая: можно звать новые API");
        } else {
            NSLog(@"ОС старая: идём по запасному пути");
        }

        /* Заведомо будущая версия — ветка else сработает на любой ОС. */
        if (@available(macOS 99.0, *)) {
            NSLog(@"запущены на macOS 99 или новее");
        } else {
            NSLog(@"macOS пока младше 99 — используем старый код");
        }

        /* Современная замена ISO-8601 даты появилась в macOS 10.12.
           Проверяем доступность, прежде чем создавать форматтер. */
        if (@available(macOS 10.12, *)) {
            NSISO8601DateFormatter *fmt = [[NSISO8601DateFormatter alloc] init];
            NSString *now = [fmt stringFromDate:[NSDate date]];
            NSLog(@"сейчас по ISO-8601: %@", now);
        } else {
            NSLog(@"ISO-8601 форматтер недоступен на этой ОС");
        }
    }
    return 0;
}
