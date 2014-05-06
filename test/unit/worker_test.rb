require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class WorkerTest < Test::Unit::TestCase
  include TestHelpers::Fixtures

  def setup
    @storage = Storage.instance(true)
    @storage.flushdb

    Resque.reset!

    setup_provider_fixtures

    @application_one = Application.save(:service_id => @service_id,
                                        :id         => next_id,
                                        :state      => :active,
                                        :plan_id    => @plan_id,
                                        :plan_name  => @plan_name)

    @application_two = Application.save(:service_id => @service_id,
                                        :id         => next_id,
                                        :state      => :active,
                                        :plan_id    => @plan_id,
                                        :plan_name  => @plan_name)

    @metric_id = next_id
    Metric.save(:service_id => @service_id, :id => @metric_id, :name => 'hits')
  end

  def test_queue_name
    assert_equal :priority, Worker::QUEUES[0]
    assert_equal :main, Worker::QUEUES[1]
  end

  def test_format_of_a_job
    encoded_job = Yajl::Encoder.encode(:class => 'TestJob', :args => [{'0'=> {:app_id => "app_id with spaces"}}])
    assert_equal '{"class":"TestJob","args":[{"0":{"app_id":"app_id with spaces"}}]}', encoded_job
  end

  def test_no_jobs_in_the_queue
    redis = Backend::Storage.any_instance
    redis.expects(:blpop).with(*Worker::QUEUES.map{|q| "resque:queue:#{q}"}, {:timeout => 60}).returns(nil)

    Worker.work(:one_off => true)
  end

  def test_logging_works
    Timecop.freeze(Time.utc(2011, 12, 12, 11, 48)) do
      log_file = "/tmp/temp_3scale_backend_worker.log"
      FileUtils.remove_file(log_file, :force => true)

      Transactor.report(@provider_key, @service_id, '0' => {'app_id' => @application_one.id,
                                             'usage'  => {'hits' => 1}},
                                     '1' => {'app_id' => @application_two.id,
                                             'usage'  => {'hits' => 1}})

      assert_queued Transactor::ReportJob,
                  [@service_id,
                    {'0' => {'app_id' => @application_one.id, 'usage' => {'hits' => 1}},
                    '1' => {'app_id' => @application_two.id, 'usage' => {'hits' => 1}}},
                    Time.utc(2011, 12, 12, 11, 48).to_f]

      ## WARNING: we cannot do the call below, because worker fetches from redis, and resque_unit keeps it in
      ## memory. Get rid of resque_unit some time soon
      ## it will block for a minute

      ## creates the log file when on new
      worker = Backend::Worker.new(:one_off => true, :log_file => log_file)

      line = File.new(log_file,"r").read
      assert_equal "# Logfile created on 2011-12-12 12:48:00 +0100 by logger.rb", line.split("/").first

      ## creates the log file when on work
      FileUtils.remove_file(log_file, :force => true)
      worker = Backend::Worker.work(:one_off => true, :log_file => log_file)

      line = File.new(log_file,"r").read
      assert_equal "# Logfile created on 2011-12-12 12:48:00 +0100 by logger.rb", line.split("/").first

      FileUtils.remove_file(log_file, :force => true)
    end
  end

  # TODO: more tests here.
end
