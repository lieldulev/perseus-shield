# Load the rails application
require File.expand_path('../application', __FILE__)

PerseusShield.configure YAML.load_file(Rails.root.join("config/perseus_shield.yml"))[Rails.env]

# Initialize the rails application
PerseusShield::Application.initialize!
