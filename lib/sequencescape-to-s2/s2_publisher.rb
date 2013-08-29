require 'lims-core/persistence/message_bus'

module SequencescapeToS2
  module S2Publisher

    def self.included(klass)
      klass.class_eval do
        include Virtus
        include Aequitas
        attribute :bus, Lims::Core::Persistence::MessageBus, :required => true, :writer => :private
      end
    end
      
    def publish(objects)
      objects.each do |object|
        bus.publish(object.to_json, :routing_key => routing_key(object))   
      end
    end

    def routing_key(object)
      "sequencescapetos2.#{object.keys.first}.create"
    end

    def setup_message_bus(settings)
      @bus = Lims::Core::Persistence::MessageBus.new(settings).tap do |b|
        b.set_message_persistence(settings["message_persistence"])
        b.connect
      end
    end
  end
end
