#include <stdio.h>
#include <string.h>

int main(void) {
    char buf1[] = "cat";
    char buf2[] = "cat";
    const char *a = buf1;   /* указывает на первый "cat"  */
    const char *b = buf2;   /* указывает на второй "cat"  */

    /* Наивная попытка: сравнить строки через ==. */
    if (a == b) {
        printf("a == b: строки равны\n");
    } else {
        printf("a == b: строки РАЗНЫЕ (сравнили адреса, не текст!)\n");
    }

    /* Правильно: strcmp возвращает 0, когда строки совпадают. */
    if (strcmp(a, b) == 0) {
        printf("strcmp: строки равны\n");
    } else {
        printf("strcmp: строки разные\n");
    }

    /* Знак результата говорит о порядке. */
    printf("strcmp(\"apple\", \"banana\") = %d\n", strcmp("apple", "banana"));
    printf("strcmp(\"banana\", \"apple\") = %d\n", strcmp("banana", "apple"));

    /* Копирование: буфер заведомо больше источника. */
    char dst[16];
    strcpy(dst, "cat");
    printf("После strcpy: %s\n", dst);

    return 0;
}
