# XR6.0.0 GPB Telemetry

This folder contains the .proto and .map files needed to stream and decode a selection of commonly used data from NCS5500 routers running IOS XR version 6.0.0. 

Streaming telemetry data over GPB involves the following stages:

1. Create a policy file listing the data to stream and associated cadences. Copy this to the /telemetry/policies/ directory on the router
2. Pick the appropriate .map files from this repository and copy these to the /telemetry/gpb/maps/ directory on the router
3. Configure the router
4. Use the .proto files from this repository to decode the data at the collector.

## Available schema paths

The following table shows the XR schema paths for which .proto and .map files are available in this repository, along with the MIB which most closely corresponds to them (there is no 1-1 mapping)

 Description | Schema Path in Policy File | .proto & .map filename | Corresponding MIB(s)
 ----------- | -------------------------- | ---------------------- | --------------------
 BGP neighbour data for all neighbors using default instance. Other instances amy be chosen. | RootOper.BGP.Instance({'InstanceName': 'default'}).InstanceActive.DefaultVRF.Neighbor(*) | bgp_neighbor | BGP4-MIB, CISCO-BGP4-MIB
 Ingress QoS counters | RootOper.QOS.Interface(*).Input.Statistics | qos_input_statistics | CISCO-CLASS-BASED-QOS-MIB
 Egress QoS counters | RootOper.QOS.Interface(*).Output.Statistics | qos_output_statistics | CISCO-CLASS-BASED-QOS-MIB
 Interface Packet and Byte counters | RootOper.InfraStatistics.Interface(*).Latest.GenericCounters | infrastatistics_generic | IF-MIB, CISCO-IF-EXTENSION-MIB
 Interface packet and byte rates | RootOper.InfraStatistics.Interface(*).Latest.DataRate | infrastatistics_datarate | IF-MIB, CISCO-IF-EXTENSION-MIB
 Interface operational data. Equivalent to 'show interfaces'. This is a superset of the packet and byte counters etc. but is much slower to collect | RootOper.Interfaces.Interface(*) | interfaces | IF-MIB, CISCO-IF-EXTENSION-MIB
 MPLS auto-bandwidth data | RootOper.MPLS_TE.Tunnels.TunnelAutoBandwidth(*) | mpls_te_tunnelautobandwidth | CISCO-MPLS-TE-STD-EXT-MIB
 MPLS tunnel data | RootOper.MPLS_TE.P2P_P2MPTunnel.TunnelHead(*) | mpls_te_tunnelhead | MPLS-TE-STD-MIB
 MPLS head signelling counters | RootOper.MPLS_TE.SignallingCounters.HeadSignallingCounters | mpls_te_headsignallingcounters | MPLS-TE-STD-MIB

## Policy File Syntax

Policy files are written in JSON syntax and consist of
 * Policy name
 * Metadata. Any fields can be included here but the following fields have specific uses:
   * Version - a user-specified version string included in every streamed message
   * Identifier - a user-specified string value included in every streamed message e.g. to identify the source router
   * Description - a description string displayed in 'show telemetry policies'
 * One or more Collection Groups (use multiple groups if different periods are required for different data). Each group consists of:
   * Period - the time in seconds between collections. Minimum 5s
   * Paths - a list of schema paths to stream with the specified period

### Example Policy File:

example.policy

    {
      "Name": "example",
      "Metadata": {
        "Version": 25,
        "Description": "This is a sample policy to demonstrate the syntax",
        "Comment": "This is the first draft",
        "Identifier": "<hostname or other router ID>"
      },
      "CollectionGroups": {
        "FirstGroup": {
          "Period": 30,
          "Paths": [
            "RootOper.BGP.Instance({'InstanceName': 'default'}).InstanceActive.DefaultVRF.Neighbor(*)",
            "RootOper.InfraStatistics.Interface(*).Latest.GenericCounters",
            "RootOper.InfraStatistics.Interface(*).Latest.DataRate",
            "RootOper.QOS.Interface(*).Input.Statistics",
            "RootOper.QOS.Interface(*).Output.Statistics",
            "RootOper.Interfaces.Interface(*)",
            "RootOper.MPLS_TE.Tunnels.TunnelAutoBandwidth(*)",
            "RootOper.MPLS_TE.P2P_P2MPTunnel.TunnelHead(*)",
            "RootOper.MPLS_TE.SignallingCounters.HeadSignallingCounters(*)"
          ]
        }
      }
    }

## Router Configuration

Use the following configuration to stream the data defined by the above policy. Mulitple policies and/or destinations can be configured, in which case all the data in the policies is streamed to all locations. 

    telemetry encoder gpb
      policy group examplegroup
        policy example
        destination ipv4 123.10.1.1 port 2222
        
 If different information needs to be sent to different destinations then multiple policy groups can be defined.

## Wire Format & Decoding

The data is sent in UDP packets, each of which contains a TelemetryHeader GPB message defined in telemetry.proto in this repository. This in turn contains a repeated list of TelemetryTable objects for each row. Each one contains a path which can be used to identify the .proto file used to decode the bytes of the message. Assuming the policy contains a subset of the paths listed above then one of the .proto files in this repository can be used.

## Troubleshooting

 Error | Resolution 
 ----- | ---------- 
 'No encoding definition found for the requested schema path' | .map file missing from /telemetry/gpb/maps. Add the appropriate file from this repository
 'Encoded telemetry data too large for the packet MTU' | A single row doesn't fit in a UDP packet and rows cannot be fragmented so the data cannot be streamed. All of the paths provided can be streamed using an mtu of 1500 but below this some paths may not function and the only option is to remove them from the policy file

