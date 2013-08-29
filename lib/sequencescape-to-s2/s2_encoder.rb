require 'lims-laboratory-app/laboratory/plate/plate_resource'
require 'lims-laboratory-app/labels/labellable/labellable_resource'
require 'lims-api/context'

module SequencescapeToS2
  module S2Encoder
    
    # @param [Hash] objects
    # @return [Array]
    def encode(objects)
      laboratory_uuids = objects[:laboratory].keys
      management_uuids = objects[:management].keys

      [].tap do |encoded_resources|
        encoded_resources << encode_for_store(laboratory_store, laboratory_uuids)
        encoded_resources << encode_for_store(management_store, management_uuids)
      end.flatten
    end

    # @param [Lims::Core::Persistence::Sequel::Store] store
    # @param [Array] uuids
    # @return [Array]
    def encode_for_store(store, uuids)
      url_generator = lambda { |u| u }
      context = Lims::Api::Context.new(store, nil, nil, url_generator)

      [].tap do |encoded_resources|
        uuids.each do |uuid|
          resource = context.for_uuid(uuid)
          context.with_session do |session|
            resource.object(session)

            if context.find_model_name(resource.object.class)
              encoded_resources << context.send(:message_payload, "create", resource)
            end
          end
        end
      end
    end
  end
end
