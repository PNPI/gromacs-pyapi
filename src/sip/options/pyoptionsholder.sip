/*
 * This file is part of the GROMACS-PyAPI package.
 *
 * Copyright (c) 2014,2015,
 * by Maks Koltsov <maks@omrb.pnpi.spb.ru> and
 * by Alexey Shvetsov <alexxy@omrb.pnpi.spb.ru>
 *
 * GROMACS-PyAPI is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 2.1
 * of the License, or (at your option) any later version.
 *
 * GROMACS-PyAPI is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with GROMACS; if not, see
 * http://www.gnu.org/licenses, or write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
 */

%ModuleHeaderCode
#include <exception>
#include "gromacs/options/basicoptions.h"
#include "gromacs/options/filenameoption.h"
#include "gromacs/selection/selectionoption.h"
#include <map>
#include <string>

class PyOptionsHolder {
    public:
        class DuplicateOption: public std::exception {
            public:
                virtual const char* what() const noexcept;
        };
        class StringList {
            public:
                StringList(const std::vector < std::string > *);
                StringList(const std::string*, size_t);
                const char       * operator[] (size_t);
            private:
                const std::string *list;
                size_t             size;
                const              std::vector < std::string > *vector;
        };
        gmx::DoubleOption doubleOption(const char*, size_t = 1, double* = NULL);
        gmx::IntegerOption integerOption(const char*, size_t = 1, int* = NULL);
        gmx::StringOption stringOption(const char*, size_t = 1, const char* = NULL);
        gmx::BooleanOption booleanOption(const char*, size_t = 1, bool = 0);
        gmx::SelectionOption selectionOption(const char*, size_t = 1);
        gmx::FileNameOption fileNameOption(const char*, size_t = 1);
        PyObject* get_value(const char*);
        ~PyOptionsHolder();
    private:
        struct option_value {
            void       *value;
            const char *type;
            int        *count;
            bool        vector;
            const char *name;
        };
        std::map < std::string, option_value > storage;
        template < typename T, typename U > U createStorage(const char*, const char*, int, const T* = 0);
        template < typename T > PyObject* buildValue(const char*, const option_value &, const sipTypeDef* = NULL, size_t = 0);
        template < typename T > void deleteStorage(const option_value &);
};
%End

%ModuleCode
#include "gromacs/utility/gmxassert.h"

const char* PyOptionsHolder::DuplicateOption::what() const noexcept {
    return "This option is already defined";
}

PyOptionsHolder::StringList::StringList(const std::vector < std::string > *vector) :
    list(NULL), size(vector->size()), vector(vector)
{}

PyOptionsHolder::StringList::StringList(const std::string *list, size_t size) :
    list(list), size(size), vector(NULL)
{}

const char* PyOptionsHolder::StringList::operator[] (size_t i) {
    if (i >= size)
    {
        return NULL;
    }
    return vector ? (*vector)[i].data() : list[i].data();
}

template < typename T, typename U > U PyOptionsHolder::createStorage(const char *name, const char *type, int count, const T *def)
{
    if (storage.count(name))
    {
        throw DuplicateOption();
    }

    U option(name);

    option_value value;
    value.type  = type;
    value.count = new int;
    value.name  = name;

    if (count == 0)   // std::vector of values
    {
        auto *store = new std::vector < T > ();
        option.storeVector(store);
        option.multiValue();
        option.storeCount(value.count);

        *value.count = 0;
        if (def)
        {
            store->push_back(*def);
            *value.count = 1;
        }

        value.value  = store;
        value.vector = true;
    }
    else     // exactly `count` values
    {
        auto *store = new T[count];
        if (def)
        {
            store[0] = *def;
        }

        option.store(store);
        if (count > 1)
        {
            option.valueCount(count);
        }

        value.value  = store;
        value.vector = false;
        *value.count = count;
    }

    storage[name] = value;
    return option;
}

gmx::DoubleOption PyOptionsHolder::doubleOption(const char *name, size_t count, double *def)
{
    gmx::DoubleOption option = createStorage < double, gmx::DoubleOption > (name, "d", count, def);

    return option;
}

gmx::IntegerOption PyOptionsHolder::integerOption(const char *name, size_t count, int *def)
{
    gmx::IntegerOption option = createStorage < int, gmx::IntegerOption > (name, "i", count, def);

    return option;
}

gmx::StringOption PyOptionsHolder::stringOption(const char *name, size_t count, const char* def)
{
    std::string *s_def = NULL;
    if (def)
    {
        s_def = new std::string(def);
    }

    gmx::StringOption option = createStorage < std::string, gmx::StringOption > (name, "A", count, s_def);
    delete            s_def;

    return option;
}

// FIXME: Unify with the rest
gmx::BooleanOption PyOptionsHolder::booleanOption(const char *name, size_t count, bool def)
{
    if (storage.count(name))
    {
        throw DuplicateOption();
    }

    bool *store = new bool;
    *store = def;
    gmx::BooleanOption option(name);
    option.store(store);
    storage[name] = {store, "b"};

    return option;
}

gmx::SelectionOption PyOptionsHolder::selectionOption(const char *name, size_t count)
{
    gmx::SelectionOption option = createStorage < gmx::Selection, gmx::SelectionOption > (name, "S", count);

    return option;
}

gmx::FileNameOption PyOptionsHolder::fileNameOption(const char *name, size_t count)
{
    gmx::FileNameOption option = createStorage < std::string, gmx::FileNameOption > (name, "f", count);

    return option;
}

template < typename T > PyObject* PyOptionsHolder::buildValue(const char *sipType, const PyOptionsHolder::option_value &value, const sipTypeDef *td, size_t size)
{
    int count = *value.count;
    T  *store = !value.vector ? (T*) value.value : ((std::vector < T > *)value.value)->data();

    if (count == 1 && !value.vector)
    {
        if (td)
        {
            return sipConvertFromType(store, td, NULL);
        }
        else
        {
            return sipBuildResult(NULL, sipType, *store);
        }
    }
    else
    {
        if (td)
        {
            return sipConvertToTypedArray(store, td, NULL, size, count, SIP_READ_ONLY);
        }
        else
        {
            return sipConvertToArray(store, sipType, count, SIP_READ_ONLY);
        }
    }
}


PyObject* PyOptionsHolder::get_value(const char *name)
{
    if (!storage.count(name))
    {
        return NULL;
    }

    option_value v = storage[name];
    switch (*v.type)
    {
        case 'd': // double
            return buildValue < double > ("d", v);
            break;
        case 'i': // int
            return buildValue < int > ("i", v);
            break;
        case 'A': // std::string
        case 'f': // FileNameOption
            if (v.vector)
            {
                return sipConvertFromType(new PyOptionsHolder::StringList(((std::vector < std::string > *)v.value)), sipType_PyOptionsHolder_StringList, Py_None);
            }
            else if (*v.count == 1)
            {
                return sipBuildResult(NULL, "A", ((std::string*) v.value)->data());
            }
            else
            {
                return sipConvertFromType(new PyOptionsHolder::StringList((std::string*) v.value, *v.count), sipType_PyOptionsHolder_StringList, Py_None);
            }
            break;
        case 'b': // bool
            // TODO: support vector bool options
            return sipBuildResult(NULL, v.type, *((bool*) v.value));
            break;
        case 'S': // Selection
            return buildValue < gmx::Selection > (NULL, v, sipType_Selection, sizeof(gmx::Selection));
            break;
    }

    GMX_ASSERT(false, "Some type is not handled in PyOptionsHolder.get_value");
    return NULL;
}

template < typename T > void PyOptionsHolder::deleteStorage(const PyOptionsHolder::option_value &value)
{
    if (value.vector)
    {
        delete (std::vector < T > *) value.value;
    }
    else
    {
        delete[] (T*) value.value;
    }

    delete value.count;
}

PyOptionsHolder::~PyOptionsHolder()
{
    for (auto e : storage)
    {
        switch (*e.second.type)
        {
            case 'd': // double
                deleteStorage < double > (e.second);
                break;
            case 'i': // int
                deleteStorage < int > (e.second);
                break;
            case 'A': // std::string
            case 'f': // FileNameOption (the storage type is still std::string)
                deleteStorage < std::string > (e.second);
                break;
            case 'b': // bool
                delete (bool*) e.second.value;
                break;
            case 'S': // Selection
                deleteStorage < gmx::Selection > (e.second);
                break;
        }
    }
}
%End

%Exception PyOptionsHolder::DuplicateOption {
    %RaiseCode
    SIP_BLOCK_THREADS;
    PyErr_SetString(PyExc_ValueError, sipExceptionRef.what());
    SIP_UNBLOCK_THREADS;
    %End
};

class PyOptionsHolder {
    %TypeHeaderCode
#include "gromacs/options/basicoptions.h"
    %End

    public:
        class StringList /NoDefaultCtors/ {
            public:
                const char* operator[] (int);
                %MethodCode
                sipRes = (*sipCpp)[a0];

                if (!sipRes)
                {
                    SIP_BLOCK_THREADS;
                    PyErr_SetString(PyExc_IndexError, "Index out of range");
                    SIP_UNBLOCK_THREADS;
                    sipIsErr = 1;
                }
                %End
        };
        // These methods are given twice to workaround sip setting 0 for when '*def = NULL' option is not given
        DoubleOption doubleOption(const char *name /KeepReference/, int count = 1) throw (PyOptionsHolder::DuplicateOption);
        DoubleOption doubleOption(const char *name /KeepReference/, int count, const double *def) throw (PyOptionsHolder::DuplicateOption);

        IntegerOption integerOption(const char *name /KeepReference/, int count = 1) throw (PyOptionsHolder::DuplicateOption);
        IntegerOption integerOption(const char *name /KeepReference/, int count, const int *def) throw (PyOptionsHolder::DuplicateOption);

        StringOption stringOption(const char *name /KeepReference/, int count = 1) throw (PyOptionsHolder::DuplicateOption);
        StringOption stringOption(const char *name /KeepReference/, int count, const char *def) throw (PyOptionsHolder::DuplicateOption);

        BooleanOption booleanOption(const char *name /KeepReference/, int count = 1, bool def = 0) throw (PyOptionsHolder::DuplicateOption);

        SelectionOption selectionOption(const char *name /KeepReference/, int count = 1) throw (PyOptionsHolder::DuplicateOption);

        FileNameOption fileNameOption(const char *name /KeepReference/, int count = 1) throw (PyOptionsHolder::DuplicateOption);
        SIP_PYOBJECT __getitem__(const char *name);
        %MethodCode
        sipRes = sipCpp->get_value(a0);

        if (!sipRes)
        {
            SIP_BLOCK_THREADS;
            PyErr_SetString(PyExc_KeyError, "Invalid option name");
            SIP_UNBLOCK_THREADS;
            sipIsErr = 1;
        }
        %End
};
