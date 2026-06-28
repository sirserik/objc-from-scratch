#import <Foundation/Foundation.h>

@class Downloader;   /* анонс: имя есть, описание ниже */

/* Контракт делегата: что загрузчик умеет сообщить «кому-то». */
@protocol DownloaderDelegate <NSObject>
- (void)downloader:(Downloader *)downloader
 didFinishWithData:(NSString *)data;
- (void)downloader:(Downloader *)downloader
  didFailWithError:(NSString *)reason;
@end

@interface Downloader : NSObject
@property (nonatomic, copy) NSString *url;
@property (nonatomic, weak) id<DownloaderDelegate> delegate;
- (instancetype)initWithURL:(NSString *)url;
- (void)start;
@end

@implementation Downloader
- (instancetype)initWithURL:(NSString *)url {
    self = [super init];
    if (self) {
        _url = [url copy];
    }
    return self;
}
- (void)start {
    NSLog(@"Downloader: качаю %@ ...", self.url);
    /* Имитация сети: адреса со словом "secret" падают, остальные успешны. */
    if ([self.url containsString:@"secret"]) {
        [self.delegate downloader:self
                 didFailWithError:@"403 Доступ запрещён"];
    } else {
        NSString *data = [NSString stringWithFormat:@"<содержимое %@>",
                          self.url];
        [self.delegate downloader:self didFinishWithData:data];
    }
}
@end

/* Делегат: тот, кто хочет знать о результате загрузки. */
@interface ConsoleLogger : NSObject <DownloaderDelegate>
@end

@implementation ConsoleLogger
- (void)downloader:(Downloader *)downloader
 didFinishWithData:(NSString *)data {
    NSLog(@"  [+] %@ готово: %@", downloader.url, data);
}
- (void)downloader:(Downloader *)downloader
  didFailWithError:(NSString *)reason {
    NSLog(@"  [-] %@ ошибка: %@", downloader.url, reason);
}
@end

int main(void) {
    @autoreleasepool {
        ConsoleLogger *logger = [[ConsoleLogger alloc] init];

        Downloader *d1 =
            [[Downloader alloc] initWithURL:@"http://site.kz/file.txt"];
        d1.delegate = logger;
        [d1 start];

        Downloader *d2 =
            [[Downloader alloc] initWithURL:@"http://site.kz/secret.txt"];
        d2.delegate = logger;
        [d2 start];

        /* Делегат не назначен (nil). start не упадёт:
           сообщение к nil просто ничего не делает. */
        Downloader *d3 =
            [[Downloader alloc] initWithURL:@"http://site.kz/orphan.txt"];
        [d3 start];
    }
    return 0;
}
