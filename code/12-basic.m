#import <Foundation/Foundation.h>

/* Обычная функция: код с именем, известный на этапе компиляции. */
int doubleC(int x) {
    return x * 2;
}

int main(void) {
    @autoreleasepool {
        /* --- Указатель на функцию (чистый Си) --- */
        /* f умеет показывать на КОД функции, но ничего не помнит
           о месте, где его создали. */
        int (*f)(int) = doubleC;
        NSLog(@"функция через указатель: %d", f(21));

        /* --- Блок Objective-C --- */
        /* Переменная-блок: тип int (^)(int), литерал ^(int x){...}. */
        int (^doubleB)(int) = ^(int x) {
            return x * 2;
        };
        NSLog(@"блок: %d", doubleB(21));

        /* Блок без аргументов и без возврата: void (^)(void). */
        void (^hello)(void) = ^{
            NSLog(@"привет из блока");
        };
        hello();   /* вызываем так же, как функцию: имя + () */

        /* Блок можно вызвать сколько угодно раз. */
        NSLog(@"%d, %d, %d", doubleB(1), doubleB(5), doubleB(10));
    }
    return 0;
}
