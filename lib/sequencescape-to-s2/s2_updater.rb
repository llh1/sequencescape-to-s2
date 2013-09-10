require 'lims-core'
require 'lims-core/persistence/sequel'
require 'lims-core/persistence/sequel/store'
require 'lims-core/persistence/sequel/persistor'
require 'lims-core/persistence/sequel/session'
require 'lims-core/persistence/session'

Lims::LaboratoryApp::Laboratory::Sample::NO_AUTO_REGISTRATION = 1
require 'lims-laboratory-app/laboratory/plate/plate_sequel_persistor'
require 'lims-laboratory-app/labels/labellable/labellable_sequel_persistor'

Lims::ManagementApp::Sample::NO_AUTO_REGISTRATION = 1
require 'lims-management-app/sample/sample_sequel_persistor'
require 'lims-management-app/sample/cellular_material/cellular_material_sequel_persistor'
require 'lims-management-app/sample/dna/dna_sequel_persistor'
require 'lims-management-app/sample/rna/rna_sequel_persistor'
require 'lims-management-app/sample/genotyping/genotyping_sequel_persistor'
require 'lims-management-app/sample/taxonomy/taxonomy_sequel_persistor'
require 'lims-management-app/sample/taxonomy/taxonomy'

module SequencescapeToS2
  module S2Updater

    ExistingResource = Class.new(StandardError)

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    # @param [Hash] objects
    def create_plate_objects(objects)
      self.class.switch_sample_persistor_to(Lims::LaboratoryApp::Laboratory::Sample)
      create_in_store(laboratory_store, objects[:laboratory])

      self.class.switch_sample_persistor_to(Lims::ManagementApp::Sample)
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

    module ClassMethods
      # @param [Class] klass
      # Laboratory-app and management-app both use a different Sample resource.
      # Lims-core identity map has 2 data structures: id_to_object and object_to_id.
      # A key for the sample resource in id_to_object would be "sample" and it raises
      # an exception if it already exists. So we cannot have both sample resources loaded
      # at the same time. A hack is provided below to register the sample resource needed.
      def switch_sample_persistor_to(klass)
        id_to_object = Lims::Core::Persistence::Session.model_map.instance_variable_get(:@id_to_object)
        object_to_id = Lims::Core::Persistence::Session.model_map.instance_variable_get(:@object_to_id)

        id_to_object.delete("sample") if id_to_object.has_key?("sample")
        object_to_id.delete(klass) if object_to_id.has_key?(klass)

        id_to_object["sample"] = klass
        object_to_id[klass] = "sample"
      end
    end
  end
end
