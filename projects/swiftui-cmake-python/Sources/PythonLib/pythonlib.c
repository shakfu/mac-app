#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include "pythonlib.h"
#include <stdlib.h>
#include <string.h>

int python_init(const char *home) {
    if (Py_IsInitialized()) return 0;

    PyConfig config;
    PyConfig_InitPythonConfig(&config);

    if (home) {
        wchar_t *wide_home = Py_DecodeLocale(home, NULL);
        if (wide_home) {
            PyStatus status = PyConfig_SetString(&config, &config.home, wide_home);
            PyMem_RawFree(wide_home);
            if (PyStatus_Exception(status)) {
                PyConfig_Clear(&config);
                return -1;
            }
        }
    }

    PyStatus status = Py_InitializeFromConfig(&config);
    PyConfig_Clear(&config);

    return PyStatus_Exception(status) ? -1 : 0;
}

int python_is_initialized(void) {
    return Py_IsInitialized();
}

/// Helper: fetch the string value of a Python object via getvalue().
static char *get_string_value(PyObject *obj) {
    PyObject *val = PyObject_CallMethod(obj, "getvalue", NULL);
    if (!val) return NULL;

    const char *utf8 = PyUnicode_AsUTF8(val);
    char *copy = NULL;
    if (utf8 && utf8[0] != '\0') {
        copy = strdup(utf8);
    }
    Py_DECREF(val);
    return copy;
}

int python_run(const char *code, char **output) {
    if (!Py_IsInitialized()) return -1;
    if (!code || !output) return -1;
    *output = NULL;

    /* Redirect stdout and stderr to StringIO buffers. */
    int rc = PyRun_SimpleString(
        "import sys as _sys, io as _io\n"
        "_pylib_out = _io.StringIO()\n"
        "_pylib_err = _io.StringIO()\n"
        "_sys.stdout = _pylib_out\n"
        "_sys.stderr = _pylib_err\n"
    );
    if (rc != 0) return -1;

    /* Execute the user code. */
    int result = PyRun_SimpleString(code);

    /* Restore original streams. */
    PyRun_SimpleString(
        "_sys.stdout = _sys.__stdout__\n"
        "_sys.stderr = _sys.__stderr__\n"
    );

    /* Collect captured output. */
    PyObject *main_mod = PyImport_AddModule("__main__");
    if (!main_mod) return result;
    PyObject *main_dict = PyModule_GetDict(main_mod);

    PyObject *out_obj = PyDict_GetItemString(main_dict, "_pylib_out");
    PyObject *err_obj = PyDict_GetItemString(main_dict, "_pylib_err");

    char *out_str = out_obj ? get_string_value(out_obj) : NULL;
    char *err_str = err_obj ? get_string_value(err_obj) : NULL;

    /* Combine stdout and stderr into the output buffer. */
    if (out_str && err_str) {
        size_t len = strlen(out_str) + strlen(err_str) + 2;
        *output = malloc(len);
        if (*output) {
            snprintf(*output, len, "%s%s", out_str, err_str);
        }
        free(out_str);
        free(err_str);
    } else if (out_str) {
        *output = out_str;
    } else if (err_str) {
        *output = err_str;
    }

    /* Cleanup temporary variables. */
    PyRun_SimpleString(
        "del _pylib_out, _pylib_err\n"
    );

    return result;
}

void python_finalize(void) {
    if (Py_IsInitialized()) {
        Py_Finalize();
    }
}
