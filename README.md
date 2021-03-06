# High-Performance Asynchronous CNN Accelerator with Early Termination

PENDING paper submission to MCSOC 2022

My Masters Thesis is co-advised by [Dr. Teo Tee Hui](https://epd.sutd.edu.sg/people/faculty/teo-tee-hui), SUTD, and [Dr. Wey I-Chyn](https://ee.cgu.edu.tw/p/405-1083-564,c11454.php?Lang=en), CGU.

The topic of my thesis is on the hardware acceleration of a CNN with early termination function, via asynchronous technique.

## Motivation
Real-world environment, such as lighting and object orientation, can vary drastically, resulting in a changing difficulty for object recognition. This meant that a fixed-depth CNN model may not be suitable for all cases, where shallow network may not have sufficient parameters for difficult inference workload, or phenomenon such as over-fitting on deeper network affecting the accuracy in easier workload, and calls for a dynamic network.

Dynamic network can be made easier with early out branches, where one or more sub-network, consist of small dense layer and Softmax activation function, branches out from the main (and very deep) CNN network. The function of Softmax at the end of each sub-network is to determine if the particular depth is sufficient for the object recognition, where sufficient, the result will be generated from that sub-network and the remaining network will be terminated and freed to execute the next workload.

In hardware acceleration, asynchronous technique is used to reduce power consumption by allowing the memory elements in the deeper layers to remain idle, while the computation has yet reach, and in the event of early termination, remaining operations will not be executed, drastically reducing the dynamic energy consumption.

## Early Termination Model

The following model serves as an example to demonstrate my concept/idea, and is trained and quantised using [Tensorflow](https://www.tensorflow.org/), with [Mnist Fashion dataset](https://github.com/zalandoresearch/fashion-mnist).
 
![tf_graph_overview](https://github.com/lootr5858/master_thesis/blob/69872bdd97cd17967ba9b78947fcf1ef0892a5fa/resources/tf_grpah_overview.png)

*Figure 1. Early Termination CNN model generated using Tensorflow Graph*

## Hardware Implementation

All 3 architecture are written in Verilog and implemented via Xilinx's Vivado on ZCU102.
- Traditional : synchronous implementation with only main CNN network
- Proposal-1  : synchronous implementation of early termination CNN network
- Proposal-2  : asynchronous implementation of early termination CNN network

![triginal_architecture](https://github.com/lootr5858/master_thesis/blob/69872bdd97cd17967ba9b78947fcf1ef0892a5fa/resources/cnn_chip-traditional_architecture.drawio.png)
*Figure 2. Hardware Architecture for tradition CNN implementation (main network only, synchronous circuit)*

![proposal_1](https://github.com/lootr5858/master_thesis/blob/69872bdd97cd17967ba9b78947fcf1ef0892a5fa/resources/cnn_chip-proposal-1_architecture.drawio.png)
*Figure 3. Hardware Architecture for Proposal-1: Synchronous implementation with early termination*

![proposal_2](https://github.com/lootr5858/master_thesis/blob/69872bdd97cd17967ba9b78947fcf1ef0892a5fa/resources/cnn_chip-proposal-2_architecture.drawio.png)
*Figure 4. Hardware Architecture for Proposal-2: Asynchronous implementation with early termination*

## Results

Proposal-2 vs Traditional CNN hardware implementation:
- as much as 5 times faster (min delay)
- as much as 2.5 times lower power consumption (min power)
- 69% increase in LUTs used
- 43% increase in registers (reg) used

![delay_min](https://github.com/lootr5858/master_thesis/blob/f70bf49b42d542e96754be6f64dc8bec81ddcb6b/resources/delay_min.png)
*Figure 5. Min. delay comparison*

![delay_max](https://github.com/lootr5858/master_thesis/blob/f70bf49b42d542e96754be6f64dc8bec81ddcb6b/resources/delay_max.png)
*Figure 6. Max. delay comparison*

![power_min](https://github.com/lootr5858/master_thesis/blob/f70bf49b42d542e96754be6f64dc8bec81ddcb6b/resources/power_min.png)
*Figure 7. Min. power comparison*

![power_max](https://github.com/lootr5858/master_thesis/blob/f70bf49b42d542e96754be6f64dc8bec81ddcb6b/resources/power_max.png)
*Figure 8. Max. power comparison*

![area_lut](https://github.com/lootr5858/master_thesis/blob/f70bf49b42d542e96754be6f64dc8bec81ddcb6b/resources/area_lut.png)
*Figure 9. Area (LUT) comparison*

![area_reg](https://github.com/lootr5858/master_thesis/blob/f70bf49b42d542e96754be6f64dc8bec81ddcb6b/resources/area_reg.png)
*Figure 10. Area (Reg) comparison*

## Files & Folders
- Asychronous : Verilog files for Proposal-2 hardware implementation
- Synchronous : Verilog files for Proposal-1 hardware implementation
- Resources.  : Resources for readme
