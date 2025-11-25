require 'xcodeproj'

project_path = 'Pods/Pods.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'firebase_messaging' }
abort "ERROR: firebase_messaging target not found" unless target

target.build_configurations.each do |config|
  settings = config.build_settings
  settings['DEFINES_MODULE'] = 'YES'
  settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
  settings['CLANG_WARN_NON_MODULAR_IN_FRAMEWORK_MODULES'] = 'NO'
  cflags = settings['OTHER_CFLAGS']
  cflags = cflags.is_a?(Array) ? cflags : [cflags].compact
  cflags << '$(inherited)' if cflags.empty?
  extra = [
    '-Wno-error=non-modular-include-in-framework-module',
    '-Wno-non-modular-include-in-framework-module',
    '-Wno-nonportable-include-path'
  ]
  settings['OTHER_CFLAGS'] = (cflags + extra).uniq
end

project.save
