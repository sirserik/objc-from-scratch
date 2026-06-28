#import <Foundation/Foundation.h>

/* Задача: спроектируй делегат с optional-методами. Проверяем
   respondsToSelector: перед вызовом необязательного метода.
   Свойство delegate — weak (иначе цикл). */

@protocol DownloaderDelegate <NSObject>
@required
- (void)downloaderDidFinish:(NSString *)result;
@optional
- (void)downloaderDidProgress:(double)fraction;
@end

@interface Downloader : NSObject
@property (nonatomic, weak) id<DownloaderDelegate> delegate;  /* weak! */
- (void)run;
@end

@implementation Downloader
- (void)run {
    /* необязательный метод — зовём только если делегат его реализует */
    if ([self.delegate respondsToSelector:@selector(downloaderDidProgress:)]) {
        [self.delegate downloaderDidProgress:0.5];
    }
    /* обязательный метод — зовём без проверки (протокол гарантирует) */
    [self.delegate downloaderDidFinish:@"DATA"];
}
@end

/* Делегат реализует только @required-метод, @optional пропускает. */
@interface MinimalListener : NSObject <DownloaderDelegate>
@end
@implementation MinimalListener
- (void)downloaderDidFinish:(NSString *)result {
    NSLog(@"Minimal: готово, %@", result);
}
@end

/* Делегат реализует оба метода. */
@interface FullListener : NSObject <DownloaderDelegate>
@end
@implementation FullListener
- (void)downloaderDidProgress:(double)fraction {
    NSLog(@"Full: прогресс %.0f%%", fraction * 100);
}
- (void)downloaderDidFinish:(NSString *)result {
    NSLog(@"Full: готово, %@", result);
}
@end

int main(void) {
    @autoreleasepool {
        Downloader *d = [[Downloader alloc] init];

        MinimalListener *m = [[MinimalListener alloc] init];
        d.delegate = m;
        NSLog(@"--- minimal (без optional) ---");
        [d run];                 /* progress пропущен */

        FullListener *f = [[FullListener alloc] init];
        d.delegate = f;
        NSLog(@"--- full (с optional) ---");
        [d run];                 /* progress вызван */
    }
    return 0;
}
