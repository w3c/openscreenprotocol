# Discovery Protocol Evaluation

The goal of this experiment is to create a controlled environment in which we
can gather data on performance, efficiency, and reliability of the two network
discovery protocols proposed for Open Screen:

* [SSDP](../ssdp.md)
* [mDNS](../mdns.md)

# Observables

* Network efficiency
  * Number of packets sent and received per device per minute
  * Number of bytes sent and received per device per minute
  * Total number of packets transmitted per minute
  * Total number of bytes transmitted per minute
* Power efficiency
  * Total mW consumed per minute per device
* Reliability
  * Percentage of devices found
* Latency
  * Time to find all devices
  * Time to discover a device after it is connected
  * Time to remove a device after it is disconnected
  
# Test Environment


## Hardware and Operating System

The test environment will consist of 10
[Raspberry Pi 2 Model B](https://www.adafruit.com/product/2358)
single-board computers with:
* ARM Cortex-A53 1.2 GHz quad-core processor
* 1 GB RAM
* 802.11 b/g/n wireless LAN module (via USB)

## Networking

## Software

# Experimental Variables

## Device Population

## Network Quality

## SSDP specific

## mDNS specific

# Data Collection

For numerical values, data will be collected for a given experimental condition
N = 100 times and the 50%, 75%, and 95% values computed.

One experimental condition (the control) will have no senders or responders to
collect baseline data.

# Notes

Power consumption measurement only makes sense as a relative measurement, and
depends heavily on the power saving capabilities of a specific device.  To 




