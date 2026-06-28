#include <stdio.h>

int main(void) {
    int age = 0;

    printf("Сколько тебе лет? ");

    int got = scanf("%d", &age);
    if (got != 1) {
        printf("Это не число.\n");
        return 1;
    }

    printf("Через 10 лет тебе будет %d\n", age + 10);
    return 0;
}
