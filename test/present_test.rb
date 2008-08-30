require File.dirname(__FILE__) + '/test_helper.rb'

require "test/unit"
class PresentTest < Test::Unit::TestCase
  def test_run
    bin = File.join(File.dirname(__FILE__), '..', 'bin', 'present')
    assert system("#{bin} 2>&1 > /dev/null")
  end
end
