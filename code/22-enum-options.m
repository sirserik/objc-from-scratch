#import <Foundation/Foundation.h>

/* NS_ENUM — типобезопасное перечисление состояний.
   Тип значений — NSInteger, имя типа — TaskStatus. */
typedef NS_ENUM(NSInteger, TaskStatus) {
    TaskStatusTodo,         /* 0 */
    TaskStatusInProgress,   /* 1 */
    TaskStatusDone,         /* 2 */
};

/* NS_OPTIONS — битовые флаги: значения степени двойки,
   их можно складывать через | и проверять через &. */
typedef NS_OPTIONS(NSUInteger, Permissions) {
    PermissionNone   = 0,        /* 0000 */
    PermissionRead   = 1 << 0,   /* 0001 */
    PermissionWrite  = 1 << 1,   /* 0010 */
    PermissionDelete = 1 << 2,   /* 0100 */
    /* удобная комбинация */
    PermissionAll    = PermissionRead | PermissionWrite | PermissionDelete,
};

/* Превращаем статус в текст. Компилятор для NS_ENUM в switch
   предупредит, если забыть один из случаев (-Wswitch). */
static NSString *statusName(TaskStatus status) {
    switch (status) {
        case TaskStatusTodo:        return @"в очереди";
        case TaskStatusInProgress:  return @"в работе";
        case TaskStatusDone:        return @"готово";
    }
    return @"?";
}

int main(void) {
    @autoreleasepool {
        /* enum: переменная строго типа TaskStatus */
        TaskStatus st = TaskStatusInProgress;
        NSLog(@"статус: %@ (код %ld)", statusName(st), (long)st);

        /* options: собираем права через ИЛИ */
        Permissions perms = PermissionRead | PermissionWrite;
        NSLog(@"маска прав: %lu", (unsigned long)perms);   /* 1|2 = 3 */

        /* проверяем отдельный флаг через И */
        if (perms & PermissionRead) {
            NSLog(@"можно читать");
        }
        if (perms & PermissionDelete) {
            NSLog(@"можно удалять");
        } else {
            NSLog(@"удалять нельзя");
        }

        /* добавляем флаг */
        perms |= PermissionDelete;
        NSLog(@"после выдачи delete маска: %lu", (unsigned long)perms);
        NSLog(@"полные права? %@",
              (perms == PermissionAll) ? @"да" : @"нет");

        /* снимаем флаг: И с инверсией */
        perms &= ~PermissionWrite;
        NSLog(@"после отзыва write маска: %lu", (unsigned long)perms);
    }
    return 0;
}
