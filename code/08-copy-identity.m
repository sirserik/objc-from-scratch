/* Глава 8. Что на самом деле делает copy: для неизменяемой строки —
   ничего, для изменяемой — настоящую копию. Печатаем адреса объектов. */
#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        NSString *a = @"Привет";
        NSString *b = [a copy];
        NSLog(@"неизменяемая: a=%p b=%p — тот же объект: %@",
              (__bridge void *)a, (__bridge void *)b,
              (a == b) ? @"да" : @"нет");

        NSMutableString *m = [NSMutableString stringWithString:@"Привет"];
        NSString *c = [m copy];
        NSLog(@"изменяемая:   m=%p c=%p — тот же объект: %@",
              (__bridge void *)m, (__bridge void *)c,
              (m == c) ? @"да" : @"нет");

        NSLog(@"класс копии изменяемой строки: %@",
              NSStringFromClass([c class]));
    }
    return 0;
}
