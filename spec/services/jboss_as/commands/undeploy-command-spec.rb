require 'sc-agent/services/jboss_as/commands/undeploy-command'

module SteamCannon
  describe JBossAS::UndeployCommand do

    before(:each) do
      @service        = mock( 'Service' )
      @service_helper = mock( ServiceHelper )

      @db = mock("DB")

      @service.stub!( :service_helper ).and_return( @service_helper )
      @service.stub!(:db).and_return( @db )
      @service.stub!(:deploy_path).and_return('this/is/a/location')
      
      @service.should_receive(:state).and_return( :stopped )

      @log            = Logger.new('/dev/null')
      @cmd            = JBossAS::UndeployCommand.new( @service, :log => @log )
      @exec_helper    = @cmd.instance_variable_get(:@exec_helper)
    end

    it "should remove the artifact" do
      @db.should_receive( :save_event ).with( :undeploy, :started ).and_return("1")
      @db.should_receive( :save_event ).with( :undeploy, :finished, :parent => "1" )
      
      @service.should_receive(:deploy_path).with('name.war').and_return('this/is/a/location')

      File.should_receive(:exists?).with('this/is/a/location').and_return(true)
      
      FileUtils.should_receive(:rm).with("this/is/a/location", :force => true)

      @cmd.execute( 'name.war' ).should == nil
    end

    it "should return error message when artifact doesn't exists" do
      @db.should_receive( :save_event ).with( :undeploy, :started ).and_return("1")
      @db.should_receive( :save_event ).with( :undeploy, :failed, :parent => "1", :msg=>"Artifact with id 'name.war' not found" )

      File.should_receive(:exists?).with('this/is/a/location').and_return(false)

      begin
        @cmd.execute( 'name.war' )
      rescue => e
        e.message.should == "Artifact with id 'name.war' not found"
      end
    end

  end
end

