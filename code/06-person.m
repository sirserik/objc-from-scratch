#import <Foundation/Foundation.h>

@interface Person : NSObject
{
    NSString *_name;   /* имя */
    NSInteger _age;    /* возраст */
}
- (void)setName:(NSString *)newName;
- (NSString *)name;
- (void)setAge:(NSInteger)newAge;
- (void)sayHello;
- (void)greet:(Person *)other;
@end

@implementation Person

- (void)setName:(NSString *)newName {
    _name = newName;
}

- (NSString *)name {
    return _name;
}

- (void)setAge:(NSInteger)newAge {
    _age = newAge;
}

- (void)sayHello {
    NSLog(@"Привет! Меня зовут %@, мне %ld.", _name, (long)_age);
}

- (void)greet:(Person *)other {
    NSLog(@"%@ говорит: привет, %@!", [self name], [other name]);
}

@end

int main(void) {
    @autoreleasepool {
        Person *anna = [[Person alloc] init];
        [anna setName:@"Анна"];
        [anna setAge:30];

        Person *boris = [[Person alloc] init];
        [boris setName:@"Борис"];
        [boris setAge:25];

        [anna sayHello];
        [boris sayHello];
        [anna greet:boris];
        [boris greet:anna];
    }
    return 0;
}
