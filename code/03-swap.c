#include <stdio.h>

/* наивная версия: функция получает копии чисел */
void swapBad(int a, int b) {
    int tmp = a;
    a = b;
    b = tmp;
}

/* рабочая версия: функция получает адреса чисел */
void swapGood(int *a, int *b) {
    int tmp = *a;
    *a = *b;
    *b = tmp;
}

int main(void) {
    int x = 1;
    int y = 2;

    printf("До:             x = %d, y = %d\n", x, y);

    swapBad(x, y);
    printf("После swapBad:  x = %d, y = %d\n", x, y);

    swapGood(&x, &y);
    printf("После swapGood: x = %d, y = %d\n", x, y);

    return 0;
}
