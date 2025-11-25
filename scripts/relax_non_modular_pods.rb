require 'xcodeproj'

project_path = 'Pods/Pods.xcodeproj'
target_names = %w[firebase_messaging geolocator_apple]
extra_flags = [
  '-Wno-error=non-modular-include-in-framework-module',
  '-Wno-non-modular-include-in-framework-module',
  '-Wno-nonportable-include-path'
]

puts "Opening #{project_path}..."
project = Xcodeproj::Project.open(project_path)

project.targets.each do |target|
  next unless target_names.include?(target.name)
  puts "Updating target: #{target.name}"

  target.build_configurations.each do |config|
    settings = config.build_settings
    puts "  - #{config.name}"

    settings['DEFINES_MODULE'] = 'YES'
    settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
    settings['CLANG_WARN_NON_MODULAR_IN_FRAMEWORK_MODULES'] = 'NO'

    other_cflags = settings['OTHER_CFLAGS']
    other_cflags = case other_cflags
                   when String then [other_cflags]
                   when Array then other_cflags
                   else []
                   end
    other_cflags << '$(inherited)' if other_cflags.empty?
    settings['OTHER_CFLAGS'] = (other_cflags + extra_flags).uniq

    if target.name == 'geolocator_apple'
      settings['SKIP_INSTALL'] = 'YES'
      settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
    end
  end
end

puts 'Saving project...'
project.save
puts 'Done.'
