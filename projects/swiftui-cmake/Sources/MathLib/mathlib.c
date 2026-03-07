#include "mathlib.h"

int mathlib_add(int a, int b) {
    return a + b;
}

int mathlib_subtract(int a, int b) {
    return a - b;
}

int mathlib_multiply(int a, int b) {
    return a * b;
}

int mathlib_divide(int a, int b, int *error) {
    if (b == 0) {
        if (error) *error = 1;
        return 0;
    }
    if (error) *error = 0;
    return a / b;
}

long long mathlib_factorial(int n) {
    if (n < 0) return -1;
    if (n <= 1) return 1;
    long long result = 1;
    for (int i = 2; i <= n; i++) {
        result *= i;
    }
    return result;
}

long long mathlib_fibonacci(int n) {
    if (n < 0) return -1;
    if (n <= 1) return n;
    long long a = 0, b = 1;
    for (int i = 2; i <= n; i++) {
        long long temp = a + b;
        a = b;
        b = temp;
    }
    return b;
}
