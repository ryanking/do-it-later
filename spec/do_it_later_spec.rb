require File.dirname(__FILE__) + '/spec_helper'

describe "ActiveRecord::Base" do
  describe ".included_modules" do
    it "should include DoItLater::InstanceMethods" do
      ActiveRecord::Base.included_modules.should include(DoItLater::InstanceMethods)
    end
  end
end

describe "Thing" do
  it "should respond to :later" do
    Thing.new.should respond_to(:later)
  end

  describe "unsaved instance" do
    before do
      @thing = Thing.new
    end

    it "should fail" do
      @thing.should be_new_record
      lambda do
        @thing.later :do_stuff
      end.should raise_error(RuntimeError)
    end
  end

  describe "saved instance" do
    before do
      @thing = Thing.new
      @thing.save!
    end

    it "should only accept priorities in (1..5)" do
      lambda do
        @thing.later :do_stuff, 10
      end.should raise_error(ArgumentError)
      lambda do
        @thing.later :do_stuff, :not_a_number
      end.should raise_error(ArgumentError)
    end

    it "should add a job to the appropriate queue" do
      STARLING.should_receive(:set).with("work_1", "{\"class\":\"Thing\",\"method\":\"do_stuff\",\"id\":1}")
      @thing.later :do_stuff, 1
    end
  end
end

describe "DoItLater::Worker" do
  it "should be instantiatable" do
    lambda do
      DoItLater::Worker.new
    end.should_not raise_error
  end

  describe "#get_job" do
    before do
      @worker = DoItLater::Worker.new
    end

    it "should walk through the priorities" do
      STARLING.should_receive(:fetch).exactly(5).times.and_return(nil)
      @worker.get_job
    end
  end

  describe "#run_job" do
    before do
      @worker = DoItLater::Worker.new
      @thing = Thing.new
      @thing.save!
    end

    it "should call the given method" do
      Thing.should_receive(:find).with(1).and_return(@thing)
      @worker.run_job({:class => 'Thing', :id => 1, :method => 'do_stuff'})
    end
  end
end