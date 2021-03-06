module Data

import SIT.Acquisition
import SIT.Grid
import SIT.Coupling
using Interpolations

"""
time domain representation of Seismic Data
TODO: Also include acqsrc?

# Fields
* `d` : data first sorted in time, then in receivers, and finally in sources
* `nfield` : number of components
* `tgrid` : `M1D` grid to represent time
* `acqgeom` : acquisition geometry
"""
type TD
	d::Array{Array{Float64,2},2}
	nfield::Int64
	tgrid::Grid.M1D
	acqgeom::Acquisition.Geom
end


"""
function to resample data in time domain

# Arguments
* `data` : input data of type `TD`
* `tgrid` : resampling in time according to this time grid
"""
function TD_resamp(data::TD,
		tgrid::Grid.M1D
		)
	nss = data.acqgeom.nss
	nr = data.acqgeom.nr
	dataout = TD(
	      [zeros(tgrid.nx,data.acqgeom.nr[iss]) for iss=1:nss, ifield=1:data.nfield],
	      data.nfield,tgrid,data.acqgeom)
	for ifield = 1:data.nfield, iss = 1:nss, ir = 1:nr[iss]
		itp = interpolate((data.tgrid.x,),
		    data.d[iss, ifield][:, ir], 
			     Gridded(Linear()))
		dataout.d[iss, ifield][:,ir] = itp[tgrid.x]
	end
	return dataout
end

"""
Return zeros
"""
function TD_zeros(nfield::Int64,
		 tgrid::Grid.M1D,
		 acqgeom::Acquisition.Geom
		 )
	return TD([zeros(tgrid.nx,acqgeom.nr[iss]) for iss=1:acqgeom.nss, ifield=1:nfield],
    				nfield,tgrid,acqgeom)
end

"""
Check if zeros
"""
function TD_iszero(data::TD)
	return maximum(broadcast(maximum,broadcast(abs,data.d))) == 0.0 ? true : false
end

"""
Returns dot product of the data
"""
function TD_dot(data1::TD, data2::TD)
	dotd = 0.0;
	for ifield = 1:data1.nfield, iss = 1:data1.acqgeom.nss, ir = 1:data1.acqgeom.nr[iss]
		dotd += dot(data1.d[iss, ifield][:, ir],data2.d[iss, ifield][:, ir])
	end
	return dotd
end


"""
normalize time-domain seismic data
"""
function TD_normalize(data::TD, attrib::Symbol)
	nr = data.acqgeom.nr;	nss = data.acqgeom.nss;	nt = data.tgrid.nx;
	datan = deepcopy(data);
	for ifield = 1:data.nfield, iss = 1:nss, ir = 1:nr[iss]
		if(attrib == :recrms)
			nval = sqrt(mean(datan.d[iss, ifield][:,ir].^2.))
		elseif(attrib == :recmax)
			nval = maximum(datan.d[iss, ifield][:,ir])
		else
			error("invalid attrib")
		end

		# normalize
		datan.d[iss, ifield][:, ir] = 
		isequal(nval, 0.0) ? zeros(nt) : datan.d[iss, ifield][:, ir]./nval  
	end
	return datan
end

"""
Construct TD using data at all the unique receiver positions
for all supersources.
"""
function TD_urpos(d::Array{Float64}, 
		   nfield::Int64, 
		   tgrid::Grid.M1D, 
		   acq::Acquisition.Geom,
		   nur::Int64,
		   urpos::Tuple{Array{Float64,1},Array{Float64,1}
		  }
		   )
	dout = [zeros(tgrid.nx,acq.nr[iss]) for iss=1:acq.nss, ifield=1:nfield] 

	for ifield=1:nfield, iss=1:acq.nss, ir=1:acq.nr[iss]
		# find index in urpos
		irr=find([[urpos[1][i]-acq.rz[iss][ir],
		       urpos[2][i]-acq.rx[iss][ir]] == [0., 0.,] for i in 1:nur])

		dout[iss, ifield][:,ir] = d[:,irr[1],iss,ifield] 
	end

	return TD(dout, nfield, tgrid, acq)

end

"""
Apply SR to TD
"""
function TDcoup(
	       r::TD,
	       w::Coupling.TD,
	       )
	nr = r.acqgeom.nr;	nss = r.acqgeom.nss;	nt = r.tgrid.nx;
	s =  deepcopy(r)
	for ifield = 1:data.nfield, iss = 1:nss, ir = 1:nr[iss]
		# receiver coupling
	#	DSP.fast_filt!(s.d[iss, ifield][:, ir],r.d[iss, ifield][:, ir],
#		 w.rf[iss, ifield][:,ir],:s)
		# source coupling
		DSP.fast_filt!(s.d[iss, ifield][:, ir],r.d[iss, ifield][:, ir],
		 w.ssf[iss, ifield][:],:s)
	end
end # TDcoup


end # module
