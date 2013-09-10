require 'yaml'
require 'sequencescape-to-s2'
require 'logging'

module SequencescapeToS2
  env = "development" 

  sequencescape_settings = YAML.load_file(File.join('config','sequencescape_database.yml'))[env]
  s2_laboratory_settings = YAML.load_file(File.join('config','s2_database.yml'))[env]['laboratory-app']
  s2_management_settings = YAML.load_file(File.join('config','s2_database.yml'))[env]['management-app']

  reception_amqp_settings = YAML.load_file(File.join('config','amqp.yml'))[env]['message_reception']
  publication_amqp_settings = YAML.load_file(File.join('config','amqp.yml'))[env]['message_publication']
  api_settings = YAML.load_file(File.join('config','api.yml'))[env]

  manager = PlateManager.new({
    :sequencescape_settings => sequencescape_settings, 
    :s2_laboratory_settings => s2_laboratory_settings, 
    :s2_management_settings => s2_management_settings, 
    :reception_amqp_settings => reception_amqp_settings, 
    :publication_amqp_settings => publication_amqp_settings,
    :api_settings => api_settings
  })

  manager.set_logger(Logging::LOGGER)

  Logging::LOGGER.info("Sequencescape to S2 started")
  manager.start
  Logging::LOGGER.info("Sequencescape to S2 ended")

  #manager.copy_plate_in_s2("394b3040-ee23-0130-c2bf-7becfc20e235")
end
