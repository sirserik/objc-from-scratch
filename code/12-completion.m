#import <Foundation/Foundation.h>

/* Тип completion-блока: получает результат (NSString *) и ничего
   не возвращает. typedef делает сигнатуру метода читаемой. */
typedef void (^DownloadHandler)(NSString *result);

@interface Downloader : NSObject
- (void)downloadName:(NSString *)name
          completion:(DownloadHandler)completion;
@end

@implementation Downloader

/* Метод делает «работу» и в конце ЗОВЁТ переданный блок,
   отдавая ему результат. Так вызывающий код узнаёт, что готово. */
- (void)downloadName:(NSString *)name
          completion:(DownloadHandler)completion {
    NSLog(@"качаю %@ ...", name);
    NSString *result = [name uppercaseString];   /* «результат работы» */
    completion(result);                           /* вызываем блок */
}

@end

int main(void) {
    @autoreleasepool {
        Downloader *d = [[Downloader alloc] init];

        /* Передаём блок прямо на месте вызова. Он сработает тогда,
           когда метод сам решит — внутри downloadName:completion:. */
        [d downloadName:@"file.txt" completion:^(NSString *result) {
            NSLog(@"готово, получил: %@", result);
        }];

        /* Тот же метод, другой блок-обработчик. */
        [d downloadName:@"photo.png" completion:^(NSString *result) {
            NSLog(@"длина результата: %lu",
                  (unsigned long)result.length);
        }];
    }
    return 0;
}
