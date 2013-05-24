require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MiteCmd::CompletionTable do
  before :each do
    Mite::Project.stub!(:all).and_return [stub('project', :name => 'Demo Project')]
    Mite::Service.stub!(:all).and_return [stub('service', :name => 'late night programming')]
    Mite::TimeEntry.stub!(:all).and_return [stub('time entry', :note => 'shit 02:13 is really late')]
  end

  def path_to_cache_file
    '/tmp/mitetest'
  end

  after :all do
    File.delete(path_to_cache_file) if File.exist?(path_to_cache_file)
  end

  let(:table) { MiteCmd::CompletionTable.new(path_to_cache_file) }

  describe 'new' do
    it "stores path to cache file" do
      table = MiteCmd::CompletionTable.new('test')
      table.path.should == 'test'
    end
  end

  describe "#rebuild" do
    it "deletes existing file" do
      File.open(path_to_cache_file, 'w') { |f| f.puts "testing" }
      table.rebuild
      File.read(path_to_cache_file).should_not include("testing")
    end

    it "writes data to disk" do
      File.delete(path_to_cache_file) if File.exist?(path_to_cache_file)

      table.rebuild

      values_from_disk = Marshal.load(File.read(path_to_cache_file))
      values_from_disk[0].should == ['Demo Project']
    end
  end

  describe '#values' do
    context "when not cached" do
      before :each do
        File.delete(path_to_cache_file) if File.exist?(path_to_cache_file)
      end

      it "fetches data from Mite" do
        table.values.should == {
          0 => ["Demo Project"],
          1 => ["late night programming"],
          2 => ["\"0:05\"", "\"0:05+\"", "\"0:15\"", "\"0:15+\"", "\"0:30\"", "\"0:30+\"", "\"1:00\"", "\"1:00+\""],
          3 => ["shit 02:13 is really late"]
        }
      end
    end

    context "when cached" do
      before :each do
        values = {
          0 => ["Foo"],
          1 => ["Bar"],
          2 => ["Baz"],
          3 => ["Qux"]
        }
        File.open(path_to_cache_file, 'w') { |f| Marshal.dump(values, f) }
      end

      it "returns values from disk" do
        table.values[3].should == ["Qux"]
      end
    end
  end
end
