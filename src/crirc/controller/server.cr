require "../network/server"

class Crirc::Controller::Server
  getter network : Network::Server

  def initialize(@network)
  end

  def start
  end
end