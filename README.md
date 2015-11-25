# Logstash Plugin

This is a plugin for [Logstash](https://github.com/elasticsearch/logstash).

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Documentation

The role of this codec plugin is to extract content out of protobuf encoded telemetry streams produced by the network and transported over a datagram service (e.g. UDP). A [sister plugin](https://github.com/cisco/logstash-codec-bigmuddy-network-telemetry) handles compressed JSON content. The codec generates logstash events which can be handled by the output stage using an output plugin which matches the consuming application. For example, logstash running with this plugin as input codec, might use;

- the [elasticsearch output plugin](https://github.com/logstash-plugins/logstash-output-elasticsearch) in order to push content in [elasticsearch](https://www.elastic.co/products/elasticsearch).
- a [transport output plugin](https://github.com/logstash-plugins/logstash-output-tcp) to push telemetry content into [Splunk](http://www.splunk.com/).
- the [Kafka output plugin](https://github.com/logstash-plugins/logstash-output-kafka) to publish telemetry content to an [Apache Kafka](http://kafka.apache.org/) bus and in to a big data platform.

A collection of pre-packaged and pre-configured [container based stacks](https://github.com/cisco/bigmuddy-network-telemetry-stacks) should make access to a running setup (e.g ELK stack) easy. The `stack_run` utility also takes care of building the Ruby binding of the `.proto` files in use.

Further documentation is provided in the [plugin source](/lib/logstash/codecs/telemetry_gpb.rb).

__Note: The streaming telemetry project is work in progress, and both the on and off box components of streaming telemetry are likely to evolve at a fast pace.__

## Configuration

This codec requires the item 'protofiles' to be configured. This configuration item is mandatory and specifies a directory where the `.proto` files and their Ruby binding equivalent are located. Note that both the `.proto` files, and the generated `.pb.rb` Ruby source corresponding to the `.proto` files are required by this codec plugin..

Here is an example logstash configuration snippet:

```
input {
    udp {
        port => 2103
        codec => telemetry_gpb {
            protofiles => "/data/proto"
        }
    }
}
```

The `.proto` files for a corresponding schema path (e.g.`RootOper.InfraStatistics.Interface.Latest.GenericCounters`) can be generated on the router using the following command:

```
telemetry generate gpb-encoding path 'RootOper.InfraStatistics.Interface.Latest.GenericCounters' file /telemetry/gpb/genericcounters.proto
```

The `telemetry generate` command also provides an option `package` which causes a package directive to be added to the top of the generated `.proto` files. This is useful when multiple `.proto` files define messages with conflicting names. The `package` directive provides an independent namespace for messages in each `.proto`.

In order to produce the Ruby bindings for the `.proto` files, a protocol buffer compiler which supports [`proto2`](https://developers.google.com/protocol-buffers/docs/reference/proto2-spec) bindings (e.g. [`ruby-protocol-buffer` gem](https://github.com/codekitchen/ruby-protocol-buffers)) is required. Alternatively, simply clone the [bigmuddy network telemetry stacks](https://github.com/cisco/bigmuddy-network-telemetry-stacks), place the `.proto` files in the appropriate location (e.g. default location for ELK stack would be `/var/local/stack_elk/logstash_data/proto`) and run the stack. This will compile the `.proto` files and place generated Ruby source (`.pb.rb`) in the same location.

Along with the `.proto` definitions corresponding to schema paths specified in the policy, it will also be necessary to include `cisco.proto`, `header.proto` and `descriptor.proto` which describe common content across messages. A pointer to these files will be added shortly.

Authoritative IOS-XR configuration information can be found on [CCO](http://www.cisco.com/c/en/us/products/ios-nx-os-software/ios-xr-software/index.html).

## Need Help?

Need help? Try #logstash on freenode IRC or the https://discuss.elastic.co/c/logstash discussion forum.

## Developing

### 1. Plugin Development and Testing

#### Code
- To get started, you'll need JRuby with the Bundler gem installed.

- Create a new plugin or clone and existing from the GitHub [logstash-plugins](https://github.com/logstash-plugins) organization. We also provide [example plugins](https://github.com/logstash-plugins?query=example).

- Install dependencies
```sh
bundle install
```

#### Test

Unit test development in progress.

### 2. Running your unpublished Plugin in Logstash

#### 2.1 Run in a local Logstash clone

- Edit Logstash `Gemfile` and add the local plugin path, for example:
```ruby
gem "logstash-codec-bigmuddy-telemetry-gpb", :path => "/your/local/logstash-codec-bigmuddy-telemetry-gpb"
```
- Install plugin
```sh
bin/plugin install --no-verify
```

At this point any modifications to the plugin code will be applied to this local Logstash setup. After modifying the plugin, simply rerun Logstash.

#### 2.2 Run in an installed Logstash

You can use the same **2.1** method to run your plugin in an installed Logstash by editing its `Gemfile` and pointing the `:path` to your local plugin development directory or you can build the gem and install it using:

- Build your plugin gem
```sh
gem build logstash-codec-bigmuddy-telemetry-gpb.gemspec
```
- Install the plugin from the Logstash home
```sh
bin/plugin install /your/local/plugin/logstash-codec-bigmuddy-telemetry-gpb.gem
```
- Start Logstash and proceed to test the plugin

## Contributing

Once all the necessary criteria are met, we will attempt to push this content to the [logstash-plugins](https://github.com/logstash-plugins) repository, and the corresponding gem to rubygems.org. Watch this space.

