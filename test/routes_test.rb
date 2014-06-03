require_relative 'test_helper'

class RoutesTest < Test::Unit::TestCase
  def test_it_home
    get '/'
    assert last_response.ok?
  end

  def test_it_places_comments
    get '/places/1641/comments'
    assert last_response.ok?
  end
end
