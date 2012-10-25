## Copyright (C) 2012 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## Plot a flat lattice tiling generated by TestFlatLatticeTiling.
## Usage:
##   PlotFlatLatticeTiling(res, i, j, what, [paramx, paramy])
## where
##   res = results structure returned by TestFlatLatticeTiling()
##   i, j = dimensions to plot
##   what = string of characters which determines what to plot:
##     T: plot templates which have been hit
##     t: plot templates which have not been hit
##     E: plot metric ellipses of templates which have been hit
##     e: plot metric ellipses of templates which have not been hit
##     f: plot metric ellipses of templates which have been hit by non-covered templates
##     I: plot injections which are covered
##     i: plot injections which are not covered
##     N: plot lines from covered injections to their nearest template
##     n: plot lines from non-covered injections to their nearest template
##  paramx, paramy = parameter space bounds (optional)

function PlotFlatLatticeTiling(res, i, j, what, paramx=[], paramy=[])

  ## check input
  assert(isstruct(res));
  assert(!isempty(res.templates));
  assert(!isempty(res.injections));
  assert(!isempty(res.nearest_index));
  assert(!isempty(res.min_mismatch));
  assert(isscalar(i));
  assert(isscalar(j));
  assert(ischar(what));

  ## get indices of templates which have/have not been "hit" by an injection
  hit_kk = res.nearest_index;
  nohit_kk = setdiff(1:res.num_templates, hit_kk);

  ## get indices of injections which are/are not "covered" by a template
  cvr_kk = find(res.min_mismatch <= 1.0);
  nocvr_kk = setdiff(1:res.num_injections, cvr_kk);

  ## clear current figure and prepare for plotting
  clf;
  hold on;

  ## plot templates which have been hit
  if any(what == "T")
    plot(res.templates(i, hit_kk), res.templates(j, hit_kk), "bo");
  endif

  ## plot templates which have not been hit
  if any(what == "t")
    plot(res.templates(i, nohit_kk), res.templates(j, nohit_kk), "co");
  endif

  ## plot metric ellipses of templates which have been hit
  if any(what == "E")
    [x, y] = metricEllipsoid(res.metric([i,j], [i,j]), 1.0);
    for k = hit_kk
      plot(x + res.templates(i,k), y + res.templates(j,k), "b-");
    endfor
  endif

  ## plot metric ellipses of templates which have not been hit
  if any(what == "e")
    [x, y] = metricEllipsoid(res.metric([i,j], [i,j]), 1.0);
    for k = nohit_kk
      plot(x + res.templates(i,k), y + res.templates(j,k), "c-");
    endfor
  endif

  ## plot metric ellipses of templates which have been hit by non-covered templates
  if any(what == "f")
    [x, y] = metricEllipsoid(res.metric([i,j], [i,j]), 1.0);
    for k = hit_kk(nocvr_kk)
      plot(x + res.templates(i,k), y + res.templates(j,k), "b-");
    endfor
  endif

  ## plot injections which are covered
  if any(what == "I")
    plot(res.injections(i, cvr_kk), res.injections(j, cvr_kk), "kx");
  endif

  ## plot injections which are not covered
  if any(what == "i")
    plot(res.injections(i, nocvr_kk), res.injections(j, nocvr_kk), "rx");
  endif

  ## plot lines from covered injections to their nearest template
  if any(what == "N")
    x = [res.injections(i, cvr_kk); res.templates(i, hit_kk(cvr_kk)); nan(1, length(cvr_kk))];
    y = [res.injections(j, cvr_kk); res.templates(j, hit_kk(cvr_kk)); nan(1, length(cvr_kk))];
    plot(x(:), y(:), "k-");
  endif

  ## plot lines from non-covered injections to their nearest template
  if any(what == "n")
    x = [res.injections(i, nocvr_kk); res.templates(i, hit_kk(nocvr_kk)); nan(1, length(nocvr_kk))];
    y = [res.injections(j, nocvr_kk); res.templates(j, hit_kk(nocvr_kk)); nan(1, length(nocvr_kk))];
    plot(x(:), y(:), "r-");
  endif

  ## plot parameter space bounds, if given
  if !isempty(paramx) && !isempty(paramy)
    h = plot(paramx, paramy, "k-");
    set(h, "linewidth", 3 * get(h, "linewidth"));
  endif

  ## close plotting
  hold off;

endfunction
