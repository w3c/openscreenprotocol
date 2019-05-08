# Discovery Protocol Benchmarks

The goal of this benchmark design is to create a controlled environment in which
we can gather data on performance, efficiency, and reliability of the two
network discovery protocols proposed for Open Screen:

* [SSDP](../archive/ssdp.md)
* [mDNS](../archive/mdns.md)

# Observables

* Network efficiency & utilization
  * Number of packets sent and received per device per minute
  * Number of bytes sent and received per device per minute
  * Total number of packets and bytes sent per minute
  * Peak number of packets and bytes sent per second
* Power efficiency
  * Total mW consumed per minute per device
* Reliability
  * Percentage of devices found after 10s, 30s, 60s
* Latency
  * Time to find all devices
  * Time to discover that a device has been connected
  * Time to discover that a device has been disconnected

# Test Environment

## Hardware and Operating System

The test environment will consist of 10
[Raspberry Pi 2 Model B](https://www.adafruit.com/product/2358)
single-board computers with:
* ARM Cortex-A53 1.2 GHz quad-core processor
* 1 GB RAM
* 802.11 b/g/n wireless LAN module (via USB)

These are similar to Android One smartphones and slightly more powerful than
previous generation streaming devices (see [Device Specs](../device_specs.md)).

The default operating system for Raspberry Pi devices is
[Raspbian](https://www.raspberrypi.org/downloads/raspbian/), which is
Linux-based.  The "Lite" version should be sufficient as we don't need an
interactive OS.

## Networking

The test devices will be connected via a 802.11/n, 2.4 GHz WiFi network secured
by WPA2-PSK and provided by an off the shelf, basic home Wi-Fi router.

Typical models:
* [Netgear N300](https://www.netgear.com/home/products/networking/wifi-routers/WNR3500L.aspx)
* [TP-Link TL-WR841N](http://www.tp-link.com/us/products/details/cat-5506_TL-WR841N.html)
* [ASUS RT-N12 D1](https://www.asus.com/us/Networking/RTN12_D1/)
* [Zyxel NBG-418N v2](http://www.zyxel.com/us/en/products_services/Wireless-N300-Home-Router-NBG-418N-v2/)

For the sake of reproducibility, we will re-run benchmarks with multiple router
models to see if there is any signficant variation in results.

## Software

For mDNS, we will use the [Avahi](https://www.avahi.org/) open source mDNS
software that is available as a Debian package.

For SSDP, we will either:

1. Fork and customize [libupnp](http://pupnp.sourceforge.net/) for the
[Open Screen SSDP discovery protocol](../archive/ssdp.md).
2. Write our own SSDP implementation from scratch, possibly based on the
[Chromium](https://cs.chromium.org/chromium/src/chrome/browser/media/router/discovery/dial/dial_service.h)
implementation or the [Fraunhofer FOKUS](https://github.com/fraunhoferfokus/peer-ssdp/blob/master/lib/peer-ssdp.js)
SSDP implementation based on Node.js.

As part of these implementations, we will instrument them to log data related to
the Observables above, including (but not limited to):
* Packets and bytes sent and received each second
* Timestamp a device is discovered
* Timestamp a device is detected to have left the network
* Number of devices discovered

A Python script will be used to start the sender and responder process with
command line flags to adjust behavior for a given test condition. Data points of
interest will be logged by the binaries to stdout, which will be injested and
accumulated by the Python script.  At the end of the test, the script will write
a JSON file to be copied to a Web server, so that a HTML frontend can be used to
render nice charts of the results.  All of the scripts and source code for the
benchmarks will be stored on GitHub.

# Experimental Variables

The following variables will be adjusted and the Observables collected for each
condition.

To keep the number of conditions within reason, one set of parameters will be
adjusted and the others kept fixed.  In case the data shows interesting trends,
we can run more conditions as desired as the entire process will be automated
through scripting.

## Protocols in use

* SSDP alone
* mDNS alone
* SSDP and mDNS together

## Device Population

* Number of senders (devices initiating queries): 1, 2, 4, 8
* Number of responders (devices responding to queries): 1, 2, 4, 8

## Physical Positioning

Most benchmarks will take place with the devices co-located (same room, same
distance from router).

However, to simulate signal fading effects, we will also collect data when the
devices will be positioned in adjacent offices such that the senders are in one
room separated by a wall from the router, and the responders are in a different
room separated by a wall from the router.  This is to simulate a typical
household where controller devices, receiver devices, and routers are spread
among different rooms.

**NOTE:** If there is interest in evaluating these protocols in particularly
adverse WiFi conditions, we can investigate using a routing proxy to simulate
additional congestion and packet loss, or simply move devices further away.

## SSDP specific

* Interval between `M-SEARCH` requests.
* Value of `MX` which is the maximum delay in an `M-SEARCH` response.

## mDNS specific

* TTL assigned to mDNS answers.

# Data Collection And Analysis

For numerical values, data will be collected for a given experimental condition
N = 30 times and the 50%, 75%, and 95% values computed, as well as time series.

One experimental condition (the control) will have no senders or responders to
collect baseline data.

# Notes / Future Work

## Mobile Device Benchmarking

Power consumption measurement only makes sense as a relative measurement, and
depends heavily on the power saving capabilities of a specific device.  We need
to revisit this by designing power benchmarks that can be run on mobile phones and
mobile OSes (Android, iOS).  As a first approximation we can allow discovery to run
to a steady state and look at the resulting battery level.

[Issue #72](https://github.com/webscreens/openscreenprotocol/issues/72):
Investigate power consumption measurement

### SSDP

For benchmarking on mobile devices (e.g., for power consumption), the
[Fraunhofer FOKUS Cordova Plugin](https://github.com/fraunhoferfokus/cordova-plugin-hbbtv/tree/master/src/android/ssdp)
can be used as an SSDP responder.

## Steady State Benchmarks

The benchmarks proposed here are intended to run over the course of several minutes,
until discovery hits a "steady state" and no new devices are discovered.  Benchmarks
of network efficiency over the course of hours would also be informative, as most of
the time devices on a network exist in a steady state.  For these benchmarks,
different protocol-specific parameters may need to be investigated like `CACHE-CONTROL`
for SSDP.



