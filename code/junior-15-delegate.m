#import <Foundation/Foundation.h>

/* delegate всегда weak. Иначе: контроллер сильно держит загрузчик, а
   загрузчик сильно держит контроллер обратно через delegate — цикл,
   оба объекта не освобождаются (утечка). weak разрывает цикл. */
@protocol DownloadDelegate <NSObject>
- (void)didFinish;
@end

@interface Downloader : NSObject
@property (nonatomic, weak) id<DownloadDelegate> delegate;   /* weak! */
- (void)start;
@end

@implementation Downloader
- (void)start { [self.delegate didFinish]; }
- (void)dealloc { NSLog(@"Downloader освобождён"); }
@end

@interface Controller : NSObject <DownloadDelegate>
@property (nonatomic, strong) Downloader *downloader;
@end

@implementation Controller
- (void)didFinish { NSLog(@"Controller: загрузка завершена"); }
- (void)dealloc { NSLog(@"Controller освобождён"); }
@end

int main(void) {
    @autoreleasepool {
        Controller *c = [Controller new];
        c.downloader = [Downloader new];
        c.downloader.delegate = c;   /* weak -> цикла нет */
        [c.downloader start];
    }   /* конец области видимости: оба объекта освобождаются */
    NSLog(@"после блока — оба объекта уже мертвы");
    return 0;
}
