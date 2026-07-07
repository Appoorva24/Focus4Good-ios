require 'xcodeproj'
project_path = 'Focus4Good.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath('Focus4Good/Resources', true)
file_ref = group.new_reference('guided_meditation.mp4')
target.resources_build_phase.add_file_reference(file_ref, true)

project.save
puts "Added guided_meditation.mp4 to project"
