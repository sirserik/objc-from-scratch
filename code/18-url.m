#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* URL сетевого ресурса. */
        NSURL *site = [NSURL URLWithString:
            @"https://developer.apple.com/documentation/foundation?q=1"];
        NSLog(@"scheme: %@", site.scheme);
        NSLog(@"host:   %@", site.host);
        NSLog(@"path:   %@", site.path);
        NSLog(@"query:  %@", site.query);

        /* URL файла на диске. */
        NSURL *file = [NSURL fileURLWithPath:@"/tmp/notes/today.txt"];
        NSLog(@"file scheme: %@", file.scheme);
        NSLog(@"file path:   %@", file.path);
        NSLog(@"имя файла:    %@", file.lastPathComponent);
        NSLog(@"расширение:   %@", file.pathExtension);

        /* Достроить путь к подпапке/файлу. */
        NSURL *base = [NSURL fileURLWithPath:@"/tmp/notes"];
        NSURL *child = [base URLByAppendingPathComponent:@"june.txt"];
        NSLog(@"составной путь: %@", child.path);

        /* Уникальный идентификатор. */
        NSUUID *uuid = [NSUUID UUID];
        NSLog(@"UUID: %@", uuid.UUIDString);
    }
    return 0;
}
