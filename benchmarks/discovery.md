# Discovery Protocol Benchmarks

The goal of this benchmark design is to create a controlled environment in which
we can gather data on performance, efficiency, and reliability of the two
network discovery protocols proposed for Open Screen:

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

These are similar to Android One smartphones and slightly more powerful than
previous genration streaming devices (see [Device Specs](../device_specs.md)).

The default operating system for Raspberry Pi devices is
[Raspbian](https://www.raspberrypi.org/downloads/raspbian/), which is
Linux-based.  The "Lite" version syhould be sufficient as we don't need an
interactive OS.

## Networking

The test devices will be connected via a 802.11/n, 2.4 GHz network using
WPA2-PSK security using an off the shelf home Wi-Fi router.

**TODO**: Specify make/model/firmware

For the sake of reproducibility, we can re-run the benchmarks with multiple
router models to see if there is any sensitivity.

## Software

For mDNS, we will use the Avahi open source mDNS software that is available as a
Debian package.

For SSDP, we will write a small wrapper around libupnp, and may fork it to
disable unnecessary services and customize SSDP for the [Open Screen SSDP
discovery protocol](../ssdp.md).

We will determine if we can collect the relevant observables by collecting
OS-level data about network behavior and the log output of these processes.  If
not, we will fork them to add the necessary instrumentation.

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
depends heavily on the power saving capabilities of a specific device.  We may
revisit this by designing power benchmarks that run on mobile phones or tablets.


