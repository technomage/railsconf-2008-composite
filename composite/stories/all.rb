dir = File.dirname(__FILE__)
require File.expand_path("#{dir}/helper.rb")
Spec::Story::Runner.run_options.colour=true

with_steps_for :funfx, :setup do
  run File.join(dir,"create_data.story")
end