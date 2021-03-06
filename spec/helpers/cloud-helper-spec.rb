require 'sc-agent/helpers/cloud-helper'

module SteamCannon
  describe CloudHelper do
    before(:each) do
      @client_helper = mock( ClientHelper )

      @helper = CloudHelper.new( :log => Logger.new('/dev/null'), :client_helper => @client_helper )
    end

    it "should discover if we're on EC2" do
      @client_helper.should_receive(:get).with('http://169.254.169.254/1.0/meta-data/local-ipv4').and_return('127.0.0.1')
      @helper.discover_ec2.should == true
    end

    it "should discover if we're on EC2 and return false if not" do
      @client_helper.should_receive(:get).with('http://169.254.169.254/1.0/meta-data/local-ipv4').and_return(nil)
      @helper.discover_ec2.should == false
    end

    it "should discover if we're on Virtualbox" do
      File.should_receive(:exist?).with(CloudHelper::VBOX_CONTROL).and_return(true)
      @helper.discover_virtualbox.should == true
    end

    it "should discover if we're on Virtualbox and return false if not" do
      File.should_receive(:exist?).with(CloudHelper::VBOX_CONTROL).and_return(false)
      @helper.discover_virtualbox.should == false
    end

    it "should discover platform and abort if no platform was discovered after 10 retries" do
      @helper.should_receive(:discover_ec2).exactly(10).times.and_return(false)
      @helper.should_receive(:discover_virtualbox).exactly(10).times.and_return(false)
      @helper.should_receive(:sleep).with(5).exactly(10).times
      @helper.should_receive(:abort)

      @helper.discover_platform
    end

    it "should discover platform and return it" do
      @helper.should_receive(:discover_ec2).and_return(false)
      @helper.should_receive(:discover_virtualbox).and_return(false)
      @helper.should_receive(:sleep).with(5).once
      @helper.should_receive(:discover_ec2).and_return(true)

      @helper.discover_platform == :ec2
    end

    describe ".read_certificate" do
      it "should read certificate for EC2" do
        @client_helper.should_receive(:get).with('http://169.254.169.254/1.0/user-data').and_return('{ "steamcannon_ca_cert": "CERT" }')
        @helper.read_certificate( :ec2 ).should == "CERT"
      end

      it "should read certificate for EC2 and return nil because there is no certificate in UserData" do
        @client_helper.should_receive(:get).with('http://169.254.169.254/1.0/user-data').and_return('{}')
        @helper.read_certificate( :ec2 ).should == nil
      end

      it "should read certificate for EC2 and return nil because UserData is not in JSON format" do
        @client_helper.should_receive(:get).with('http://169.254.169.254/1.0/user-data').and_return('{sdf}')
        @helper.read_certificate( :ec2 ).should == nil
      end

      it "should read certificate for Virtualbox" do
        @helper.should_receive('`').and_return('Value: { "steamcannon_ca_cert": "CERT" }')
        @helper.read_certificate(:virtualbox).should == "CERT"
      end

      it "should read certificate for Virtualbox and return nil because there is no certificate in UserData" do
        @helper.should_receive('`').and_return("Value: " + Base64.encode64('{}'))
        @helper.read_certificate(:virtualbox).should == nil
      end

      it "should read certificate for Virtualbox and return nil because UserData is not in JSON format" do
        @helper.should_receive('`').and_return("Value: " + Base64.encode64('{sdf}'))
        @helper.read_certificate(:virtualbox).should == nil
      end
    end
  end
end
