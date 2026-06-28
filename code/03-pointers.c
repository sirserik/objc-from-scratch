#include <stdio.h>

int main(void) {
    int age = 19;

    /* значение переменной и её адрес в памяти */
    printf("Значение age:   %d\n", age);
    printf("Адрес age:      %p\n", (void *)&age);

    /* указатель: переменная, которая хранит адрес */
    int *p = &age;
    printf("Значение p:     %p\n", (void *)p);
    printf("Куда смотрит p: %d\n", *p);

    /* меняем age, не трогая саму age — только через указатель */
    *p = 25;
    printf("Теперь age:     %d\n", age);

    /* NULL — указатель, который явно никуда не смотрит */
    int *empty = NULL;
    if (empty == NULL) {
        printf("empty пока никуда не смотрит\n");
    }

    return 0;
}
