class Testme
  def initialize
    @param = "salam"
  end

  def tip
    puts @param
  end

  def saracie
    puts "sarac"
  end
end

testme = Testme.new
testme.tip
testme.saracie

class Testme
  undef tip
  undef saracie

  def tip
    puts "acm"
  end

  def saracie
    puts "bbb"
  end
end

testme.tip
testme.saracie