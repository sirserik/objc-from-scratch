#include <stdio.h>
#include <stdbool.h>

int main(void) {
    int age = 19;
    double price = 199.90;
    char grade = 'A';
    bool isStudent = true;

    printf("Возраст: %d\n", age);
    printf("Цена: %f\n", price);
    printf("Цена (2 знака): %.2f\n", price);
    printf("Оценка: %c\n", grade);
    printf("Студент: %d\n", isStudent);

    age = age + 1;
    printf("Через год: %d\n", age);

    return 0;
}
