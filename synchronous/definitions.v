`define OFF 1'b0
`define ON  1'b1

`define BIT_DATA  8
`define THRESHOLD 70

`define CONV2D_KSIZE 9 // 3x3
`define MAX2D_KSIZE  4 // 2x2
`define DENSE_KSIZE  10 // 1x10

`define ADDRT 22
`define BIT_W `BIT_DATA * 16384
`define BIT_I 72
`define BIT_O 4

`define FILTER_IN  1
`define FILTER_L0  32
`define FILTER_L1  32
`define FILTER_L2  32
`define FILTER_L3F 128
`define FILTER_L4F 1024
`define FILTER_L5F 1024

`define PIXEL_IN  28
`define PIXEL_L0  26
`define PIXEL_L1  24
`define PIXEL_L2  12
`define PIXEL_L3F 10
`define PIXEL_L4F 8
`define PIXEL_L5F 4

`define IN_INL0   `CONV2D_KSIZE * `FILTER_IN
`define IN_L0B0   `FILTER_L0
`define IN_B0L1   `CONV2D_KSIZE * `IN_L0B0
`define IN_L1B1   `FILTER_L1
`define IN_B1L2   `MAX2D_KSIZE  * `IN_L1B1
`define IN_L2B2   `FILTER_L2
`define IN_B2L3F  `CONV2D_KSIZE * `IN_L2B2
`define IN_L3FB3F `FILTER_L3F
`define IN_B3FL4F `CONV2D_KSIZE * `IN_L3FB3F
`define IN_L4FB4F `FILTER_L4F
`define IN_B4FL5F `MAX2D_KSIZE  * `IN_L4FB4F
`define IN_L5FB5F `FILTER_L5F
`define IN_B5FL6F 16384
`define IN_B2L3E  4608

`define BIT_SOFTMAX (2 ** `BIT_DATA) + $clog2(`DENSE_KSIZE - 1)

`define BIT_INL0   `BIT_DATA * `FILTER_IN * `CONV2D_KSIZE
`define BIT_L0B0   `BIT_DATA * `FILTER_L0
`define BIT_B0L1   `BIT_L0B0 * `CONV2D_KSIZE
`define BIT_L1B1   `BIT_DATA * `FILTER_L1
`define BIT_B1L2   `BIT_L1B1 * `MAX2D_KSIZE
`define BIT_L2B2   `BIT_DATA * `FILTER_L2
`define BIT_B2L3F  `BIT_L2B2   * `CONV2D_KSIZE
`define BIT_L3FB3F `BIT_DATA   * `FILTER_L3F
`define BIT_B3FL4F `BIT_L3FB3F * `CONV2D_KSIZE
`define BIT_L4FB4F `BIT_DATA   * `FILTER_L4F
`define BIT_B4FL5F `BIT_L4FB4F * `MAX2D_KSIZE
`define BIT_L5FB5F `BIT_DATA   * `FILTER_L5F
`define BIT_B5FL6F `BIT_DATA * 2 + $clog2(IN_B5FL6F - 1)
`define BIT_B2L3E  `BIT_DATA * 2 + $clog2(IN_B5FL6F - 1)
`define BIT_RLRE   `BIT_SOFTMAX * DENSE_KSIZE

`define BIT_S0  $clog2(`BIT_DATA + $clog2(`CONV2D_KSIZE - 1))
`define BIT_S1  $clog2(`BIT_DATA + $clog2(`CONV2D_KSIZE * `FILTER_L0 - 1))
`define BIT_S3F $clog2(`BIT_DATA + $clog2(`CONV2D_KSIZE * `FILTER_L2 - 1))
`define BIT_S3E $clog2(`BIT_DATA + $clog2(`IN_B2L3E - 1))
`define BIT_S4F $clog2(`BIT_DATA + $clog2(`CONV2D_KSIZE * `FILTER_L3F - 1))
`define BIT_S6F $clog2(`BIT_DATA + $clog2(`IN_B5FL6F - 1))
`define BIT_LW  6

// `define SIZE_IN  `FILTER_IN  * `PIXEL_IN  * `PIXEL_IN
// `define SIZE_L0  `FILTER_L0  * `PIXEL_L0  * `PIXEL_L0
// `define SIZE_L1  `FILTER_L1  * `PIXEL_L1  * `PIXEL_L1
// `define SIZE_L2  `FILTER_L2  * `PIXEL_L2  * `PIXEL_L2
// `define SIZE_L3F `FILTER_L3F * `PIXEL_L3F * `PIXEL_L3F
// `define SIZE_L4F `FILTER_L4F * `PIXEL_L4F * `PIXEL_L4F
// `define SIZE_L5F `FILTER_L5F * `PIXEL_L5F * `PIXEL_L5F

// `define BIT_L0  $clog2(`SIZE_IN  - 1) + 2 * `BIT_DATA
// `define BIT_L1  $clog2(`SIZE_L0  - 1) + 2 * `BIT_DATA
// `define BIT_L3F $clog2(`SIZE_L2  - 1) + 2 * `BIT_DATA
// `define BIT_L4F $clog2(`SIZE_L3  - 1) + 2 * `BIT_DATA
// `define BIT_L3E $clog2(`SIZE_L2  - 1) + 2 * `BIT_DATA
// `define BIT_L6F $clog2(`SIZE_L5F - 1) + 2 * `BIT_DATA
