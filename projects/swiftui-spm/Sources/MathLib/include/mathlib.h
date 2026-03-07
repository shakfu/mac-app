#ifndef MATHLIB_H
#define MATHLIB_H

#ifdef __cplusplus
extern "C" {
#endif

/// Add two integers.
int mathlib_add(int a, int b);

/// Subtract b from a.
int mathlib_subtract(int a, int b);

/// Multiply two integers.
int mathlib_multiply(int a, int b);

/// Integer division. Returns 0 and sets error to 1 on division by zero.
int mathlib_divide(int a, int b, int *error);

/// Compute factorial of n. Returns -1 for negative input.
long long mathlib_factorial(int n);

/// Compute the nth Fibonacci number. Returns -1 for negative input.
long long mathlib_fibonacci(int n);

#ifdef __cplusplus
}
#endif

#endif /* MATHLIB_H */
