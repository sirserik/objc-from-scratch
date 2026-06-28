#include <stdio.h>
#include <string.h>

int main(void) {
    char s[] = "hi";

    /* Сколько ячеек заняла строка? Два символа плюс нулевой байт. */
    printf("Размер массива s: %zu\n", sizeof s);

    /* Печатаем посимвольно, пока не встретим завершающий ноль. */
    for (int i = 0; s[i] != '\0'; i++) {
        printf("s[%d] = '%c' (код %d)\n", i, s[i], s[i]);
    }

    /* А вот кириллица в UTF-8: букв 6, а байтов вдвое больше. */
    char ru[] = "Привет";
    printf("Букв глазами: 6, а strlen даёт: %zu\n", strlen(ru));

    return 0;
}
