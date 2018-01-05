class Server

  setter ready

  def initialize
    @ready = false
    init_routes
  end

  def init_routes
    get "/" do |env|
      env.redirect "/index.html"
    end

    get "/isready" do |env|
      @ready ? "ready" : "busy"
    end
  end

  def run
    Kemal.run
  end
end
