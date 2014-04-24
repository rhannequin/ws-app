require_relative 'test_helper'

class RoutesTest < Test::Unit::TestCase
  def test_it_home
    get '/'
    assert last_response.ok?
  end
end
