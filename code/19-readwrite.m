#import <Foundation/Foundation.h>

/* Глава 19. Чтение и запись строк и сырых данных целиком —
 * одним вызовом, без открытия/закрытия дескрипторов. */

int main(void) {
    @autoreleasepool {
        NSString *dir = NSTemporaryDirectory();

        /* --- Строки --- */
        NSString *txtPath =
            [dir stringByAppendingPathComponent:@"objc-rw.txt"];

        NSString *text = @"Первая строка\nВторая строка\nИтого 3 строки\n";

        /* Записать строку в файл. atomically:YES — пишет во временный
         * файл и атомарно переименовывает поверх старого. encoding —
         * как переводить символы в байты. error даёт причину сбоя. */
        NSError *err = nil;
        BOOL ok = [text writeToFile:txtPath
                         atomically:YES
                           encoding:NSUTF8StringEncoding
                              error:&err];
        if (!ok) {
            NSLog(@"запись не удалась: %@", err.localizedDescription);
            return 1;
        }
        NSLog(@"строку записали в %@", txtPath.lastPathComponent);

        /* Прочитать строку обратно. Кодировка должна совпасть. */
        NSString *back = [NSString stringWithContentsOfFile:txtPath
                                                   encoding:NSUTF8StringEncoding
                                                      error:&err];
        if (!back) {
            NSLog(@"чтение не удалось: %@", err.localizedDescription);
            return 1;
        }
        NSLog(@"прочитали символов: %lu", (unsigned long)back.length);
        NSLog(@"совпало с исходным? %d", [back isEqualToString:text]);

        /* Заодно посчитаем строки, разбив по переводу строки. */
        NSArray<NSString *> *lines =
            [back componentsSeparatedByString:@"\n"];
        NSLog(@"первая строка файла: %@", lines.firstObject);

        /* --- Сырые байты (NSData) --- */
        NSString *binPath =
            [dir stringByAppendingPathComponent:@"objc-rw.bin"];

        /* Любую строку можно превратить в байты заданной кодировки. */
        NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"в строке %lu байт (длиннее символов из-за кириллицы)",
              (unsigned long)data.length);

        [data writeToFile:binPath atomically:YES];

        /* И прочитать сырые байты обратно. */
        NSData *raw = [NSData dataWithContentsOfFile:binPath];
        NSLog(@"прочитали %lu байт, байты совпали? %d",
              (unsigned long)raw.length, [raw isEqualToData:data]);

        /* Из байтов снова собрать строку. */
        NSString *fromData = [[NSString alloc] initWithData:raw
                                                   encoding:NSUTF8StringEncoding];
        NSLog(@"из байтов восстановили первую строку: %@",
              [fromData componentsSeparatedByString:@"\n"].firstObject);

        /* Убираем за собой. */
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:txtPath error:NULL];
        [fm removeItemAtPath:binPath error:NULL];
        NSLog(@"временные файлы удалены");
    }
    return 0;
}
