#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* Строка → байты в кодировке UTF-8. */
        NSString *hello = @"Привет, NSData!";
        NSData *bytes = [hello dataUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"строка заняла %lu байт", (unsigned long)[bytes length]);

        /* Байты → строка обратно. */
        NSString *back = [[NSString alloc] initWithData:bytes
                                               encoding:NSUTF8StringEncoding];
        NSLog(@"раскодировали обратно: %@", back);

        /* Base64 — байты в безопасный текст и назад. */
        NSString *b64 = [bytes base64EncodedStringWithOptions:0];
        NSLog(@"base64: %@", b64);
        NSData *decoded = [[NSData alloc] initWithBase64EncodedString:b64
                                                             options:0];
        NSString *fromB64 = [[NSString alloc] initWithData:decoded
                                                  encoding:NSUTF8StringEncoding];
        NSLog(@"из base64: %@", fromB64);

        /* Записать байты в файл и прочитать их обратно. */
        NSString *path = @"/tmp/18-data-demo.txt";
        BOOL ok = [bytes writeToFile:path atomically:YES];
        NSLog(@"запись в файл удалась: %@", ok ? @"да" : @"нет");

        NSData *loaded = [NSData dataWithContentsOfFile:path];
        NSLog(@"прочитали %lu байт из файла", (unsigned long)[loaded length]);
    }
    return 0;
}
