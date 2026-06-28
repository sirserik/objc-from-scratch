#import <Foundation/Foundation.h>

/* Класс с одним свойством name и одним свойством age.
   @property просит компилятор сам сделать геттер, сеттер
   и скрытый ivar _name / _age. */
@interface Person : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@end

@implementation Person
@end

int main(void) {
    @autoreleasepool {
        Person *p = [[Person alloc] init];

        /* Установка через точечную запись — это сообщение setName:. */
        p.name = @"Айгерим";
        p.age = 30;

        /* Чтение через точечную запись — это сообщение name / age. */
        NSLog(@"через точку:    %@, %ld", p.name, (long)p.age);

        /* Ровно то же самое явными сообщениями. */
        [p setName:@"Болат"];
        [p setAge:42];
        NSLog(@"через сообщения: %@, %ld", [p name], (long)[p age]);
    }
    return 0;
}
