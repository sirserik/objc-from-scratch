#import <Foundation/Foundation.h>

/* В коллекции нельзя класть nil — это «нет объекта». Чтобы хранить
   осмысленное «значение отсутствует», есть объект-заглушка NSNull.
   А запись dict[key] = nil — это не вставка nil, а УДАЛЕНИЕ ключа. */
int main(void) {
    @autoreleasepool {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        d[@"name"]   = @"Анна";
        d[@"middle"] = [NSNull null];   /* явная заглушка «нет отчества» */

        NSLog(@"name:   %@", d[@"name"]);
        NSLog(@"middle: %@", d[@"middle"]);    /* <null> */
        NSLog(@"absent: %@", d[@"absent"]);    /* нет ключа -> nil -> (null) */

        id middle = d[@"middle"];
        if (middle == [NSNull null]) {
            NSLog(@"middle — это NSNull, а не настоящее значение");
        }
    }
    return 0;
}
