#import <Foundation/Foundation.h>

/* Глава 19. Архивация своих объектов: NSSecureCoding + NSKeyedArchiver.
 * Класс Task сам умеет записывать себя в байты и восстанавливаться. */

@interface Task : NSObject <NSSecureCoding>
@property (nonatomic, copy)   NSString *title;
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, assign) BOOL done;
- (instancetype)initWithTitle:(NSString *)title
                     priority:(NSInteger)priority;
@end

@implementation Task

- (instancetype)initWithTitle:(NSString *)title
                     priority:(NSInteger)priority {
    self = [super init];
    if (self) {
        _title = [title copy];
        _priority = priority;
        _done = NO;
    }
    return self;
}

/* Согласие на безопасное разархивирование. */
+ (BOOL)supportsSecureCoding {
    return YES;
}

/* Кодирование: перечисляем каждое поле под своим ключом. */
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeInteger:self.priority forKey:@"priority"];
    [coder encodeBool:self.done forKey:@"done"];
}

/* Декодирование: достаём поля обратно. Для объектов указываем
 * ожидаемый класс — это и есть «безопасность» NSSecureCoding. */
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _title = [coder decodeObjectOfClass:[NSString class] forKey:@"title"];
        _priority = [coder decodeIntegerForKey:@"priority"];
        _done = [coder decodeBoolForKey:@"done"];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<Task '%@' p%ld %@>",
            self.title, (long)self.priority,
            self.done ? @"готово" : @"открыто"];
}

@end

int main(void) {
    @autoreleasepool {
        Task *t = [[Task alloc] initWithTitle:@"Заархивировать объект"
                                     priority:5];
        t.done = YES;
        NSLog(@"исходный: %@", t);

        /* Объект -> NSData. requiringSecureCoding:YES требует, чтобы класс
         * поддерживал NSSecureCoding (у нас поддерживает). */
        NSError *err = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:t
                                            requiringSecureCoding:YES
                                                            error:&err];
        if (!data) {
            NSLog(@"архивация не удалась: %@", err.localizedDescription);
            return 1;
        }
        NSLog(@"архив занял %lu байт", (unsigned long)data.length);

        /* Сохраним архив в файл и прочитаем назад. */
        NSString *path = [NSTemporaryDirectory()
                            stringByAppendingPathComponent:@"task.archive"];
        [data writeToFile:path atomically:YES];

        NSData *raw = [NSData dataWithContentsOfFile:path];

        /* NSData -> объект. Указываем ожидаемый класс корня. */
        Task *back = [NSKeyedUnarchiver unarchivedObjectOfClass:[Task class]
                                                       fromData:raw
                                                          error:&err];
        if (!back) {
            NSLog(@"разархивация не удалась: %@", err.localizedDescription);
            return 1;
        }
        NSLog(@"восстановили: %@", back);
        NSLog(@"title совпал? %d", [back.title isEqualToString:t.title]);

        /* Попытка распаковать как «не тот» класс -> ошибка, а не краш. */
        Task *wrong = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSDate class]
                                                        fromData:raw
                                                           error:&err];
        NSLog(@"распаковка как NSDate -> %@ (есть ошибка? %d)",
              wrong ? @"объект" : @"nil", err != nil);

        /* Убираем за собой. */
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
        NSLog(@"архивный файл удалён");
    }
    return 0;
}
