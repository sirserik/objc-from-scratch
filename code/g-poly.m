// Как в Objective-C: ВСЕ методы динамические — слова virtual нет,
// оно тут не нужно. Полиморфизм не требует общего базового класса:
// объекты могут быть НЕ родственны, лишь бы отвечали на сообщение
// (duck typing). Тип id принимает что угодно; respondsToSelector:
// и isKindOfClass: дают runtime-интроспекцию богаче, чем RTTI в C++.
// Сборка:
//   clang -fobjc-arc -framework Foundation -Wall -Wextra -O2 \
//       g-poly.m -o /tmp/t && /tmp/t
#import <Foundation/Foundation.h>

// Dog и Duck НЕ связаны наследованием — общего предка (кроме NSObject) нет.
@interface Dog : NSObject @end
@implementation Dog
- (NSString *)speak { return @"гав"; }
@end

@interface Duck : NSObject @end
@implementation Duck
- (NSString *)speak { return @"кря"; }
@end

int main(void) {
    @autoreleasepool {
        // Разнородные объекты в одной коллекции — обычное дело.
        NSArray *zoo = @[[Dog new], [Duck new]];

        for (id animal in zoo) {                 // id — «любой объект»
            // Никакого общего интерфейса не требуется: если объект
            // отвечает на selector — шлём, runtime найдёт нужный метод.
            if ([animal respondsToSelector:@selector(speak)]) {
                NSLog(@"%@ -> %@", [animal class], [animal speak]);
            }
            // Интроспекция — спросить объект о его типе во время выполнения:
            if ([animal isKindOfClass:[Dog class]]) {
                NSLog(@"   (это Dog)");
            }
        }
    }
    return 0;
}
