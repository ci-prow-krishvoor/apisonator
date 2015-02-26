require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ListenerTest < Test::Unit::TestCase
  include TestHelpers::Integration

  UnexpectedError = Class.new(RuntimeError)
  ExpectedError   = Class.new(Error)

  def test_on_invalid_path_responds_with_404
    post '/foo.html'
    assert_equal 404, last_response.status
  end

  def test_on_invalid_http_method_responds_with_404
    get '/transactions.xml'
    assert_equal 404, last_response.status

    post '/transaction/authorize.xml'
    assert_equal 404, last_response.status
  end

  def test_empty_report
    post '/transactions.xml'
    assert_equal 403, last_response.status
  end

  def test_unexpected_exception_bubbles_through
    Transactor.stubs(:report).raises(UnexpectedError.new('bang!'))
    assert_raise UnexpectedError do
      post '/transactions.xml?transactions[0]=foo2', :provider_key => 'foo'
    end
  end

  def test_expected_exception_is_caught
    Transactor.stubs(:report).raises(ExpectedError.new('bang!'))
    assert_nothing_raised do
      post '/transactions.xml?transactions[0]=foo2', :provider_key => 'foo'
    end
  end

  def test_utf8_exception_is_caught
    Transactor.stubs(:report).raises(ArgumentError.new('invalid byte sequence in UTF-8'))
    assert_nothing_raised do
      post '/transactions.xml?transactions[0]=foo2', :provider_key => 'foo'
    end
  end
end
