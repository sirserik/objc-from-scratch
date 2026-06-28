#include <stdio.h>
#include <string.h>

/* Наша собственная длина строки: шагаем до завершающего '\0'. */
static size_t my_strlen(const char *str) {
    size_t n = 0;
    while (str[n] != '\0') {
        n++;
    }
    return n;
}

int main(void) {
    char word[] = "Objective";

    printf("my_strlen: %zu\n", my_strlen(word));
    printf("strlen:    %zu\n", strlen(word));

    char empty[] = "";
    printf("Длина пустой строки: %zu\n", my_strlen(empty));

    return 0;
}
