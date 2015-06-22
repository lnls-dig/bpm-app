[![Build
Status](https://travis-ci.org/lnls-dig/bpm-sw-app.svg)](https://travis-ci.org/lnls-dig/bpm-sw-app)

# Beam Position Monitor Application Software/Gateware

Repository containing all of the third-party libraries needed by with our
Software, as well as Gateware and client applications.

## Instructions

### Server

For server installation with AFCv3 boards, typically a CPU within a microTCA.4
crate, do the following command:

    sudo ./get-all.sh server afcv3

This will download/compile/install all the dependencies needed, as well as the
BPM-SW application, which takes care of initializing and controlling the AFCv3
boards inside the microTCA.4 crate.

#### Configuration files

By default, the LNLS configuration file is installed in the system BPM-SW
configuration directory “${PREFIX}/etc/bpm_sw/bpm_sw.cfg”, with PREFIX being
/usr/local, by default. However, you can customize the file if wanted.

Also, you can have a crude configuration file, located inside the bpm-sw
repository under “cfg/crude_config/bpm_sw.cfg”. To install it, just copy it to
the system BPM-SW configuration directory.

#### System integration

For system integration, we have two options. The first one is an upstart
script, for Ubuntu-based distributions, located inside the bpm-sw repository
under “scripts/bpm-sw.conf”. The second option is a systemd script, for Fedora,
Arch-Linux, RHEL, and many others. This is located under
“scripts/bpm-sw.service”.

The process of installing the scripts are manual, for now, and rely on copying
the file to the appropriate place and enabling the service.

#### Upstart jobs

For upstart jobs, just copy the .conf script to “/etc/init/” and call “initctl
reload-configuration” to enable the service to run at boot.

#### Systemd services

For systemd services, just copy the .service script to “/etc/systemd/system/”
and call “systemctl enable bpm-sw”.

#### Log

By default, all of the logs are not handled by the system log, typically
syslog, but by a custom engine that writes messages to an specified directory
in the configuration file, under the hierarchy /dev_mngr/log/dir. By default,
this is set to “/media/remote_logs”, but can be changed if needed. Bare in mind
that the systemd script expects this mount point to be available before
starting the service. So, if needed, change the systemd script and/or config
file.

The BPM-SW application will write log files under the specified directory for
each board (AFCv3 or RFFE). So, for instance, if our system is composed of 4
AFCv3 and 8 RFFE boards, we will have 12 logs.

The logs also have the following standard naming convention for DEVIOs:

    dev_io<board_number>_<devio_type><instance_number>.log

And the following naming convention for DEV_MNGRs:

    dev_mngr.log

### Client

For client installation with AFCv3 boards, do the following command:

    sudo ./get-all.sh client afcv3

This will download/compile/install all the dependencies needed, as well as the
BPM-SW-CLI application, which is a command-line interface (CLI) to the BPM-SW
server.

Typically, to use the CLI, you should do the following:

    client --endpoint tcp://<server_ip>:9999 --board <slot_number> --bpm \
    <bpm_number> <command>

In which the <server_ip> is the server IP address, <slot_number> is the
microTCA.4 slot number in which the AFC is located, <bpm_number> is the up
(i.e., 0) or bottom (i.e., 1) position on the AFC.

As an example, we could read the current Kx value from the server, with:

    client --endpoint tcp://10.2.117.47:9999 --board 9 --bpm 1 --getkx

And the output should be something like:

```
INFO : [15-06-22 14:50:54] [libclient] Spawing LIBBPMCLIENT with broker address
            tcp://10.2.117.47:9999, with logfile on NULL ...
INFO : [15-06-22 14:50:54] [libclient] BPM Client version 0.1.0, Build by:
            Lucas Russo, Jun 22 2015 12:14:11
dsp_set_get_kx: 10000000
```

A very common operation on the BPM-SW is data acquisition. To perform an
acquisition do the following:

    client --endpoint tcp://10.2.117.47:9999 --board 9 --bpm 1 --setsamples 10 \
        --setchan 0 --acqstart --getcurve

And the output should be something like for the FMC130 MSPS board with a
sinusoidal wave:

```
INFO : [15-06-22 14:47:35] [libclient] Spawing LIBBPMCLIENT with broker
            address tcp://10.2.117.47:9999, with logfile on NULL ...
INFO : [15-06-22 14:47:35] [libclient] BPM Client version 0.1.0, Build by:
            Lucas Russo, Jun 22 2015 12:14:11
     597	      642	     3061	     3796
    6507	     6703	     6297	     6518
    1513	     1462	    -1237	    -1723
   -6216	    -6518	    -6710	    -6835
   -2830	    -2940	     -404	      278
    5343	     5538	     6437	     6935
    4498	     4575	     2223	     1894
   -4240	    -4509	    -6064	    -6477
   -5430	    -5669	    -3752	    -3343
    2743	     2891	     4877	     5570
[client:acq]: bpm_acq_get_curve was successfully executed
```

It’s important to note that the command is internally composed of three parts.

1. Setting the acquisition parameters: (--setsamples) number of samples and
    (--setchan) acquisition channel number
2. Starting the acquisition: (--acqstart)
3. Retrieving the data from the server: (--getcurve)

The first step sets some parameters in the BPM-SW server in order to prepare
for an upcoming acquisition.

The second step triggers the acquisition with the previously set parameters.
For now, only immediate trigger is available. In the future, external hardware
trigger and a data-driven trigger are planned.

The third step retrieves all of the successfully acquired samples from the
BPM-SW server.

It’s also possible to perform the acquisition in different ways. For instance,
you could want to acquire an acquisition and wait for a maximum number of
seconds before giving up waiting:

    client --endpoint tcp://10.2.117.47:9999 --board 9 --bpm 1 --setsamples 10 \
        --setchan 0 --fullacq --timeout 5

The previous example perform an acquisition on board 9, bpm 1, of 10 samples
of the channel 0 and waiting up to 5 seconds before giving up.

Another interesting example is to just retrieving some data blocks from a
previous acquisition:

    client --endpoint tcp://10.2.117.47:9999 --board 9 --bpm 1 --setsamples 10 \
        --setchan 0 --getblock 0

The previous example perform does not actively starts an acquisition. Instead,
it just reads the stored data for the specified channel and number of samples.

Bear in mind that the block size is implementation specific and you can only
specify the block number and the amount of samples within this same block, not
a variable offset from the beginning of the acquired data. This behavior should
be changed in future releases, as it is cumbersome to use.

Another useful functionality is to check if an acquisition has finished. Note
that in general you don’t need this, as the --getcurve and --fullacq options
already does this implicit.

To check if a previous acquisition has finished:

    client --endpoint tcp://10.2.117.47:9999 --board 9 --bpm 1 --acqcheck

The output should be something like:

```
INFO : [15-06-22 15:15:45] [libclient] Spawing LIBBPMCLIENT with broker
            address tcp://10.2.117.47:9999, with logfile on NULL ...
INFO : [15-06-22 15:15:45] [libclient] BPM Client version 0.1.0, Build by:
            Lucas Russo, Jun 22 2015 12:14:11
TRACE: [15-06-22 15:15:45] [libclient] bpm_acq_check: Check ok: data acquire
            was successfully completed
```

To continuously check if a previous acquisition has finished, up to an
specified timeout:

    client --endpoint tcp://10.2.117.47:9999 --board 9 --bpm 1 --acqcheckpoll \
            --timeout 5


The previous example continuously checks for completion up to 5 seconds and
then gives up if the acquisition is not completed in this time window.
