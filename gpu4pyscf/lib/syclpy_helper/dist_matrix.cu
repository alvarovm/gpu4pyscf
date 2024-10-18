/* Copyright 2023 The GPU4PySCF Authors. All Rights Reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <sycl/sycl.hpp>
#include <stdio.h>
#define THREADS        32

__attribute__((always_inline))
static void _calc_distances(double *dist, const double *x, const double *y, int m, int n)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    if (i >= m || j >= n){
        return;
    }

    double dx = x[3*i]   - y[3*j];
    double dy = x[3*i+1] - y[3*j+1];
    double dz = x[3*i+2] - y[3*j+2];
    dist[i*n+j] = norm3d(dx, dy, dz);
}

extern "C" {
int dist_matrix(sycl::queue& stream, double *dist, const double *x, const double *y, int m, int n)
{
    int ntilex = (m + THREADS - 1) / THREADS;
    int ntiley = (n + THREADS - 1) / THREADS;
    dim3 threads(THREADS, THREADS);
    dim3 blocks(ntilex, ntiley);
    _calc_distances<<<blocks, threads, 0, stream>>>(dist, x, y, m, n);
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        return 1;
    }
    return 0;
}
}
