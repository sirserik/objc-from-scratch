#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* NSValue упаковывает произвольную C-структуру в объект.
           Возьмём NSRange — структуру из двух полей (location, length). */
        NSRange range = NSMakeRange(2, 5);
        NSValue *boxed = [NSValue valueWithBytes:&range
                                        objCType:@encode(NSRange)];

        /* Теперь структуру можно положить в массив (он хранит объекты). */
        NSArray *ranges = @[ boxed ];
        NSLog(@"в массиве лежит: %@", ranges[0]);

        /* Распаковка: getValue: копирует байты обратно в структуру. */
        NSRange back;
        [boxed getValue:&back];
        NSLog(@"распаковали: location=%lu length=%lu",
              (unsigned long)back.location, (unsigned long)back.length);

        /* Для NSRange есть готовая обёртка-удобство. */
        NSValue *r2 = [NSValue valueWithRange:NSMakeRange(10, 3)];
        NSRange got = [r2 rangeValue];
        NSLog(@"valueWithRange: location=%lu length=%lu",
              (unsigned long)got.location, (unsigned long)got.length);

        /* --- NSNull: объект-«ничто» для коллекций. --- */
        /* В массив нельзя класть nil — это конец списка аргументов.
           Когда значение «пустое», кладут общий объект [NSNull null]. */
        id maybeName = [NSNull null];
        NSArray *row = @[ @"Иван", maybeName, @42 ];
        NSLog(@"строка с дыркой: %@", row);

        id cell = row[1];
        if (cell == [NSNull null]) {
            NSLog(@"в ячейке 1 — NSNull (значения нет)");
        }

        /* nil и NSNull — разные вещи. */
        NSLog(@"nil это NSNull? %@",
              (nil == [NSNull null]) ? @"да" : @"нет");
    }
    return 0;
}
