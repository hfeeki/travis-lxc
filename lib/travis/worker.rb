require 'core_ext/string/camelize'

STDOUT.sync = true
HOSTNAME = `hostname`

module Travis
  class Worker
    autoload :Receiver, 'travis/worker/receiver'
    autoload :Runner,   'travis/worker/runner'
    autoload :Reporter, 'travis/worker/reporter'
    autoload :Utils,    'travis/worker/utils'

    attr_reader :config, :receivers

    def initialize(config)
      @config    = config
      @receivers = []
    end

    def start
      const = Receiver.const_get(config[:receiver].to_s.camelize, false)
      1.upto(config[:threads]) do
        receivers << const.new(config)
      end
      sleep
    end

    def stop
      receivers.each { |receiver| receiver.stop }
    end
  end
end

app = Travis::Worker.new(
  threads: 1,
  receiver: :stub,
  runner:   :lxc,
  reporter: :amqp,
  amqp: {
    host: 'localhost',
    port: 5672,
    username: 'travis',
    password: 'travis',
    vhost: '/travis',
    queue: 'builds',
  }
)
app.start
