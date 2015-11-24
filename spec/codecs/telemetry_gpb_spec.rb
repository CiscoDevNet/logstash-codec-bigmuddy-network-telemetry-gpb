require "logstash/devutils/rspec/spec_helper"
require "logstash/codecs/telemetry"

describe "Codec telemetry" do

  context "registration" do
    it "should register without raising exception" do
      codec = LogStash::Plugin.lookup("codec", "telemetry").new
      expect {codec.register}.to_not raise_error
    end
  end

  context "encode" do
    it "should handle encode silently" do
      codec = LogStash::Codecs::Telemetry.new
      expect {codec.encode({})}.to_not raise_error
    end
  end

end
