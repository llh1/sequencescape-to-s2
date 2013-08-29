require 'yaml'
require 'sequencescape-to-s2'

module SequencescapeToS2
  env = "development" 
  sequencescape_settings = YAML.load_file(File.join('config','sequencescape_database.yml'))[env]
  s2_laboratory_settings = YAML.load_file(File.join('config','s2_database.yml'))[env]['laboratory-app']
  s2_management_settings = YAML.load_file(File.join('config','s2_database.yml'))[env]['management-app']
  amqp_settings = YAML.load_file(File.join('config','amqp.yml'))[env]

  manager = PlateManager.new(sequencescape_settings, s2_laboratory_settings, s2_management_settings, amqp_settings)
  manager.copy_plate_in_s2("394b3040-ee23-0130-c2bf-7becfc20e235")
  #manager.copy_plate_in_s2("fb3b5e70-ee22-0130-c2bf-7becfc20e235")

  puts "Plate imported in S2."
end
