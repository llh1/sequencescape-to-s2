require 'lims-core'
require 'lims-core/persistence/sequel'
require 'lims-core/persistence/sequel/store'
require 'lims-core/persistence/sequel/persistor'
require 'lims-core/persistence/sequel/session'
require 'lims-core/persistence/session'
require 'lims-laboratory-app/laboratory/plate/plate_sequel_persistor'
require 'lims-laboratory-app/labels/labellable/labellable_sequel_persistor'

module SequencescapeToS2
  module S2Updater

    ExistingResource = Class.new(StandardError)

    # @param [Hash] objects
    def create_plate_objects(objects)
      create_in_store(laboratory_store, objects[:laboratory])
      create_in_store(management_store, objects[:management])
    end

    # @param [Lims::Core::Persistence::Sequel::Store] store
    # @param [Hash] objects
    def create_in_store(store, objects)
      store.with_session do |session|
        objects.each do |uuid, resource|
          session << resource

          if existing_uuid?(uuid, session)
            raise ExistingResource, "The resource '#{resource.class}' already exists in S2 with the uuid '#{uuid}'."
          end

          session.new_uuid_resource_for(resource).send(:uuid=, uuid)
        end
      end
    end

    # @param [String] uuid
    # @param [Lims::Core::Persistence::Session] session
    # @return [Bool]
    def existing_uuid?(uuid, session)
      !session[uuid].nil?
    end
  end
end
