/* Глава 10, шаг 1 (наивный вариант). Загрузчик намертво знает про
   ConsoleLogger: докладывать он умеет только ему, и только об успехе.
   Именно эту жёсткую связь мы разорвём протоколом в 10-delegate.m. */
#import <Foundation/Foundation.h>

@interface ConsoleLogger : NSObject
- (void)printResult:(NSString *)data;
@end

@implementation ConsoleLogger
- (void)printResult:(NSString *)data {
    NSLog(@"  [+] готово: %@", data);
}
@end

@interface Downloader : NSObject
@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) ConsoleLogger *logger;   /* жёстко прибит */
- (instancetype)initWithURL:(NSString *)url;
- (void)start;
@end

@implementation Downloader
- (instancetype)initWithURL:(NSString *)url {
    self = [super init];
    if (self) {
        _url = [url copy];
        _logger = [[ConsoleLogger alloc] init];
    }
    return self;
}
- (void)start {
    NSLog(@"Downloader: качаю %@ ...", self.url);
    NSString *data = [NSString stringWithFormat:@"<содержимое %@>", self.url];
    [self.logger printResult:data];
}
@end

int main(void) {
    @autoreleasepool {
        Downloader *d =
            [[Downloader alloc] initWithURL:@"http://site.kz/file.txt"];
        [d start];
    }
    return 0;
}
