#import <Foundation/Foundation.h>

/* Глава 19. NSFileManager: папки, файлы, атрибуты.
 * Всё происходит во временной директории и убирается за собой. */

int main(void) {
    @autoreleasepool {
        NSFileManager *fm = [NSFileManager defaultManager];

        /* 1. Временная папка системы — куда можно писать без спроса. */
        NSString *tmp = NSTemporaryDirectory();
        NSLog(@"временная папка: %@", tmp);

        /* 2. Строим путь к своей подпапке внутри временной. */
        NSString *dir = [tmp stringByAppendingPathComponent:@"objc-fm-demo"];
        NSLog(@"наша папка:     %@", dir);

        /* 3. Создаём подпапку. withIntermediateDirectories:YES создаёт
         *    и все недостающие промежуточные папки разом. */
        NSError *err = nil;
        BOOL ok = [fm createDirectoryAtPath:dir
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&err];
        if (!ok) {
            NSLog(@"не смог создать папку: %@", err.localizedDescription);
            return 1;
        }

        /* 4. Кладём в неё три файла. */
        NSArray<NSString *> *names = @[ @"a.txt", @"b.txt", @"note.md" ];
        for (NSString *name in names) {
            NSString *path = [dir stringByAppendingPathComponent:name];
            NSString *body = [NSString stringWithFormat:@"файл %@\n", name];
            [body writeToFile:path
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:NULL];
        }

        /* 5. Проверяем существование. */
        NSString *aPath = [dir stringByAppendingPathComponent:@"a.txt"];
        NSLog(@"a.txt на месте? %d", [fm fileExistsAtPath:aPath]);
        NSLog(@"z.txt на месте? %d",
              [fm fileExistsAtPath:
                  [dir stringByAppendingPathComponent:@"z.txt"]]);

        /* 6. fileExistsAtPath:isDirectory: заодно говорит, папка это или файл. */
        BOOL isDir = NO;
        [fm fileExistsAtPath:dir isDirectory:&isDir];
        NSLog(@"наш путь — папка? %d", isDir);

        /* 7. Список содержимого папки (только имена, без полного пути). */
        NSArray<NSString *> *items =
            [fm contentsOfDirectoryAtPath:dir error:NULL];
        NSArray<NSString *> *sorted =
            [items sortedArrayUsingSelector:@selector(compare:)];
        NSLog(@"в папке: %@", [sorted componentsJoinedByString:@", "]);

        /* 8. Атрибуты файла: размер, дата изменения. */
        NSDictionary<NSFileAttributeKey, id> *attrs =
            [fm attributesOfItemAtPath:aPath error:NULL];
        unsigned long long size =
            [attrs[NSFileSize] unsignedLongLongValue];
        NSDate *mtime = attrs[NSFileModificationDate];
        NSLog(@"a.txt: размер=%llu байт, изменён=%@", size, mtime);

        /* 9. Убираем за собой: удаляем всю папку с содержимым. */
        if ([fm removeItemAtPath:dir error:&err]) {
            NSLog(@"папку удалили");
        } else {
            NSLog(@"не удалил: %@", err.localizedDescription);
        }
        NSLog(@"папка ещё есть? %d", [fm fileExistsAtPath:dir]);
    }
    return 0;
}
