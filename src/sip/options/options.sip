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

class OptionInfo /NoDefaultCtors/;

class IOptionManager /NoDefaultCtors/ {
    %TypeHeaderCode

#include <gromacs/options/options.h>
    using gmx::IOptionManager;
    %End

    protected:
        virtual ~IOptionManager();
};

class Options: public IOptionsContainer {
    %TypeHeaderCode

#include <gromacs/options/options.h>
    using gmx::Options;
    %End

    public:
        Options(const char *name, const char *title);
        void addManager (IOptionManager *manager);
        void addSubSection (Options *section);
        OptionInfo* addOption(const AbstractOption &settings);

        // No way to add it clearly - C++ returns reference, sip can't wrap it
        //IOptionsContainer *addGroup();

        void finish();
    private:
        Options(const Options &other);
};
