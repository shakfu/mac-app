#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "mathlib.h"

static int tests_run = 0;
static int tests_passed = 0;

#define TEST(name) \
    do { \
        tests_run++; \
        printf("  %-40s", #name); \
    } while (0)

#define PASS() \
    do { \
        tests_passed++; \
        printf("PASS\n"); \
    } while (0)

#define ASSERT_EQ(expected, actual) \
    do { \
        if ((expected) != (actual)) { \
            printf("FAIL (expected %lld, got %lld)\n", \
                   (long long)(expected), (long long)(actual)); \
            return; \
        } \
    } while (0)

static void test_add(void) {
    TEST(add_positive);
    ASSERT_EQ(5, mathlib_add(2, 3));
    ASSERT_EQ(0, mathlib_add(-1, 1));
    ASSERT_EQ(-5, mathlib_add(-2, -3));
    PASS();
}

static void test_subtract(void) {
    TEST(subtract);
    ASSERT_EQ(1, mathlib_subtract(3, 2));
    ASSERT_EQ(-1, mathlib_subtract(2, 3));
    ASSERT_EQ(0, mathlib_subtract(5, 5));
    PASS();
}

static void test_multiply(void) {
    TEST(multiply);
    ASSERT_EQ(6, mathlib_multiply(2, 3));
    ASSERT_EQ(0, mathlib_multiply(0, 100));
    ASSERT_EQ(6, mathlib_multiply(-2, -3));
    PASS();
}

static void test_divide(void) {
    TEST(divide_normal);
    int error = 0;
    ASSERT_EQ(3, mathlib_divide(6, 2, &error));
    ASSERT_EQ(0, error);
    PASS();

    TEST(divide_by_zero);
    error = 0;
    mathlib_divide(6, 0, &error);
    ASSERT_EQ(1, error);
    PASS();

    TEST(divide_null_error);
    /* Should not crash when error is NULL */
    ASSERT_EQ(5, mathlib_divide(10, 2, NULL));
    PASS();
}

static void test_factorial(void) {
    TEST(factorial);
    ASSERT_EQ(1, mathlib_factorial(0));
    ASSERT_EQ(1, mathlib_factorial(1));
    ASSERT_EQ(120, mathlib_factorial(5));
    ASSERT_EQ(3628800, mathlib_factorial(10));
    ASSERT_EQ(-1, mathlib_factorial(-1));
    PASS();
}

static void test_fibonacci(void) {
    TEST(fibonacci);
    ASSERT_EQ(0, mathlib_fibonacci(0));
    ASSERT_EQ(1, mathlib_fibonacci(1));
    ASSERT_EQ(5, mathlib_fibonacci(5));
    ASSERT_EQ(55, mathlib_fibonacci(10));
    ASSERT_EQ(-1, mathlib_fibonacci(-1));
    PASS();
}

int main(void) {
    printf("Running mathlib tests:\n");

    test_add();
    test_subtract();
    test_multiply();
    test_divide();
    test_factorial();
    test_fibonacci();

    printf("\n%d/%d tests passed\n", tests_passed, tests_run);
    return (tests_passed == tests_run) ? EXIT_SUCCESS : EXIT_FAILURE;
}
