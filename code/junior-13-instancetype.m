#import <Foundation/Foundation.h>

/* instancetype в фабричном методе говорит компилятору: «вернётся объект
   ИМЕННО этого класса». Поэтому к результату можно сразу слать методы
   класса без приведения. С id компилятор не знал бы точный тип. */
@interface Widget : NSObject
@property (nonatomic, copy) NSString *title;
+ (instancetype)widgetWithTitle:(NSString *)title;
@end

@implementation Widget
+ (instancetype)widgetWithTitle:(NSString *)title {
    Widget *w = [[self alloc] init];   /* self здесь — сам класс */
    w.title = title;
    return w;
}
@end

int main(void) {
    @autoreleasepool {
        /* тип выводится точно как Widget *, .title доступно без приведения */
        Widget *w = [Widget widgetWithTitle:@"Кнопка"];
        NSLog(@"создан Widget с title = %@", w.title);
    }
    return 0;
}
