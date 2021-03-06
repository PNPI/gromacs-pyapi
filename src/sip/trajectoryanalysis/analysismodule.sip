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

struct t_trxframe {

    %TypeHeaderCode
#include <gromacs/trajectory/trajectoryframe.h>
#include "numpy_conv.h"
    %End

    int         not_ok;
    bool         bDouble;
    int          natoms;
    bool         bTitle;
    const char  *title;
    bool         bStep;
    int          step;
    bool         bTime;
    double       time;
    bool         bLambda;
    bool         bFepState;
    double       lambda;
    int          fep_state;
    bool         bAtoms;
    t_atoms     *atoms;
    bool         bPrec;
    double       prec;
    bool         bX;

    SIP_PYOBJECT x /NoSetter/ {
        %GetCode
        sipPy = array2dToNumpy(sipCpp->natoms, 3, sipCpp->x);
        %End
    };
    bool         bV;
    SIP_PYOBJECT v /NoSetter/ {
        %GetCode
        sipPy = array2dToNumpy(sipCpp->natoms, 3, sipCpp->v);
        %End
    };
    bool         bF;
    SIP_PYOBJECT f /NoSetter/ {
        %GetCode
        sipPy = array2dToNumpy(sipCpp->natoms, 3, sipCpp->f);
        %End
    };
    bool         bBox;
    SIP_PYOBJECT box /NoSetter/ {
        %GetCode
        sipPy = array2dToNumpy(3, 3, sipCpp->box);
        %End
    };
    bool         bPBC;
    int          ePBC;
    bool         bIndex;
    SIP_PYOBJECT index /NoSetter/ {
        %GetCode
        sipPy = array1dToNumpy(sipCpp->natoms, sipCpp->index);
        %End
    };
};

struct t_pbc {

    %TypeHeaderCode
#include <gromacs/pbcutil/pbc.h>
#include "numpy_conv.h"
    %End
    int ePBC;
    int          ndim_ePBC;
    int          ePBCDX;
    int          dim;
    SIP_PYOBJECT box /NoSetter/ {
        %GetCode
        sipPy = array2dToNumpy(3, 3, sipCpp->box);
        %End
    };
    SIP_PYOBJECT fbox_diag /NoSetter/ {
        %GetCode
        sipPy = array1dToNumpy(3, sipCpp->fbox_diag);
        %End
    };
    SIP_PYOBJECT hbox_diag /NoSetter/ {
        %GetCode
        sipPy = array1dToNumpy(3, sipCpp->hbox_diag);
        %End
    };
    SIP_PYOBJECT mhbox_diag /NoSetter/ {
        %GetCode
        sipPy = array1dToNumpy(3, sipCpp->mhbox_diag);
        %End
    };
    double max_cutoff2;
    int    ntric_vec;
    /*ivec tric_shift[MAX_NTRICVEC];*/
    /*rvec tric_vec[MAX_NTRICVEC];*/
};

class AnalysisDataParallelOptions /NoDefaultCtors/ {
    %TypeHeaderCode
#include <gromacs/analysisdata/paralleloptions.h>
    %End
    public:
        AnalysisDataParallelOptions();
};

class TrajectoryAnalysisModuleDataPointer;
class TrajectoryAnalysisModuleData /NoDefaultCtors/ {
    %TypeHeaderCode
#include <gromacs/trajectoryanalysis/analysismodule.h>
    using namespace gmx;
    %End

    public:
        virtual void finish() = 0;
};

class TrajectoryAnalysisModulePointer;
class TrajectoryAnalysisModule /VirtualErrorHandler = vehandler/ {
    %TypeHeaderCode
#include <gromacs/trajectoryanalysis/analysismodule.h>
    using namespace gmx;
    %End
    public:
        virtual void initOptions(IOptionsContainer *options, TrajectoryAnalysisSettings *settings) = 0;
        virtual void optionsFinished(TrajectoryAnalysisSettings *settings);
        virtual void initAnalysis(const TrajectoryAnalysisSettings &settings, const TopologyInformation &top) = 0;
        virtual void initAfterFirstFrame(const TrajectoryAnalysisSettings &settings, const t_trxframe &fr);
        // Discarding the virtual for now
        std::unique_ptr < TrajectoryAnalysisModuleData > startFrames (const AnalysisDataParallelOptions &opt, const SelectionCollection &selections);
        virtual void analyzeFrame(int frnr, const t_trxframe &fr /NoCopy/, t_pbc *pbc, TrajectoryAnalysisModuleData *pdata ) = 0;
        virtual void finishFrames(TrajectoryAnalysisModuleData *pdata);
        virtual void finishAnalysis(int nframes) = 0;
        virtual void writeOutput()               = 0;
        int datasetCount() const;
        void finishFrameSerial(int frameIndex);
        AbstractAnalysisData &datasetFromIndex(int index) const;
        AbstractAnalysisData &datasetFromName(const char *name) const;
    protected:
        TrajectoryAnalysisModule();
    private:
        TrajectoryAnalysisModule(const TrajectoryAnalysisModule &other);
};
