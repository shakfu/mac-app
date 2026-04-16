#ifndef PYTHONLIB_H
#define PYTHONLIB_H

#ifdef __cplusplus
extern "C" {
#endif

/// Initialize the Python interpreter.
/// @param home Path to the Python framework prefix
///             (e.g. ".../Python.framework/Versions/3.13").
/// @return 0 on success, -1 on failure.
int python_init(const char *home);

/// Run a Python code string and capture combined stdout/stderr.
/// @param code  The Python source to execute.
/// @param output  On success, set to a malloc'd string the caller must free.
///                May be NULL if no output was produced.
/// @return 0 on success, -1 on error (error text will be in *output).
int python_run(const char *code, char **output);

/// Return 1 if the interpreter is initialized, 0 otherwise.
int python_is_initialized(void);

/// Finalize the Python interpreter.
void python_finalize(void);

#ifdef __cplusplus
}
#endif

#endif /* PYTHONLIB_H */
