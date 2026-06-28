#include <stdio.h>

int main(void) {
    int a[5];

    a[0] = 10;
    a[1] = 20;
    a[2] = 30;
    a[3] = 40;
    a[4] = 50;

    printf("Первый: %d\n", a[0]);
    printf("Последний: %d\n", a[4]);

    int sum = 0;
    for (int i = 0; i < 5; i++) {
        printf("a[%d] = %d\n", i, a[i]);
        sum = sum + a[i];
    }
    printf("Сумма: %d\n", sum);

    /* Имя массива — это адрес его первого элемента. */
    printf("Адрес a:    %p\n", (void *)a);
    printf("Адрес a[0]: %p\n", (void *)&a[0]);

    return 0;
}
